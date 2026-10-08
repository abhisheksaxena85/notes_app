package com.example.notes_app.auth.dto.response;

import lombok.Data;

@Data
public class UpdateUserResponseDto {
    private long userId;
    private String name;
    private String mobile;
    private String gender;
}
