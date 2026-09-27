package com.example.notes_app.notes.error;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
public class ErrorResponseModel {

    private int status;
    private String message;
    private LocalDateTime timestamp;
}