package com.example.notes_app.notes.dto.response;

import com.example.notes_app.notes.model.NotesModel;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExportNotesResponseDto {
    private int exportVersion;
    private String exportedAt;
    private long userId;
    private int totalNotes;
    private List<NotesModel> notes;
}
