package com.example.notes_app.auth.dto.request;

import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateUserRequestDto {
    @Positive(message = "User id is required")
    private long userId;

    @Size(max = 100, message = "Name must be at most 100 characters")
    private String name;

    @Size(max = 20, message = "Mobile number must be at most 20 characters")
    private String mobile;

    @Size(max = 20, message = "Gender must be at most 20 characters")
    private String gender;
}
