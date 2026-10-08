package com.example.notes_app.notes.dto.request;

import lombok.Data;

@Data
public class UpdateNoteRequestDto {
    private long noteId;
    private String title;
    private String content;
    private String category;
    private boolean isPinned;
}
