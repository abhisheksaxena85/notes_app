package com.example.notes_app.auth.dto.request;

import lombok.Data;

@Data
public class SignupRequestDto {
    private String name;
    private String email;
    private String mobile;
    private String gender;
    private String password;
}
