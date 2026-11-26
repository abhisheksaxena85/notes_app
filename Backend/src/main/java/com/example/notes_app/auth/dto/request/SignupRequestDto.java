package com.example.notes_app.auth.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class SignupRequestDto {
    @NotBlank(message = "Name is required")
    @Size(max = 100, message = "Name must be at most 100 characters")
    private String name;

    @NotBlank(message = "Email is required")
    @Email(message = "Enter a valid email address")
    @Size(max = 320, message = "Email must be at most 320 characters")
    private String email;

    @Size(max = 20, message = "Mobile number must be at most 20 characters")
    private String mobile;

    @Size(max = 20, message = "Gender must be at most 20 characters")
    private String gender;

    /** Trimmed before validation so " a@b.com " is accepted; lower-casing happens in the service. */
    public void setEmail(String email) {
        this.email = email == null ? null : email.trim();
    }

    // 72 is BCrypt's input limit. Passwords are never trimmed.
    @NotEmpty(message = "Password is required")
    @Size(min = 8, max = 72, message = "Password must be between 8 and 72 characters")
    private String password;
}
