package com.example.notes_app.common.exception;

import org.springframework.http.HttpStatus;

/** Maps to HTTP 401. */
public class UnauthorizedException extends ApiException {
    public UnauthorizedException(String message) {
        super(HttpStatus.UNAUTHORIZED, message);
    }
}
