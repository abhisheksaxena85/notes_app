package com.example.notes_app.auth.dto.request;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ChangePasswordRequestDto {
    /** SEC-01: optional with a token (taken from it); required from old token-less clients. */
    private long userId;

    @NotEmpty(message = "Old password is required")
    @Size(max = 72, message = "Old password must be at most 72 characters")
    private String oldPassword;

    @NotEmpty(message = "New password is required")
    @Size(min = 8, max = 72, message = "New password must be between 8 and 72 characters")
    private String newPassword;
}
