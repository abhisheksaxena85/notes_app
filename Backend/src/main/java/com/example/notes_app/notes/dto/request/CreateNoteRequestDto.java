package com.example.notes_app.notes.dto.request;

import lombok.Data;

@Data
public class CreateNoteRequestDto {
    private long userId;
    private String title;
    private String content;
    private String category;
    private boolean isPinned;
}
