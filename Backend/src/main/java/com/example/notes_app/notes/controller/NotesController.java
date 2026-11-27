package com.example.notes_app.notes.controller;

import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.CurrentUser;
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

    @Autowired
    CurrentUser currentUser;

    @GetMapping("/get-details-by-noteId")
    public ResponseEntity<ApiResponse<NotesModel>> getNoteDetails(@RequestParam long id){
        return notesService.getNoteDetails(id, currentUser.ownerScope());
    }

    @GetMapping("/get-all-notes")
    public ResponseEntity<ApiResponse<List<NotesModel>>> getAllNotes(@RequestParam(required = false) Long id){
        return notesService.getNotes(currentUser.resolve(id, "id"));
    }

    @PostMapping("/create-note")
    public ResponseEntity<ApiResponse<CreateNoteResponseDto>> createNote(@Valid @RequestBody CreateNoteRequestDto requestDto){
        requestDto.setUserId(currentUser.resolve(requestDto.getUserId(), "userId"));
        return notesService.createNote(requestDto);
    }

    @PutMapping("/update-note")
    public ResponseEntity<ApiResponse<UpdateNoteResponseDto>> updateNote(@Valid @RequestBody UpdateNoteRequestDto requestDto){
        return notesService.updateNote(requestDto, currentUser.ownerScope());
    }

    @PutMapping("/toggle-pin")
    public ResponseEntity<ApiResponse<NotesModel>> togglePin(@RequestParam long id){
        return notesService.togglePin(id, currentUser.ownerScope());
    }

    @DeleteMapping("/delete-note")
    public ResponseEntity<ApiResponse<NotesModel>> deleteNote(
            @RequestParam(name = "id", required = false) Long paramId,
            @RequestBody(required = false) Long bodyId){
        Long targetId = paramId != null ? paramId : bodyId;
        if (targetId == null) {
            throw new BadRequestException("Note id is required");
        }
        return notesService.deleteNote(targetId, currentUser.ownerScope());
    }

    @GetMapping("/calendar-summary")
    public ResponseEntity<ApiResponse<CalendarSummaryResponseDto>> getCalendarSummary(
            @RequestParam(required = false) Long userId,
            @RequestParam int year,
            @RequestParam int month,
            @RequestParam(required = false) String tz){
        return notesService.getCalendarSummary(currentUser.resolve(userId, "userId"), year, month, tz);
    }

    @GetMapping("/get-notes-by-date")
    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotesByDate(
            @RequestParam(required = false) Long userId,
            @RequestParam String date,
            @RequestParam(required = false) String tz){
        return notesService.getNotesByDate(currentUser.resolve(userId, "userId"), date, tz);
    }

    @GetMapping("/day-activity")
    public ResponseEntity<ApiResponse<DayActivityResponseDto>> getDayActivity(
            @RequestParam(required = false) Long userId,
            @RequestParam String date,
            @RequestParam(required = false) String tz){
        return notesService.getDayActivity(currentUser.resolve(userId, "userId"), date, tz);
    }

    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<NotesModel>>> searchNotes(
            @RequestParam(required = false) Long userId,
            @RequestParam String query){
        return notesService.searchNotes(currentUser.resolve(userId, "userId"), query);
    }

    @GetMapping("/export")
    public ResponseEntity<ApiResponse<ExportNotesResponseDto>> exportNotes(@RequestParam(required = false) Long userId){
        return notesService.exportNotes(currentUser.resolve(userId, "userId"));
    }
}
