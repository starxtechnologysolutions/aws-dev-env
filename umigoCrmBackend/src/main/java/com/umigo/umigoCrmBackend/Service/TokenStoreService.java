package com.umigo.umigoCrmBackend.Service;

import com.umigo.umigoCrmBackend.Entity.UserToken;
import java.util.Optional;

public interface TokenStoreService {
    void storeTokens(String userId, String accessToken, String refreshToken);

    boolean isAccessTokenValid(String userId, String accessToken);

    Optional<UserToken> consumeRefreshToken(String refreshToken);

    void revokeTokens(String userId);

    void cleanupExpiredTokens();
}
