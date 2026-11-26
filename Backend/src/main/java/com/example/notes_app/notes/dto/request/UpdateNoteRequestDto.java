package com.example.notes_app.notes.dto.request;

import com.example.notes_app.notes.model.NoteLimits;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateNoteRequestDto {
    private long noteId;
    @Size(max = NoteLimits.TITLE_MAX, message = "Title must be at most " + NoteLimits.TITLE_MAX + " characters")
    private String title;
    @Size(max = NoteLimits.CONTENT_MAX, message = "Content must be at most " + NoteLimits.CONTENT_MAX + " characters")
    private String content;
    @Size(max = NoteLimits.CATEGORY_MAX, message = "Category must be at most " + NoteLimits.CATEGORY_MAX + " characters")
    private String category;
    private boolean isPinned;
    @Size(max = NoteLimits.TAGS_MAX, message = "Tags must be at most " + NoteLimits.TAGS_MAX + " characters")
    private String tags;
}
