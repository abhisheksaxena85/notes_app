package com.example.notes_app.auth.dto.request;

import lombok.Data;

@Data
public class UpdateUserRequestDto {
    private long userId;
    private String name;
    private String mobile;
    private String gender;
}
