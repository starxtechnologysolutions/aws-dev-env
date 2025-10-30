package com.umigo.umigoCrmBackend.Security;

import com.umigo.umigoCrmBackend.Entity.UserToken;
import com.umigo.umigoCrmBackend.Service.TokenStoreService;
import com.umigo.umigoCrmBackend.Entity.Users;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtRefreshFilter extends OncePerRequestFilter {

    private final JwtTokenUtil jwtTokenUtil;
    private final TokenStoreService tokenStoreService;
    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        String refreshHeader = request.getHeader("X-Refresh-Token");

        if (!StringUtils.hasText(authorization) || !authorization.startsWith("Bearer ")
                || !StringUtils.hasText(refreshHeader)) {
            filterChain.doFilter(request, response);
            return;
        }

        String refreshToken = refreshHeader.trim();

        try {
            if (!jwtTokenUtil.validateRefreshToken(refreshToken)) {
                filterChain.doFilter(request, response);
                return;
            }

            Optional<UserToken> tokenOpt = tokenStoreService.consumeRefreshToken(refreshToken);
            if (tokenOpt.isEmpty()) {
                filterChain.doFilter(request, response);
                return;
            }

            UserToken consumedToken = tokenOpt.get();
            Users user = consumedToken.getUser();

        List<String> profile = new ArrayList<>();
        if (user.isDriver()) {
            profile.add("DRIVER");
        }
        if (user.isStaff()) {
            profile.add("STAFF");
        }
        if (profile.isEmpty()) {
            profile.add("USER");
        }

        String mode = profile.contains("DRIVER") ? "DRIVER"
                : profile.contains("STAFF") ? "STAFF" : "USER";

        Map<String, Object> claims = Map.of(
                "uid", user.getId(),
                "email", user.getEmail(),
                "mode", mode,
                "profile", profile
        );

            String newAccessToken = jwtTokenUtil.generateAccessToken(user.getId(), claims);
            String newRefreshToken = jwtTokenUtil.generateRefreshToken(user.getId());
            tokenStoreService.storeTokens(user.getId(), newAccessToken, newRefreshToken);

            response.setHeader("X-New-Access-Token", newAccessToken);
            response.setHeader("X-New-Refresh-Token", newRefreshToken);
        } catch (Exception ex) {
            log.warn("JWT refresh processing failed: {}", ex.getMessage());
        }

        filterChain.doFilter(request, response);
    }
}
