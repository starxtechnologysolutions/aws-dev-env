package com.umigo.umigoCrmBackend.Service.Impl;

import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.auth.UserRecord;
import com.umigo.umigoCrmBackend.Common.Enums.DriverStatus;
import com.umigo.umigoCrmBackend.Common.Enums.StaffStatus;
import com.umigo.umigoCrmBackend.DTO.Request.AuthRequest;
import com.umigo.umigoCrmBackend.DTO.Response.AuthResponse;
import com.umigo.umigoCrmBackend.DTO.Response.DriverResponse;
import com.umigo.umigoCrmBackend.DTO.Response.StaffResponse;
import com.umigo.umigoCrmBackend.Entity.Users;
import com.umigo.umigoCrmBackend.Entity.Driver;
import com.umigo.umigoCrmBackend.Entity.Staff;
import com.umigo.umigoCrmBackend.Repository.UserRepository;
import com.umigo.umigoCrmBackend.Repository.DriverRepository;
import com.umigo.umigoCrmBackend.Repository.StaffRepository;
import com.umigo.umigoCrmBackend.Security.JwtTokenUtil;
import com.umigo.umigoCrmBackend.Service.AuthService;
import com.umigo.umigoCrmBackend.Service.FirebaseService;
import com.umigo.umigoCrmBackend.Service.TokenStoreService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.*;
import org.springframework.util.StringUtils;

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final FirebaseService firebaseService;
    private final JwtTokenUtil jwtTokenUtil;
    private final UserRepository userRepo;
    private final DriverRepository driverRepo;
    private final StaffRepository staffRepo;
    private final TokenStoreService tokenStoreService;

    @Override
    @Transactional
    public ResponseEntity<AuthResponse> register(String domain, AuthRequest request) {
        String normalizedDomain = domain == null ? "" : domain.trim().toLowerCase(Locale.ROOT);
        if (!"driver".equals(normalizedDomain)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(AuthResponse.failure("Registration is only available for drivers"));
        }

        Optional<Users> existingUserOpt = userRepo.findByEmailIgnoreCase(request.getEmail());
        System.out.println(userRepo.existsByEmail(request.getEmail()));
        if (existingUserOpt.isPresent()) {
            Users existingUser = existingUserOpt.get();
            if (existingUser.isDriver()) {
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(AuthResponse.failure("Driver profile already exists for this email"));
            }
            AuthResponse response = registerDriver(existingUser, request);
            return ResponseEntity.ok(response);
        }

        try {
            String displayName = String.format("%s %s",
                    StringUtils.hasText(request.getFirstName()) ? request.getFirstName() : "",
                    StringUtils.hasText(request.getLastName()) ? request.getLastName() : ""
            ).trim();
            UserRecord userRecord = firebaseService.createUser(
                    request.getEmail(),
                    request.getPassword(),
                    request.getPhoneNumber(),
                    displayName
            );

            Users user = userRepo.save(
                    Users.builder()
                            .id(userRecord.getUid())
                            .email(userRecord.getEmail())
                            .driver(false)
                            .staff(false)
                            .build()
            );

            AuthResponse response = registerDriver(user, request);
            return ResponseEntity.ok(response);
        } catch (FirebaseAuthException e) {
            log.error("Firebase user creation failed", e);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(AuthResponse.failure("Unable to create Firebase user: " + e.getMessage()));
        } catch (IllegalStateException e) {
            log.error("Registration failed: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(AuthResponse.failure(e.getMessage()));
        }
    }

    @Override
    @Transactional
    public ResponseEntity<AuthResponse> login(String authorizationHeader, String domainName) {
        try {
            String idToken = extractBearer(authorizationHeader);
            if (idToken == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(AuthResponse.failure("Missing or invalid Authorization header"));
            }

            // 1) Verify Firebase token (invalid → exception)
            FirebaseToken fb = firebaseService.verifyIdToken(idToken);

            log.info("Firebase UID={}, email={}", fb.getUid(), fb.getEmail());

            // 2) User must exist (UID is PK)
            Users user = userRepo.findById(fb.getUid())
                    .orElseThrow(() -> new IllegalStateException("User not provisioned"));

            // 3) Mode routing
            String mode = domainName == null ? "" : domainName.trim().toLowerCase(Locale.ROOT);
            switch (mode) {
                case "driver" -> {
                    if (!user.isDriver()) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                .body(AuthResponse.failure("No Driver Login for User"));
                    }
                    Driver d = driverRepo.findByUserId(user.getId())
                            .orElseThrow(() -> new IllegalStateException("Driver profile not found"));

                    // (Optional) Only allow Verified
                    if (DriverStatus.Blacklisted == d.getStatus()) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                .body(AuthResponse.failure("Driver status: " + d.getStatus()));
                    }

                    // 4) Mint tokens
                    Map<String, Object> claims = Map.of(
                            "uid", user.getId(),
                            "email", user.getEmail(),
                            "mode", "DRIVER",
                            "profile", List.of("DRIVER")
                    );
                    String access  = jwtTokenUtil.generateAccessToken(user.getId(), claims);
                    String refresh = jwtTokenUtil.generateRefreshToken(user.getId());
                    tokenStoreService.storeTokens(user.getId(), access, refresh);

                    // 5) Build DriverResponse
                    DriverResponse dto = DriverResponse.fromEntity(d);

                    return ResponseEntity.ok(AuthResponse.driverOK(access, refresh, dto));
                }
                case "staff" -> {
                    if (!user.isStaff()) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                .body(AuthResponse.failure("No Staff Login for User"));
                    }
                    Staff s = staffRepo.findByUserId(user.getId())
                            .orElseThrow(() -> new IllegalStateException("Staff profile not found"));

                    if (StaffStatus.Active != s.getStatus()) {
                        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                                .body(AuthResponse.failure("Staff status: " + s.getStatus()));
                    }

                    Map<String, Object> claims = Map.of(
                            "uid", user.getId(),
                            "email", user.getEmail(),
                            "mode", "STAFF",
                            "profile", List.of("STAFF")
                    );
                    String access  = jwtTokenUtil.generateAccessToken(user.getId(), claims);
                    String refresh = jwtTokenUtil.generateRefreshToken(user.getId());
                    tokenStoreService.storeTokens(user.getId(), access, refresh);

                    StaffResponse dto = StaffResponse.fromEntity(s);

                    return ResponseEntity.ok(AuthResponse.staffOK(access, refresh, dto));
                }
                default -> {
                    return ResponseEntity.status(HttpStatus.FORBIDDEN)
                            .body(AuthResponse.failure("Unsupported login type: " + domainName));
                }
            }

        } catch (IllegalStateException e) {
            log.error("Provisioning mismatch: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(AuthResponse.failure("User not provisioned correctly"));
        } catch (Exception e) {
            log.warn("Login failed for {}: {}", domainName, e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(AuthResponse.failure("User does not exist or invalid token"));
        }
    }

    @Override
    @Transactional
    public ResponseEntity<AuthResponse> logout(String authorizationHeader) {
        String token = extractBearer(authorizationHeader);
        if (token == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(AuthResponse.failure("Missing or invalid Authorization header"));
        }

        if (!jwtTokenUtil.validateAccessToken(token)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(AuthResponse.failure("Invalid or expired token"));
        }

        try {
            String userId = jwtTokenUtil.extractSubject(token);
            if (!tokenStoreService.isAccessTokenValid(userId, token)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(AuthResponse.failure("Invalid or expired token"));
            }
            tokenStoreService.revokeTokens(userId);
            AuthResponse response = AuthResponse.builder()
                    .success(true)
                    .message("Logged out successfully")
                    .build();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Logout failed", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(AuthResponse.failure("Logout failed"));
        }
    }

    private String extractBearer(String header) {
        if (header == null || !header.startsWith("Bearer ")) return null;
        String token = header.substring(7).trim();
        return token.isEmpty() ? null : token;
    }

    private AuthResponse registerDriver(Users user, AuthRequest request) {
        if (user.isDriver()) {
            throw new IllegalStateException("User is already registered as Driver");
        }
        driverRepo.findByUserId(user.getId()).ifPresent(existing -> {
            throw new IllegalStateException("Driver profile already exists");
        });

        String firstName = StringUtils.hasText(request.getFirstName()) ? request.getFirstName() : "";
        String lastName = StringUtils.hasText(request.getLastName()) ? request.getLastName() : "";

        Driver driver = Driver.builder()
                .userId(user.getId())
                .firstName(firstName)
                .lastName(lastName)
                .phone(request.getPhoneNumber())
                .email(user.getEmail())
                .status(DriverStatus.Incomplete)
                .build();
        driver = driverRepo.save(driver);

        user.setDriver(true);
        userRepo.save(user);

        Map<String, Object> claims = Map.of(
                "uid", user.getId(),
                "email", user.getEmail(),
                "mode", "DRIVER",
                "profile", List.of("DRIVER")
        );
        String access = jwtTokenUtil.generateAccessToken(user.getId(), claims);
        String refresh = jwtTokenUtil.generateRefreshToken(user.getId());
        tokenStoreService.storeTokens(user.getId(), access, refresh);

        return AuthResponse.driverOK(access, refresh, DriverResponse.fromEntity(driver));
    }
}
