package com.example.notes_app.auth.dto.request;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateUserRequestDto {
    /** SEC-01: optional with a token (taken from it); required from old token-less clients. */
    private long userId;

    @Size(max = 100, message = "Name must be at most 100 characters")
    private String name;

    @Size(max = 20, message = "Mobile number must be at most 20 characters")
    private String mobile;

    @Size(max = 20, message = "Gender must be at most 20 characters")
    private String gender;
}
