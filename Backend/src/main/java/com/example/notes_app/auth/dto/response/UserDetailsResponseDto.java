package com.example.notes_app.auth.dto.response;

import lombok.Data;

@Data
public class UserDetailsResponseDto {
    private long id;
    private String name;
    private String email;
    private String mobile;
    private String gender;
}
