package com.umigo.umigoCrmBackend.Service.Impl;

import com.umigo.umigoCrmBackend.Config.JwtProperties;
import com.umigo.umigoCrmBackend.Entity.UserToken;
import com.umigo.umigoCrmBackend.Entity.Users;
import com.umigo.umigoCrmBackend.Repository.UserRepository;
import com.umigo.umigoCrmBackend.Repository.UserTokenRepository;
import com.umigo.umigoCrmBackend.Security.TokenCacheEntry;
import com.umigo.umigoCrmBackend.Service.TokenStoreService;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class TokenStoreServiceImpl implements TokenStoreService {

    private static final String TOKEN_CACHE_PREFIX = "auth:tokens:";
    private static final String REFRESH_CACHE_PREFIX = "auth:refresh:";

    private final RedisTemplate<String, Object> redisTemplate;
    private final UserTokenRepository userTokenRepository;
    private final UserRepository userRepository;
    private final JwtProperties jwtProperties;

    @Override
    @Transactional
    public void storeTokens(String userId, String accessToken, String refreshToken) {
        OffsetDateTime now = OffsetDateTime.now();
        OffsetDateTime accessExpiry = now.plus(jwtProperties.getAccessTtl());
        OffsetDateTime refreshExpiry = now.plus(jwtProperties.getRefreshTtl());

        List<UserToken> activeTokens = userTokenRepository.findAllByUserIdAndRevokedFalse(userId);
        for (UserToken existing : activeTokens) {
            existing.setRevoked(true);
            userTokenRepository.save(existing);
            clearCache(existing.getUser().getId(), existing.getRefreshToken());
        }

        Users user = userRepository.findById(userId)
                .orElseThrow(() -> new EmptyResultDataAccessException("User not found for id " + userId, 1));

        UserToken userToken = UserToken.builder()
                .user(user)
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .revoked(false)
                .accessExpiresAt(accessExpiry)
                .refreshExpiresAt(refreshExpiry)
                .build();

        userTokenRepository.save(userToken);
        cacheEntry(userId, userToken, now);
        log.debug("Stored tokens for user {} with refresh expiry {}", userId, refreshExpiry);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isAccessTokenValid(String userId, String accessToken) {
        OffsetDateTime now = OffsetDateTime.now();
        TokenCacheEntry cached = getCachedEntry(userId);
        if (cached != null
                && accessToken.equals(cached.getAccessToken())
                && cached.getAccessExpiresAt().isAfter(now)) {
            return true;
        }

        return userTokenRepository.findFirstByUserIdAndRevokedFalseOrderByCreatedAtDesc(userId)
                .filter(token -> token.getAccessToken().equals(accessToken))
                .filter(token -> token.getAccessExpiresAt().isAfter(now))
                .map(token -> {
                    cacheEntry(userId, token, now);
                    return true;
                })
                .orElse(false);
    }

    @Override
    @Transactional
    public Optional<UserToken> consumeRefreshToken(String refreshToken) {
        OffsetDateTime now = OffsetDateTime.now();

        String userId = (String) redisTemplate.opsForValue().get(refreshKey(refreshToken));
        if (userId != null) {
            TokenCacheEntry cached = getCachedEntry(userId);
            if (cached != null
                    && refreshToken.equals(cached.getRefreshToken())
                    && cached.getRefreshExpiresAt().isAfter(now)) {
                Optional<UserToken> tokenOpt = userTokenRepository.findByRefreshTokenAndRevokedFalse(refreshToken);
                tokenOpt.ifPresent(token -> {
                    token.setRevoked(true);
                    userTokenRepository.save(token);
                });
                clearCache(userId, refreshToken);
                return tokenOpt;
            }
        }

        return userTokenRepository.findByRefreshTokenAndRevokedFalse(refreshToken)
                .map(token -> {
                    boolean expired = token.getRefreshExpiresAt().isBefore(now);
                    token.setRevoked(true);
                    userTokenRepository.save(token);
                    clearCache(token.getUser().getId(), refreshToken);
                    return expired ? null : token;
                })
                .filter(Objects::nonNull);
    }

    @Override
    @Transactional
    public void revokeTokens(String userId) {
        userTokenRepository.findFirstByUserIdAndRevokedFalseOrderByCreatedAtDesc(userId)
                .ifPresent(token -> {
                    token.setRevoked(true);
                    userTokenRepository.save(token);
                    clearCache(userId, token.getRefreshToken());
                });
    }

    @Override
    @Transactional
    public void cleanupExpiredTokens() {
        OffsetDateTime now = OffsetDateTime.now();
        userTokenRepository.deleteByRefreshExpiresAtBefore(now);
    }

    private void cacheEntry(String userId, UserToken token, OffsetDateTime now) {
        TokenCacheEntry cacheEntry = TokenCacheEntry.builder()
                .userId(userId)
                .accessToken(token.getAccessToken())
                .refreshToken(token.getRefreshToken())
                .accessExpiresAt(token.getAccessExpiresAt())
                .refreshExpiresAt(token.getRefreshExpiresAt())
                .build();

        Duration ttl = Duration.between(now, token.getRefreshExpiresAt());
        if (ttl.isNegative() || ttl.isZero()) {
            clearCache(userId, token.getRefreshToken());
            return;
        }

        redisTemplate.opsForValue().set(cacheKey(userId), cacheEntry, ttl);
        redisTemplate.opsForValue().set(refreshKey(token.getRefreshToken()), userId, ttl);
    }

    private TokenCacheEntry getCachedEntry(String userId) {
        Object cached = redisTemplate.opsForValue().get(cacheKey(userId));
        if (cached instanceof TokenCacheEntry entry) {
            return entry;
        }
        return null;
    }

    private void clearCache(String userId, String refreshToken) {
        redisTemplate.delete(cacheKey(userId));
        redisTemplate.delete(refreshKey(refreshToken));
    }

    private String cacheKey(String userId) {
        return TOKEN_CACHE_PREFIX + userId;
    }

    private String refreshKey(String refreshToken) {
        return REFRESH_CACHE_PREFIX + refreshToken;
    }
}
