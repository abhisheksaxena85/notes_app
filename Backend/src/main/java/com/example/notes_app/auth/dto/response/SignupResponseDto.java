package com.example.notes_app.auth.dto.response;

import lombok.Data;

@Data
public class SignupResponseDto {
    private long userId;

    /** SEC-01: bearer token for {@code Authorization: Bearer <accessToken>}. */
    private String accessToken;

    /** When {@link #accessToken} expires, ISO-8601 UTC (e.g. {@code 2026-12-04T10:00:00Z}). */
    private String expiresAt;
}
