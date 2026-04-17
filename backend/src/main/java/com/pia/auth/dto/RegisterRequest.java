package com.pia.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank @Email(message = "Must be a valid email")
        String email,

        @NotBlank @Size(min = 8, max = 100, message = "Password must be 8–100 characters")
        String password,

        @Size(max = 255)
        String fullName
) {}
