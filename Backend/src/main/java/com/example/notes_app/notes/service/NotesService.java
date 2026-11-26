package com.example.notes_app.notes.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.IdempotentCreate;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.notes.dto.request.CreateNoteRequestDto;
import com.example.notes_app.notes.dto.request.UpdateNoteRequestDto;
import com.example.notes_app.notes.dto.response.CalendarSummaryResponseDto;
import com.example.notes_app.notes.dto.response.CreateNoteResponseDto;
import com.example.notes_app.notes.dto.response.DayActivityResponseDto;
import com.example.notes_app.notes.dto.response.ExportNotesResponseDto;
import com.example.notes_app.notes.dto.response.UpdateNoteResponseDto;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.repository.NotesRepository;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.tasks.model.TaskModel;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class NotesService {

    @Autowired
    NotesRepository notesRepository;

    @Autowired
    AuthRepository authRepository;

    @Autowired
    private com.example.notes_app.tasks.repository.TaskRepository taskRepository;

    @Autowired
    private com.example.notes_app.reminders.repository.ReminderRepository reminderRepository;

    private UserModel requireUser(long userId) {
        return authRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
    }

    private NotesModel requireNote(long noteId) {
        return notesRepository.findById(noteId)
                .orElseThrow(() -> new NotFoundException("Note not found"));
    }

    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> getNoteDetails(long noteId){
        NotesModel currentNote = requireNote(noteId);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Successfully fetched the details", currentNote));
    }

    @Transactional
    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotes(long id){
        UserModel user = requireUser(id);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Successfully fetched notes", user.getArticles()));
    }

    /** Not @Transactional on purpose: see {@link IdempotentCreate}. */
    public ResponseEntity<ApiResponse<CreateNoteResponseDto>> createNote(CreateNoteRequestDto requestDto){
        UserModel user = requireUser(requestDto.getUserId());
        String clientId = IdempotentCreate.normalize(requestDto.getClientId());
        IdempotentCreate.Result<NotesModel> result = IdempotentCreate.createOnce(
                clientId,
                () -> notesRepository.findByUser_IdAndClientId(user.getId(), clientId),
                () -> {
                    NotesModel newNote = new NotesModel();
                    newNote.setTitle(requestDto.getTitle());
                    newNote.setContent(requestDto.getContent());
                    newNote.setCategory(requestDto.getCategory());
                    newNote.setPinned(requestDto.isPinned());
                    newNote.setTags(requestDto.getTags());
                    newNote.setClientId(clientId);
                    newNote.setUser(user);
                    newNote.setCreatedAt(LocalDateTime.now().toString());
                    newNote.setUpdatedAt(LocalDateTime.now().toString());
                    return notesRepository.save(newNote);
                });

        CreateNoteResponseDto responseDto = new CreateNoteResponseDto();
        responseDto.setNoteId(result.entity().getNoteId());
        String message = result.created() ? "Note saved successfully!" : "Note already saved";
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, message, responseDto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<UpdateNoteResponseDto>> updateNote(UpdateNoteRequestDto requestDto){
        NotesModel currentNote = requireNote(requestDto.getNoteId());
        currentNote.setTitle(requestDto.getTitle());
        currentNote.setContent(requestDto.getContent());
        currentNote.setUpdatedAt(LocalDateTime.now().toString());
        currentNote.setCategory(requestDto.getCategory());
        currentNote.setPinned(requestDto.isPinned());
        if (requestDto.getTags() != null) {
            currentNote.setTags(requestDto.getTags());
        }
        notesRepository.save(currentNote);

        UpdateNoteResponseDto responseDto = new UpdateNoteResponseDto();
        responseDto.setNoteId(currentNote.getNoteId());
        responseDto.setTitle(currentNote.getTitle());
        responseDto.setContent(currentNote.getContent());
        responseDto.setCategory(currentNote.getCategory());
        responseDto.setTags(currentNote.getTags());
        responseDto.setCreatedAt(currentNote.getCreatedAt());
        responseDto.setUpdateAt(currentNote.getUpdatedAt());
        responseDto.setPinned(currentNote.isPinned());
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Successfully updated note!", responseDto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> deleteNote(long id){
        NotesModel currentNote = requireNote(id);
        notesRepository.deleteById(id);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Successfully deleted note", currentNote));
    }

    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> togglePin(long noteId) {
        NotesModel currentNote = requireNote(noteId);
        currentNote.setPinned(!currentNote.isPinned());
        currentNote.setUpdatedAt(LocalDateTime.now().toString());
        notesRepository.save(currentNote);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Pin status updated successfully!", currentNote));
    }

    @Transactional
    public ResponseEntity<ApiResponse<CalendarSummaryResponseDto>> getCalendarSummary(long userId, int year, int month) {
        if (month < 1 || month > 12) {
            throw new BadRequestException("Month must be between 1 and 12");
        }
        UserModel user = requireUser(userId);
        String prefix = String.format("%04d-%02d", year, month);

        Map<String, Integer> totalCounts = new HashMap<>();
        Map<String, Integer> noteCounts = new HashMap<>();
        Map<String, Integer> taskCounts = new HashMap<>();
        Map<String, Integer> reminderCounts = new HashMap<>();

        // 1. Process Notes
        List<NotesModel> notes = user.getArticles();
        int noteTotal = 0;
        if (notes != null) {
            for (NotesModel note : notes) {
                if (note.getCreatedAt() != null && note.getCreatedAt().length() >= 10) {
                    String dateKey = note.getCreatedAt().substring(0, 10);
                    if (dateKey.startsWith(prefix)) {
                        noteCounts.put(dateKey, noteCounts.getOrDefault(dateKey, 0) + 1);
                        totalCounts.put(dateKey, totalCounts.getOrDefault(dateKey, 0) + 1);
                        noteTotal++;
                    }
                }
            }
        }

        // 2. Process Tasks
        List<com.example.notes_app.tasks.model.TaskModel> tasks = taskRepository.findByUserIdAndMonth(userId, prefix);
        int taskTotal = 0;
        if (tasks != null) {
            taskTotal = tasks.size();
            for (com.example.notes_app.tasks.model.TaskModel task : tasks) {
                String dateKey = (task.getDueDate() != null && task.getDueDate().length() >= 10)
                        ? task.getDueDate().substring(0, 10)
                        : (task.getCreatedAt() != null && task.getCreatedAt().length() >= 10 ? task.getCreatedAt().substring(0, 10) : null);
                if (dateKey != null && dateKey.startsWith(prefix)) {
                    taskCounts.put(dateKey, taskCounts.getOrDefault(dateKey, 0) + 1);
                    totalCounts.put(dateKey, totalCounts.getOrDefault(dateKey, 0) + 1);
                }
            }
        }

        // 3. Process Reminders
        List<com.example.notes_app.reminders.model.ReminderModel> reminders = reminderRepository.findByUserIdAndMonth(userId, prefix);
        int reminderTotal = 0;
        if (reminders != null) {
            reminderTotal = reminders.size();
            for (com.example.notes_app.reminders.model.ReminderModel reminder : reminders) {
                String dateKey = (reminder.getDueDate() != null && reminder.getDueDate().length() >= 10)
                        ? reminder.getDueDate().substring(0, 10)
                        : (reminder.getRemindAt() != null && reminder.getRemindAt().length() >= 10 ? reminder.getRemindAt().substring(0, 10) : null);
                if (dateKey != null && dateKey.startsWith(prefix)) {
                    reminderCounts.put(dateKey, reminderCounts.getOrDefault(dateKey, 0) + 1);
                    totalCounts.put(dateKey, totalCounts.getOrDefault(dateKey, 0) + 1);
                }
            }
        }

        int grandTotal = noteTotal + taskTotal + reminderTotal;
        CalendarSummaryResponseDto dto = new CalendarSummaryResponseDto(
                year, month, noteTotal, taskTotal, reminderTotal, grandTotal,
                totalCounts, noteCounts, taskCounts, reminderCounts
        );
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Calendar summary generated", dto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotesByDate(long userId, String date) {
        requireUser(userId);
        List<NotesModel> matchingNotes = notesRepository.findByUserIdAndDatePrefix(userId, date);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Fetched notes for date " + date, matchingNotes));
    }

    @Transactional
    public ResponseEntity<ApiResponse<DayActivityResponseDto>> getDayActivity(long userId, String date) {
        if (date == null || !date.matches("\\d{4}-\\d{2}-\\d{2}")) {
            throw new BadRequestException("Date must be in YYYY-MM-DD format");
        }
        requireUser(userId);
        // Same bucketing rules as getCalendarSummary so day totals match the badges.
        List<NotesModel> notes = notesRepository.findByUserIdAndDatePrefix(userId, date);
        List<TaskModel> tasks = taskRepository.findByUserIdAndMonth(userId, date);
        List<ReminderModel> reminders = reminderRepository.findByUserIdAndMonth(userId, date);

        DayActivityResponseDto dto = new DayActivityResponseDto(
                date,
                notes.size() + tasks.size() + reminders.size(),
                notes,
                tasks,
                reminders
        );
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Fetched activity for date " + date, dto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<List<NotesModel>>> searchNotes(long userId, String query) {
        List<NotesModel> results = notesRepository.searchNotes(userId, query);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Search completed", results));
    }

    @Transactional
    public ResponseEntity<ApiResponse<ExportNotesResponseDto>> exportNotes(long userId) {
        UserModel user = requireUser(userId);
        List<NotesModel> notes = user.getArticles();
        ExportNotesResponseDto dto = new ExportNotesResponseDto(
                1,
                LocalDateTime.now().toString(),
                userId,
                notes.size(),
                notes
        );
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Notes exported successfully", dto));
    }
}
