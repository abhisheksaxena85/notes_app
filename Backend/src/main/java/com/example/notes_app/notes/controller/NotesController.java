package com.example.notes_app.notes.controller;

import com.example.notes_app.common.ApiResponse;
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

    @GetMapping("/get-all-notes")
    public ResponseEntity<ApiResponse<List<NotesModel>>> getAllNotes(@RequestParam long id){
        return notesService.getNotes(id);
    }

    @PostMapping("/create-note")
    public ResponseEntity<ApiResponse<NotesModel>> createNote(@RequestBody NotesModel requestDto, @RequestParam long userId){
        return notesService.createNote(userId, requestDto);
    }

    @PutMapping("/update-note")
    public ResponseEntity<ApiResponse<NotesModel>> updateNote(@RequestBody NotesModel newNote, @RequestParam long id){
        return notesService.updateNote(id, newNote);
    }

    @DeleteMapping("/delete-note")
    public ResponseEntity<ApiResponse<NotesModel>> deleteNote(@RequestBody long id){
        return notesService.deleteNote(id);
    }
}
