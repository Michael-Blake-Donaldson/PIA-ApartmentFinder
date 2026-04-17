package com.pia.auth.service;

import com.pia.auth.domain.RefreshToken;
import com.pia.auth.domain.User;
import com.pia.auth.repository.RefreshTokenRepository;
import com.pia.config.PiaProperties;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;

/**
 * Manages refresh token lifecycle: issue, validate, rotate, revoke.
 *
 * Rotation strategy: each successful token use issues a new token and revokes the
 * old one. This limits the window of use for any stolen token.
 *
 * We store only the SHA-256 hash of the raw token. The raw token is sent to the
 * client once and never stored server-side.
 */
@Service
@RequiredArgsConstructor
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final PiaProperties piaProperties;

    /** Issue a new refresh token for a user. Returns both the raw token and the entity. */
    @Transactional
    public TokenPair issueRefreshToken(User user) {
        String rawToken = UUID.randomUUID() + "-" + UUID.randomUUID();
        String tokenHash = sha256(rawToken);

        RefreshToken entity = new RefreshToken();
        entity.setUser(user);
        entity.setTokenHash(tokenHash);
        entity.setExpiresAt(Instant.now()
                .plusMillis(piaProperties.jwt().refreshExpirationMs()));

        refreshTokenRepository.save(entity);
        return new TokenPair(rawToken, entity);
    }

    /**
     * Validate a raw refresh token, rotate it, and return the new raw token.
     * Throws if the token is invalid, expired, or revoked.
     */
    @Transactional
    public RotationResult rotate(String rawToken) {
        String hash = sha256(rawToken);

        RefreshToken existing = refreshTokenRepository.findByTokenHash(hash)
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token"));

        if (!existing.isValid()) {
            // If token is already revoked, revoke all tokens for user (potential theft)
            if (existing.isRevoked()) {
                refreshTokenRepository.revokeAllForUser(existing.getUser());
            }
            throw new IllegalArgumentException("Refresh token is expired or revoked");
        }

        // Revoke the old token
        existing.setRevoked(true);
        refreshTokenRepository.save(existing);

        // Issue a new one
        TokenPair newPair = issueRefreshToken(existing.getUser());
        return new RotationResult(existing.getUser(), newPair.rawToken());
    }

    @Transactional
    public void revokeAllForUser(User user) {
        refreshTokenRepository.revokeAllForUser(user);
    }

    /** Cleanup job: remove expired and revoked tokens nightly */
    @Scheduled(cron = "0 0 3 * * *")
    @Transactional
    public void cleanupExpiredTokens() {
        refreshTokenRepository.deleteExpiredAndRevoked(Instant.now());
    }

    private String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }

    public record TokenPair(String rawToken, RefreshToken entity) {}
    public record RotationResult(User user, String newRawToken) {}
}
