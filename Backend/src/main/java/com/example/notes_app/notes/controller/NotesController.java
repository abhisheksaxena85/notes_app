package com.example.notes_app.notes.controller;

import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.notes.dto.request.CreateNoteRequestDto;
import com.example.notes_app.notes.dto.request.UpdateNoteRequestDto;
import com.example.notes_app.notes.dto.response.CreateNoteResponseDto;
import com.example.notes_app.notes.dto.response.UpdateNoteResponseDto;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.service.NotesService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/notes")
public class NotesController {

    @Autowired
    NotesService notesService;

    @GetMapping("/get-details-by-noteId")
    public ResponseEntity<ApiResponse<NotesModel>> getNoteDetails(@RequestParam long id){
        return notesService.getNoteDetails(id);
    }

    @GetMapping("/get-all-notes")
    public ResponseEntity<ApiResponse<List<NotesModel>>> getAllNotes(@RequestParam long id){
        return notesService.getNotes(id);
    }

    @PostMapping("/create-note")
    public ResponseEntity<ApiResponse<CreateNoteResponseDto>> createNote(@RequestBody CreateNoteRequestDto requestDto){
        return notesService.createNote(requestDto);
    }

    @PutMapping("/update-note")
    public ResponseEntity<ApiResponse<UpdateNoteResponseDto>> updateNote(@RequestBody UpdateNoteRequestDto requestDto){
        return notesService.updateNote(requestDto);
    }

    @DeleteMapping("/delete-note")
    public ResponseEntity<ApiResponse<NotesModel>> deleteNote(@RequestBody long id){
        return notesService.deleteNote(id);
    }
}
