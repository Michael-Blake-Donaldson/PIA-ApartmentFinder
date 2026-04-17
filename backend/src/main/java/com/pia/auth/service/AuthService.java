package com.pia.auth.service;

import com.pia.auth.domain.Role;
import com.pia.auth.domain.User;
import com.pia.auth.dto.*;
import com.pia.auth.repository.RoleRepository;
import com.pia.auth.repository.UserRepository;
import com.pia.auth.security.JwtTokenProvider;
import com.pia.common.exception.BadRequestException;
import com.pia.common.exception.ConflictException;
import com.pia.config.PiaProperties;
import com.pia.user.domain.UserSettings;
import com.pia.user.repository.UserSettingsRepository;
import com.pia.scoring.domain.ScoringPreferences;
import com.pia.scoring.repository.ScoringPreferencesRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Core authentication service.
 *
 * Registration flow:
 * 1. Check email uniqueness
 * 2. Hash password
 * 3. Assign default ROLE_USER
 * 4. Create user settings and scoring preferences with defaults
 * 5. Issue access + refresh tokens
 *
 * Login flow:
 * 1. Authenticate via Spring's AuthenticationManager (throws on bad credentials)
 * 2. Issue new token pair
 *
 * Refresh flow:
 * 3. Validate and rotate refresh token
 * 4. Issue new access token
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final UserSettingsRepository userSettingsRepository;
    private final ScoringPreferencesRepository scoringPreferencesRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;
    private final RefreshTokenService refreshTokenService;
    private final PiaProperties piaProperties;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.email().toLowerCase().strip();

        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new ConflictException("An account with this email already exists");
        }

        // Build user entity
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setFullName(request.fullName());

        // Assign default role
        Role userRole = roleRepository.findByName("ROLE_USER")
                .orElseThrow(() -> new IllegalStateException("ROLE_USER not seeded in database"));
        user.getRoles().add(userRole);

        userRepository.save(user);

        // Create default settings and scoring preferences
        UserSettings settings = new UserSettings();
        settings.setUser(user);
        userSettingsRepository.save(settings);

        ScoringPreferences prefs = new ScoringPreferences();
        prefs.setUser(user);
        scoringPreferencesRepository.save(prefs);

        log.info("New user registered: {}", email);
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        // AuthenticationManager will throw BadCredentialsException on failure
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.email().toLowerCase().strip(),
                        request.password()
                )
        );

        User user = (User) auth.getPrincipal();
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse refresh(RefreshRequest request) {
        RefreshTokenService.RotationResult result = refreshTokenService.rotate(request.refreshToken());
        User user = result.user();

        String accessToken = tokenProvider.generateAccessToken(user, user.getId());
        return AuthResponse.of(
                accessToken,
                result.newRawToken(),
                piaProperties.jwt().expirationMs(),
                user
        );
    }

    @Transactional
    public void logout(User user) {
        refreshTokenService.revokeAllForUser(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String accessToken = tokenProvider.generateAccessToken(user, user.getId());
        RefreshTokenService.TokenPair pair = refreshTokenService.issueRefreshToken(user);

        return AuthResponse.of(
                accessToken,
                pair.rawToken(),
                piaProperties.jwt().expirationMs(),
                user
        );
    }
}
