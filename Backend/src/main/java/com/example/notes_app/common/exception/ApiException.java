package com.example.notes_app.common.exception;

import org.springframework.http.HttpStatus;

/**
 * Base type for expected API failures. The message is sent to the client as-is,
 * so it must be a short, user-safe sentence (never exception or SQL text).
 */
public abstract class ApiException extends RuntimeException {

    private final HttpStatus status;

    protected ApiException(HttpStatus status, String message) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
