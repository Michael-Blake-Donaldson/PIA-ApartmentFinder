package com.pia.auth.security;

import com.pia.config.PiaProperties;
import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;

/**
 * JWT utility for creating and validating access tokens.
 *
 * Access tokens are short-lived (default 15 min) and contain only the minimum
 * necessary claims: subject (email), userId, roles.
 *
 * We use HMAC-SHA256 (HS256) with a secret key derived from the configured
 * JWT_SECRET environment variable. The key must be at minimum 48 characters.
 */
@Slf4j
@Component
public class JwtTokenProvider {

    private final SecretKey signingKey;
    private final long expirationMs;

    public JwtTokenProvider(PiaProperties piaProperties) {
        String secret = piaProperties.jwt().secret();
        if (secret == null || secret.length() < 48) {
            throw new IllegalStateException(
                    "JWT_SECRET must be at least 48 characters. " +
                    "Generate one with: openssl rand -base64 64"
            );
        }
        this.signingKey = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = piaProperties.jwt().expirationMs();
    }

    public String generateAccessToken(UserDetails userDetails, UUID userId) {
        return Jwts.builder()
                .subject(userDetails.getUsername())
                .claim("userId", userId.toString())
                .claim("roles", userDetails.getAuthorities().stream()
                        .map(a -> a.getAuthority()).toList())
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + expirationMs))
                .signWith(signingKey, Jwts.SIG.HS256)
                .compact();
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public UUID extractUserId(String token) {
        String id = extractClaim(token, claims -> claims.get("userId", String.class));
        return id != null ? UUID.fromString(id) : null;
    }

    public boolean isTokenValid(String token, UserDetails userDetails) {
        try {
            String username = extractUsername(token);
            return username.equals(userDetails.getUsername()) && !isTokenExpired(token);
        } catch (JwtException e) {
            log.debug("JWT validation failed: {}", e.getMessage());
            return false;
        }
    }

    private boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    private <T> T extractClaim(String token, Function<Claims, T> resolver) {
        Claims claims = extractAllClaims(token);
        return resolver.apply(claims);
    }

    private Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(signingKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
