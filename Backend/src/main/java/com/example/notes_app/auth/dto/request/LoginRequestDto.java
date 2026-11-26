package com.example.notes_app.auth.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class LoginRequestDto {
    @NotBlank(message = "Email is required")
    @Size(max = 320, message = "Email must be at most 320 characters")
    private String email;

    // No minimum length here: accounts created before the 8-character rule must still be able to log in.
    @NotEmpty(message = "Password is required")
    @Size(max = 72, message = "Password must be at most 72 characters")
    private String password;
}
