package com.umigo.umigoCrmBackend.Security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import com.umigo.umigoCrmBackend.Config.JwtProperties;

import java.security.Key;
import java.time.Instant;
import java.util.Date;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class JwtTokenUtil {

    private final JwtProperties jwtProperties;

    private Key getAccessKey() {
        return Keys.hmacShaKeyFor(jwtProperties.getAccessSecret().getBytes());
    }

    private Key getRefreshKey() {
        return Keys.hmacShaKeyFor(jwtProperties.getRefreshSecret().getBytes());
    }

    /** Create Access Token */
    public String generateAccessToken(String subject, Map<String, Object> claims) {
        Instant now = Instant.now();
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(now.plus(jwtProperties.getAccessTtl())))
                .signWith(getAccessKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    /** Create Refresh Token */
    public String generateRefreshToken(String subject) {
        Instant now = Instant.now();
        return Jwts.builder()
                .setSubject(subject)
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(now.plus(jwtProperties.getRefreshTtl())))
                .signWith(getRefreshKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    /** Validate Access Token */
    public boolean validateAccessToken(String token) {
        return validateToken(token, getAccessKey());
    }

    /** Validate Refresh Token */
    public boolean validateRefreshToken(String token) {
        return validateToken(token, getRefreshKey());
    }

    private boolean validateToken(String token, Key key) {
        try {
            Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    /** Extract Claims from Access Token */
    public Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getAccessKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    /** Extract Subject (e.g., email, Firebase UID) */
    public String extractSubject(String token) {
        return extractAllClaims(token).getSubject();
    }

}