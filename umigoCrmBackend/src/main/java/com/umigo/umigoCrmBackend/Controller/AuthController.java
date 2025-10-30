package com.umigo.umigoCrmBackend.Controller;

import java.util.Locale;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.umigo.umigoCrmBackend.DTO.Response.AuthResponse;
import com.umigo.umigoCrmBackend.Service.AuthService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import com.umigo.umigoCrmBackend.DTO.Request.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/auth")
public class AuthController {
    
    private final AuthService authService;

    @GetMapping("/{profile}/login")
    public ResponseEntity<AuthResponse> login(@RequestHeader(name= "Authorization") String idToken, @PathVariable(name = "profile") String domainName){
        return authService.login(idToken, domainName.toUpperCase());
    }

    @PostMapping("/{profile}/register")
    public ResponseEntity<AuthResponse> register(@PathVariable(name = "profile") String domainName, @Valid @RequestBody AuthRequest request){
        String domain = domainName.trim().toLowerCase(Locale.ROOT);
        return authService.register(domain, request);
    }

    @PostMapping("/logout")
    public ResponseEntity<AuthResponse> logout(@RequestHeader(name = "Authorization", required = false) String authorizationHeader) {
        return authService.logout(authorizationHeader);
    }
}
