package com.example.notes_app;

import com.example.notes_app.auth.dto.request.SignupRequestDto;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.common.IdempotentCreate;
import com.example.notes_app.notes.repository.NotesRepository;
import com.example.notes_app.reminders.repository.ReminderRepository;
import com.example.notes_app.tasks.repository.TaskRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * FE-03: a create retried with the same clientId (for example after the first
 * response was lost) returns the existing row instead of inserting a duplicate.
 * Requests without a clientId (old app builds) behave as before.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class ClientIdIdempotencyTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JsonMapper jsonMapper;

    @Autowired
    private AuthService authService;

    @Autowired
    private NotesRepository notesRepository;

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private ReminderRepository reminderRepository;

    private long userId;

    private long newUser() {
        SignupRequestDto signup = new SignupRequestDto();
        signup.setName("Idempotent");
        signup.setEmail("idem_" + UUID.randomUUID() + "@example.com");
        signup.setPassword("SecurePass123!");
        return authService.createNewUser(signup).getBody().getData().getUserId();
    }

    @BeforeEach
    void setUp() {
        userId = newUser();
    }

    private JsonNode create(String path, Map<String, Object> body, ResultMatcher expectedStatus) throws Exception {
        String response = mockMvc.perform(post(path)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonMapper.writeValueAsString(body)))
                .andExpect(expectedStatus)
                .andReturn().getResponse().getContentAsString();
        JsonNode json = jsonMapper.readTree(response);
        assertTrue(json.get("success").asBoolean());
        return json.get("data");
    }

    private Map<String, Object> note(long user, String clientId) {
        Map<String, Object> body = new HashMap<>(Map.of("userId", user, "title", "Note", "content", "Body"));
        if (clientId != null) body.put("clientId", clientId);
        return body;
    }

    private Map<String, Object> task(String clientId) {
        // The app always sends isCompleted; the DTO's primitive field requires it.
        Map<String, Object> body = new HashMap<>(Map.of("userId", userId, "title", "Task", "isCompleted", false));
        if (clientId != null) body.put("clientId", clientId);
        return body;
    }

    private Map<String, Object> reminder(String clientId) {
        Map<String, Object> body = new HashMap<>(Map.of(
                "userId", userId, "title", "Reminder", "remindAt", "2099-01-01T09:00:00"));
        if (clientId != null) body.put("clientId", clientId);
        return body;
    }

    @Test
    public void retriedNoteCreateReturnsTheSameNote() throws Exception {
        String clientId = UUID.randomUUID().toString();
        long first = create("/notes/create-note", note(userId, clientId), status().isOk()).get("noteId").asLong();
        long second = create("/notes/create-note", note(userId, clientId), status().isOk()).get("noteId").asLong();

        assertEquals(first, second);
        assertEquals(1, notesRepository.findByUser_IdOrderByIsPinnedDescCreatedAtDesc(userId).size());
        assertEquals(clientId, notesRepository.findById(first).orElseThrow().getClientId());
    }

    @Test
    public void retriedTaskCreateReturns200WithTheExistingId() throws Exception {
        String clientId = UUID.randomUUID().toString();
        long first = create("/tasks/create-task", task(clientId), status().isCreated()).get("taskId").asLong();
        long second = create("/tasks/create-task", task(clientId), status().isOk()).get("taskId").asLong();

        assertEquals(first, second);
        assertEquals(1, taskRepository.findByUserId(userId).size());
    }

    @Test
    public void retriedReminderCreateReturns200WithTheExistingId() throws Exception {
        String clientId = UUID.randomUUID().toString();
        long first = create("/reminders/create-reminder", reminder(clientId), status().isCreated())
                .get("reminderId").asLong();
        long second = create("/reminders/create-reminder", reminder(clientId), status().isOk())
                .get("reminderId").asLong();

        assertEquals(first, second);
        assertEquals(1, reminderRepository.findByUserId(userId).size());
    }

    @Test
    public void oldClientsWithoutClientIdStillCreateEveryTime() throws Exception {
        create("/notes/create-note", note(userId, null), status().isOk());
        create("/notes/create-note", note(userId, null), status().isOk());
        create("/tasks/create-task", task(null), status().isCreated());
        create("/tasks/create-task", task(null), status().isCreated());
        create("/reminders/create-reminder", reminder(null), status().isCreated());
        create("/reminders/create-reminder", reminder(null), status().isCreated());

        assertEquals(2, notesRepository.findByUser_IdOrderByIsPinnedDescCreatedAtDesc(userId).size());
        assertEquals(2, taskRepository.findByUserId(userId).size());
        assertEquals(2, reminderRepository.findByUserId(userId).size());
    }

    @Test
    public void blankClientIdIsTreatedAsMissing() throws Exception {
        create("/notes/create-note", note(userId, "  "), status().isOk());
        create("/notes/create-note", note(userId, ""), status().isOk());
        assertEquals(2, notesRepository.findByUser_IdOrderByIsPinnedDescCreatedAtDesc(userId).size());
    }

    @Test
    public void theSameClientIdFromAnotherUserIsADifferentNote() throws Exception {
        String clientId = UUID.randomUUID().toString();
        long otherUser = newUser();
        long mine = create("/notes/create-note", note(userId, clientId), status().isOk()).get("noteId").asLong();
        long theirs = create("/notes/create-note", note(otherUser, clientId), status().isOk()).get("noteId").asLong();
        assertNotEquals(mine, theirs);
    }

    @Test
    public void overlongClientIdIsRejected() throws Exception {
        mockMvc.perform(post("/tasks/create-task")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(jsonMapper.writeValueAsString(task("x".repeat(37)))))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void databaseRejectsADuplicateClientIdForTheSameUser() throws Exception {
        String clientId = UUID.randomUUID().toString();
        long noteId = create("/notes/create-note", note(userId, clientId), status().isOk()).get("noteId").asLong();
        var copy = notesRepository.findById(noteId).orElseThrow();
        var duplicate = new com.example.notes_app.notes.model.NotesModel();
        duplicate.setTitle("dup");
        duplicate.setClientId(clientId);
        duplicate.setUser(copy.getUser());
        assertThrows(DataIntegrityViolationException.class, () -> notesRepository.saveAndFlush(duplicate));
    }

    @Test
    public void concurrentDuplicateFallsBackToTheRowTheOtherRequestInserted() {
        AtomicInteger lookups = new AtomicInteger();
        IdempotentCreate.Result<String> result = IdempotentCreate.createOnce(
                "abc",
                // First lookup: not there yet. Second lookup (after the unique-key error): found.
                () -> lookups.incrementAndGet() == 1 ? Optional.empty() : Optional.of("existing"),
                () -> {
                    throw new DataIntegrityViolationException("duplicate key uk_notes_user_client");
                });

        assertEquals("existing", result.entity());
        assertFalse(result.created());
        assertEquals(2, lookups.get());
    }

    @Test
    public void unrelatedIntegrityErrorsAreNotSwallowed() {
        assertThrows(DataIntegrityViolationException.class, () -> IdempotentCreate.createOnce(
                "abc",
                Optional::empty,
                () -> {
                    throw new DataIntegrityViolationException("some other constraint");
                }));
    }
}
