package com.example.notes_app.notes.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.IdempotentCreate;
import com.example.notes_app.common.Timestamps;
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
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

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
                    newNote.setCreatedAt(Timestamps.now());
                    newNote.setUpdatedAt(Timestamps.now());
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
        currentNote.setUpdatedAt(Timestamps.now());
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
        currentNote.setUpdatedAt(Timestamps.now());
        notesRepository.save(currentNote);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Pin status updated successfully!", currentNote));
    }

    /** Notes: the day they were created, in the caller's zone. */
    private static Optional<String> noteDay(NotesModel note, ZoneId zone) {
        return Timestamps.localDay(note.getCreatedAt(), zone).map(LocalDate::toString);
    }

    /**
     * Tasks: the due date the user picked (a wall-clock value, not converted);
     * without one, the day the task was created in the caller's zone.
     */
    private static Optional<String> taskDay(TaskModel task, ZoneId zone) {
        if (task.getDueDate() != null && task.getDueDate().length() >= 10) {
            return Optional.of(task.getDueDate().substring(0, 10));
        }
        return Timestamps.localDay(task.getCreatedAt(), zone).map(LocalDate::toString);
    }

    /** Reminders: the due date, else the day of remindAt. Both are wall-clock values. */
    private static Optional<String> reminderDay(ReminderModel reminder) {
        if (reminder.getDueDate() != null && reminder.getDueDate().length() >= 10) {
            return Optional.of(reminder.getDueDate().substring(0, 10));
        }
        if (reminder.getRemindAt() != null && reminder.getRemindAt().length() >= 10) {
            return Optional.of(reminder.getRemindAt().substring(0, 10));
        }
        return Optional.empty();
    }

    private static void requireDate(String date) {
        if (date == null || !date.matches("\\d{4}-\\d{2}-\\d{2}")) {
            throw new BadRequestException("Date must be in YYYY-MM-DD format");
        }
    }

    private static void count(Map<String, Integer> counts, String day) {
        counts.merge(day, 1, Integer::sum);
    }

    /**
     * Item counts per day of a month. Timestamps are bucketed by their day in
     * {@code tz} (an IANA zone name; UTC when absent), see {@link Timestamps}.
     */
    @Transactional
    public ResponseEntity<ApiResponse<CalendarSummaryResponseDto>> getCalendarSummary(long userId, int year, int month, String tz) {
        if (month < 1 || month > 12) {
            throw new BadRequestException("Month must be between 1 and 12");
        }
        ZoneId zone = Timestamps.zone(tz);
        UserModel user = requireUser(userId);
        String prefix = String.format("%04d-%02d", year, month);

        Map<String, Integer> totalCounts = new HashMap<>();
        Map<String, Integer> noteCounts = new HashMap<>();
        Map<String, Integer> taskCounts = new HashMap<>();
        Map<String, Integer> reminderCounts = new HashMap<>();

        int noteTotal = 0;
        List<NotesModel> notes = user.getArticles();
        if (notes != null) {
            for (NotesModel note : notes) {
                Optional<String> day = noteDay(note, zone).filter(d -> d.startsWith(prefix));
                if (day.isPresent()) {
                    count(noteCounts, day.get());
                    count(totalCounts, day.get());
                    noteTotal++;
                }
            }
        }

        int taskTotal = 0;
        for (TaskModel task : taskRepository.findDueInPeriodOrUndated(userId, prefix)) {
            Optional<String> day = taskDay(task, zone).filter(d -> d.startsWith(prefix));
            if (day.isPresent()) {
                count(taskCounts, day.get());
                count(totalCounts, day.get());
                taskTotal++;
            }
        }

        int reminderTotal = 0;
        for (ReminderModel reminder : reminderRepository.findByUserIdAndMonth(userId, prefix)) {
            Optional<String> day = reminderDay(reminder).filter(d -> d.startsWith(prefix));
            if (day.isPresent()) {
                count(reminderCounts, day.get());
                count(totalCounts, day.get());
                reminderTotal++;
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

    /** Notes created on {@code date} in {@code tz} (UTC when absent). */
    @Transactional
    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotesByDate(long userId, String date, String tz) {
        requireDate(date);
        ZoneId zone = Timestamps.zone(tz);
        requireUser(userId);
        List<NotesModel> matchingNotes = notesOn(userId, date, zone);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Fetched notes for date " + date, matchingNotes));
    }

    private List<NotesModel> notesOn(long userId, String date, ZoneId zone) {
        return notesRepository.findByUser_IdOrderByIsPinnedDescCreatedAtDesc(userId).stream()
                .filter(note -> noteDay(note, zone).filter(date::equals).isPresent())
                .toList();
    }

    /** Everything on {@code date}, bucketed like {@link #getCalendarSummary}. */
    @Transactional
    public ResponseEntity<ApiResponse<DayActivityResponseDto>> getDayActivity(long userId, String date, String tz) {
        requireDate(date);
        ZoneId zone = Timestamps.zone(tz);
        requireUser(userId);
        // Same bucketing rules as getCalendarSummary so day totals match the badges.
        List<NotesModel> notes = notesOn(userId, date, zone);
        List<TaskModel> tasks = taskRepository.findDueInPeriodOrUndated(userId, date).stream()
                .filter(task -> taskDay(task, zone).filter(date::equals).isPresent())
                .toList();
        List<ReminderModel> reminders = reminderRepository.findByUserIdAndMonth(userId, date).stream()
                .filter(reminder -> reminderDay(reminder).filter(date::equals).isPresent())
                .toList();

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
                Timestamps.now(),
                userId,
                notes.size(),
                notes
        );
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Notes exported successfully", dto));
    }
}
