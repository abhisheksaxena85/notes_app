package com.example.notes_app;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.Timestamps;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.notes.dto.request.CreateNoteRequestDto;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.repository.NotesRepository;
import com.example.notes_app.notes.service.NotesService;
import com.example.notes_app.tasks.model.TaskModel;
import com.example.notes_app.tasks.repository.TaskRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * BE-02: timestamps are UTC instants and the date endpoints bucket them by
 * the caller's zone ({@code tz}). Legacy values without an offset are UTC.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TimezoneBucketingTests {

    private static final String KOLKATA = "Asia/Kolkata";

    @Autowired
    private NotesService notesService;
    @Autowired
    private NotesRepository notesRepository;
    @Autowired
    private TaskRepository taskRepository;
    @Autowired
    private AuthRepository authRepository;
    @Autowired
    private MockMvc mockMvc;

    private UserModel user;

    @BeforeEach
    void createUser() {
        UserModel newUser = new UserModel();
        newUser.setName("Zone Tester");
        newUser.setEmail("zone_" + UUID.randomUUID() + "@example.com");
        newUser.setPassword("not-used");
        user = authRepository.save(newUser);

        // 01:30 on Nov 26 in India (20:00 UTC on Nov 25).
        note("late night", "2026-11-25T20:00:00Z");
        // A pre-BE-02 row without an offset: 23:59:59.999 on Nov 25 in India.
        note("legacy", "2026-11-25T18:29:59.999");
        // Midnight Nov 26 in India.
        note("midnight", "2026-11-25T18:30:00.000Z");
        // No due date: bucketed by createdAt, which is Dec 1 in India.
        task(null, "2026-11-30T19:00:00Z");
        // A due date is a wall-clock day and is never converted.
        task("2026-11-26", "2026-11-26T22:00:00Z");
    }

    private void note(String title, String createdAt) {
        NotesModel note = new NotesModel();
        note.setTitle(title);
        note.setContent(title);
        note.setUser(user);
        note.setCreatedAt(createdAt);
        note.setUpdatedAt(createdAt);
        notesRepository.save(note);
    }

    private void task(String dueDate, String createdAt) {
        TaskModel task = new TaskModel();
        task.setTitle("task " + createdAt);
        task.setDueDate(dueDate);
        task.setStatus("PENDING");
        task.setCreatedAt(createdAt);
        task.setUpdatedAt(createdAt);
        task.setUser(user);
        taskRepository.save(task);
    }

    @Test
    void calendarSummaryBucketsByTheCallersZone() {
        var india = notesService.getCalendarSummary(user.getId(), 2026, 11, KOLKATA).getBody().getData();
        assertEquals(Map.of("2026-11-25", 1, "2026-11-26", 2), india.getNoteCountsByDate());
        assertEquals(Map.of("2026-11-26", 1), india.getTaskCountsByDate());
        assertEquals(3, india.getTotalNotes());
        assertEquals(1, india.getTotalTasks());

        var december = notesService.getCalendarSummary(user.getId(), 2026, 12, KOLKATA).getBody().getData();
        assertEquals(Map.of("2026-12-01", 1), december.getTaskCountsByDate());

        // Without tz the server buckets in UTC.
        var utc = notesService.getCalendarSummary(user.getId(), 2026, 11, null).getBody().getData();
        assertEquals(Map.of("2026-11-25", 3), utc.getNoteCountsByDate());
        assertEquals(Map.of("2026-11-26", 1, "2026-11-30", 1), utc.getTaskCountsByDate());
    }

    @Test
    void notesByDateAndDayActivityUseTheSameDays() {
        var notes = notesService.getNotesByDate(user.getId(), "2026-11-26", KOLKATA).getBody().getData();
        assertEquals(2, notes.size());

        var nov25 = notesService.getDayActivity(user.getId(), "2026-11-25", KOLKATA).getBody().getData();
        assertEquals(1, nov25.getNotes().size());
        assertEquals("legacy", nov25.getNotes().get(0).getTitle());
        assertEquals(1, nov25.getTotalCount());

        var dec1 = notesService.getDayActivity(user.getId(), "2026-12-01", KOLKATA).getBody().getData();
        assertEquals(1, dec1.getTasks().size());
        assertEquals(0, dec1.getNotes().size());
    }

    @Test
    void newTimestampsAreUtcInstants() {
        CreateNoteRequestDto request = new CreateNoteRequestDto();
        request.setUserId(user.getId());
        request.setTitle("fresh");
        request.setContent("x");
        long noteId = notesService.createNote(request).getBody().getData().getNoteId();

        NotesModel saved = notesRepository.findById(noteId).orElseThrow();
        assertTrue(saved.getCreatedAt().endsWith("Z"), saved.getCreatedAt());
        assertTrue(Timestamps.parse(saved.getUpdatedAt()).isPresent());
    }

    @Test
    void badDatesAndZonesAreRejected() throws Exception {
        assertThrows(BadRequestException.class,
                () -> notesService.getNotesByDate(user.getId(), "26/11/2026", KOLKATA));
        mockMvc.perform(get("/notes/calendar-summary")
                        .param("userId", String.valueOf(user.getId()))
                        .param("year", "2026").param("month", "11")
                        .param("tz", "Not/AZone"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
        mockMvc.perform(get("/notes/calendar-summary")
                        .param("userId", String.valueOf(user.getId()))
                        .param("year", "2026").param("month", "11")
                        .param("tz", KOLKATA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.noteCountsByDate['2026-11-26']").value(2));
    }
}
