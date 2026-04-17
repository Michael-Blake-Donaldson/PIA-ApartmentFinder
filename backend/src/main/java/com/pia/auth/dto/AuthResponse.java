package com.pia.auth.dto;

import java.util.UUID;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        long expiresIn,
        UserSummary user
) {
    public record UserSummary(UUID id, String email, String fullName, boolean admin) {}

    public static AuthResponse of(
            String accessToken,
            String refreshToken,
            long expiresIn,
            com.pia.auth.domain.User user
    ) {
        return new AuthResponse(
                accessToken,
                refreshToken,
                "Bearer",
                expiresIn,
                new UserSummary(user.getId(), user.getEmail(), user.getFullName(), user.isAdmin())
        );
    }
}
