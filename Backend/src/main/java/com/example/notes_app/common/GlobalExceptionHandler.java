package com.example.notes_app.common;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ExceptionHandler {
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<void>> handleException(Exception ex){
        
    }
}
