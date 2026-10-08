package com.example.notes_app.notes.dto.response;

import lombok.Data;

@Data
public class UpdateNoteResponseDto {
    private long noteId;
    private String title;
    private String content;
    private String category;
    private boolean isPinned;
    private String updateAt;
    private String createdAt;
}
