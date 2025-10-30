package com.umigo.umigoCrmBackend.Security;

import java.io.Serializable;
import java.time.OffsetDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * Lightweight token snapshot cached in Redis.
 */
@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TokenCacheEntry implements Serializable {

    private String userId;
    private String accessToken;
    private String refreshToken;
    private OffsetDateTime accessExpiresAt;
    private OffsetDateTime refreshExpiresAt;
}
