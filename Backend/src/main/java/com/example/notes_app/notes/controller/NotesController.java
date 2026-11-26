package com.example.notes_app.notes.controller;

import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.notes.dto.request.CreateNoteRequestDto;
import com.example.notes_app.notes.dto.request.UpdateNoteRequestDto;
import com.example.notes_app.notes.dto.response.CalendarSummaryResponseDto;
import com.example.notes_app.notes.dto.response.CreateNoteResponseDto;
import com.example.notes_app.notes.dto.response.DayActivityResponseDto;
import com.example.notes_app.notes.dto.response.ExportNotesResponseDto;
import com.example.notes_app.notes.dto.response.UpdateNoteResponseDto;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.service.NotesService;
import jakarta.validation.Valid;
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
    public ResponseEntity<ApiResponse<CreateNoteResponseDto>> createNote(@Valid @RequestBody CreateNoteRequestDto requestDto){
        return notesService.createNote(requestDto);
    }

    @PutMapping("/update-note")
    public ResponseEntity<ApiResponse<UpdateNoteResponseDto>> updateNote(@Valid @RequestBody UpdateNoteRequestDto requestDto){
        return notesService.updateNote(requestDto);
    }

    @PutMapping("/toggle-pin")
    public ResponseEntity<ApiResponse<NotesModel>> togglePin(@RequestParam long id){
        return notesService.togglePin(id);
    }

    @DeleteMapping("/delete-note")
    public ResponseEntity<ApiResponse<NotesModel>> deleteNote(
            @RequestParam(name = "id", required = false) Long paramId,
            @RequestBody(required = false) Long bodyId){
        Long targetId = paramId != null ? paramId : bodyId;
        if (targetId == null) {
            throw new BadRequestException("Note id is required");
        }
        return notesService.deleteNote(targetId);
    }

    @GetMapping("/calendar-summary")
    public ResponseEntity<ApiResponse<CalendarSummaryResponseDto>> getCalendarSummary(
            @RequestParam long userId,
            @RequestParam int year,
            @RequestParam int month,
            @RequestParam(required = false) String tz){
        return notesService.getCalendarSummary(userId, year, month, tz);
    }

    @GetMapping("/get-notes-by-date")
    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotesByDate(
            @RequestParam long userId,
            @RequestParam String date,
            @RequestParam(required = false) String tz){
        return notesService.getNotesByDate(userId, date, tz);
    }

    @GetMapping("/day-activity")
    public ResponseEntity<ApiResponse<DayActivityResponseDto>> getDayActivity(
            @RequestParam long userId,
            @RequestParam String date,
            @RequestParam(required = false) String tz){
        return notesService.getDayActivity(userId, date, tz);
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<NotesModel>>> searchNotes(
            @RequestParam long userId,
            @RequestParam String query){
        return notesService.searchNotes(userId, query);
    }

    @GetMapping("/export")
    public ResponseEntity<ApiResponse<ExportNotesResponseDto>> exportNotes(@RequestParam long userId){
        return notesService.exportNotes(userId);
    }
}
