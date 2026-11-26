package com.example.notes_app.notes.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
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


    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> getNoteDetails(long noteId){
        ApiResponse<NotesModel> response;
        try{
            NotesModel currentNote = notesRepository.findById(noteId).orElse(null);
            if(currentNote==null){
                throw new Exception("Invalid id, not found in database");
            }
            response = new ApiResponse<>(true, "Successfully fetched the details", currentNote);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotes(long id){
        ApiResponse<List<NotesModel>> response;
        try{
            UserModel user = authRepository.findById(id).orElse(null);
            if(user == null) {  
                throw new Exception("User not found");
            }
            response = new ApiResponse<>(true, "Successfully fetched notes", user.getArticles());
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, "Failed to fetch user notes "+e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<CreateNoteResponseDto>> createNote(CreateNoteRequestDto requestDto){
        ApiResponse<CreateNoteResponseDto> response;
        try{
            UserModel user = authRepository.findById(requestDto.getUserId()).orElse(null);
            if(user == null) {
                throw new Exception("User not found");
            }
            NotesModel newNote = new NotesModel();
            newNote.setTitle(requestDto.getTitle());
            newNote.setContent(requestDto.getContent());
            newNote.setCategory(requestDto.getCategory());
            newNote.setPinned(requestDto.isPinned());
            newNote.setTags(requestDto.getTags());
            newNote.setUser(user);
            newNote.setCreatedAt(LocalDateTime.now().toString());
            newNote.setUpdatedAt(LocalDateTime.now().toString());


            NotesModel savedEntity = notesRepository.save(newNote);

            CreateNoteResponseDto responseDto = new CreateNoteResponseDto();
            responseDto.setNoteId(savedEntity.getNoteId());

            response = new ApiResponse<>(true, "Note saved successfully!", responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, "Failed to save note! "+e.getMessage(), null);
            return  ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<UpdateNoteResponseDto>> updateNote(UpdateNoteRequestDto requestDto){
        ApiResponse<UpdateNoteResponseDto> response;
        try{
            NotesModel currentNote = notesRepository.findById(requestDto.getNoteId()).orElse(null);
            if(currentNote==null){
                throw new Exception("Note does not exists!");
            }
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

            response = new ApiResponse<>(true, "Successfully updated note!", responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch(Exception e){
            response = new ApiResponse<>(false, "Failed to update note! "+e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> deleteNote(long id){
        ApiResponse<NotesModel> response;
        try{
            NotesModel currentNote = notesRepository.findById(id).orElse(null);
            if(currentNote==null){
                throw new Exception("Note does not exists!");
            }
            notesRepository.deleteById(id);
            response = new ApiResponse<>(true, "Successfully deleted note", currentNote);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        } catch (Exception e) {
            response = new ApiResponse<>(false, "Failed to delete note "+e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> togglePin(long noteId) {
        ApiResponse<NotesModel> response;
        try {
            NotesModel currentNote = notesRepository.findById(noteId).orElse(null);
            if (currentNote == null) {
                throw new Exception("Note does not exist!");
            }
            currentNote.setPinned(!currentNote.isPinned());
            currentNote.setUpdatedAt(LocalDateTime.now().toString());
            notesRepository.save(currentNote);
            response = new ApiResponse<>(true, "Pin status updated successfully!", currentNote);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        } catch (Exception e) {
            response = new ApiResponse<>(false, "Failed to toggle pin: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<CalendarSummaryResponseDto>> getCalendarSummary(long userId, int year, int month) {
        ApiResponse<CalendarSummaryResponseDto> response;
        try {
            UserModel user = authRepository.findById(userId).orElse(null);
            if (user == null) {
                throw new Exception("User not found");
            }
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
            response = new ApiResponse<>(true, "Calendar summary generated", dto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        } catch (Exception e) {
            response = new ApiResponse<>(false, "Failed to get calendar summary: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotesByDate(long userId, String date) {
        ApiResponse<List<NotesModel>> response;
        try {
            UserModel user = authRepository.findById(userId).orElse(null);
            if (user == null) {
                throw new Exception("User not found");
            }
            List<NotesModel> matchingNotes = notesRepository.findByUserIdAndDatePrefix(userId, date);
            response = new ApiResponse<>(true, "Fetched notes for date " + date, matchingNotes);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        } catch (Exception e) {
            response = new ApiResponse<>(false, "Failed to fetch notes for date: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<DayActivityResponseDto>> getDayActivity(long userId, String date) {
        ApiResponse<DayActivityResponseDto> response;
        try {
            if (date == null || !date.matches("\\d{4}-\\d{2}-\\d{2}")) {
                throw new Exception("Date must be in YYYY-MM-DD format");
            }
            UserModel user = authRepository.findById(userId).orElse(null);
            if (user == null) {
                throw new Exception("User not found");
            }
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
            response = new ApiResponse<>(true, "Fetched activity for date " + date, dto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        } catch (Exception e) {
            response = new ApiResponse<>(false, "Failed to fetch day activity: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<List<NotesModel>>> searchNotes(long userId, String query) {
        ApiResponse<List<NotesModel>> response;
        try {
            List<NotesModel> results = notesRepository.searchNotes(userId, query);
            response = new ApiResponse<>(true, "Search completed", results);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        } catch (Exception e) {
            response = new ApiResponse<>(false, "Search failed: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<ExportNotesResponseDto>> exportNotes(long userId) {
        ApiResponse<ExportNotesResponseDto> response;
        try {
            UserModel user = authRepository.findById(userId).orElse(null);
            if (user == null) {
                throw new Exception("User not found");
            }
            List<NotesModel> notes = user.getArticles();
            ExportNotesResponseDto dto = new ExportNotesResponseDto(
                    1,
                    LocalDateTime.now().toString(),
                    userId,
                    notes.size(),
                    notes
            );
            response = new ApiResponse<>(true, "Notes exported successfully", dto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        } catch (Exception e) {
            response = new ApiResponse<>(false, "Failed to export notes: " + e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }
}
