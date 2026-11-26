package com.example.notes_app.common.exception;

import org.springframework.http.HttpStatus;

/** Maps to HTTP 429. */
public class TooManyRequestsException extends ApiException {
    public TooManyRequestsException(String message) {
        super(HttpStatus.TOO_MANY_REQUESTS, message);
    }
}
