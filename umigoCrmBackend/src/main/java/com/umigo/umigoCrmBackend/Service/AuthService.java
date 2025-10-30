package com.umigo.umigoCrmBackend.Service;

import org.springframework.http.ResponseEntity;

import com.umigo.umigoCrmBackend.DTO.Request.AuthRequest;
import com.umigo.umigoCrmBackend.DTO.Response.AuthResponse;

public interface AuthService {

    ResponseEntity<AuthResponse> login(String idToken, String domainName);

    ResponseEntity<AuthResponse> register(String domain, AuthRequest request);

    ResponseEntity<AuthResponse> logout(String authorizationHeader);


}
