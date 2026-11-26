package com.example.notes_app.auth.dto.request;

import lombok.Data;

@Data
public class ChangePasswordRequestDto {
    private long userId;
    private String oldPassword;
    private String newPassword;
}
