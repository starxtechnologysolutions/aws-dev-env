package com.umigo.umigoCrmBackend.Repository;

import org.springframework.stereotype.Repository;
import com.umigo.umigoCrmBackend.Entity.UserToken;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

@Repository
public interface UserTokenRepository extends JpaRepository<UserToken, Integer> {

    Optional<UserToken> findByRefreshTokenAndRevokedFalse(String refreshToken);

    Optional<UserToken> findFirstByUserIdAndRevokedFalseOrderByCreatedAtDesc(String userId);

    List<UserToken> findAllByUserIdAndRevokedFalse(String userId);

    boolean existsByAccessTokenAndRevokedFalse(String accessToken);

    void deleteByRefreshExpiresAtBefore(OffsetDateTime refreshExpiresAt);
}
