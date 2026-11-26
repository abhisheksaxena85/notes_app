package com.example.notes_app;

import com.example.notes_app.auth.dto.request.SignupRequestDto;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.common.ItemStatus;
import com.example.notes_app.reminders.repository.ReminderRepository;
import com.example.notes_app.tasks.repository.TaskRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * BE-04: reminder sort order, dueDate/dueTime kept in step with remindAt on
 * edit, enum and date validation (400 instead of a 500 or a stored "foo"), and
 * a task's isCompleted always following its status.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class ReminderTaskValidationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JsonMapper jsonMapper;

    @Autowired
    private AuthService authService;

    @Autowired
    private ReminderRepository reminderRepository;

    @Autowired
    private TaskRepository taskRepository;

    private long userId;

    @BeforeEach
    void setUp() {
        SignupRequestDto signup = new SignupRequestDto();
        signup.setName("Validation");
        signup.setEmail("validation_" + UUID.randomUUID() + "@example.com");
        signup.setPassword("SecurePass123!");
        userId = authService.createNewUser(signup).getBody().getData().getUserId();
    }

    private JsonNode send(org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request,
                          Object body, ResultMatcher expected) throws Exception {
        if (body != null) {
            request = request.contentType(MediaType.APPLICATION_JSON).content(jsonMapper.writeValueAsString(body));
        }
        String response = mockMvc.perform(request).andExpect(expected).andReturn().getResponse().getContentAsString();
        return jsonMapper.readTree(response);
    }

    private Map<String, Object> reminder(String title, String remindAt) {
        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("title", title);
        body.put("remindAt", remindAt);
        return body;
    }

    private long createReminder(Map<String, Object> body) throws Exception {
        return send(post("/reminders/create-reminder"), body, status().isCreated())
                .get("data").get("reminderId").asLong();
    }

    private void setReminderStatus(long id, String status) throws Exception {
        send(put("/reminders/update-status").param("reminderId", String.valueOf(id)).param("status", status),
                null, status().isOk());
    }

    @Test
    public void allRemindersListPendingFirst() throws Exception {
        long completedEarly = createReminder(reminder("done", "2099-01-01T08:00:00"));
        long missed = createReminder(reminder("missed", "2099-01-02T08:00:00"));
        long pendingLate = createReminder(reminder("pending late", "2099-01-05T08:00:00"));
        long rejected = createReminder(reminder("rejected", "2099-01-01T07:00:00"));
        long pendingEarly = createReminder(reminder("pending early", "2099-01-03T08:00:00"));
        setReminderStatus(completedEarly, "COMPLETED");
        setReminderStatus(missed, "missed");
        setReminderStatus(rejected, "REJECTED");

        JsonNode data = send(get("/reminders/get-all-reminders").param("userId", String.valueOf(userId)),
                null, status().isOk()).get("data");
        List<Long> ids = new ArrayList<>();
        data.forEach(node -> ids.add(node.get("reminderId").asLong()));
        assertEquals(List.of(pendingEarly, pendingLate, missed, completedEarly, rejected), ids);
    }

    @Test
    public void movingRemindAtToAnotherDayMovesDueDateAndCalendar() throws Exception {
        long id = createReminder(reminder("Dentist", "2099-03-10T09:30:00"));

        send(put("/reminders/update-reminder"),
                Map.of("reminderId", id, "remindAt", "2099-04-02T17:45"), status().isOk());

        var stored = reminderRepository.findById(id).orElseThrow();
        assertEquals("2099-04-02T17:45:00", stored.getRemindAt(), "stored with seconds");
        assertEquals("2099-04-02", stored.getDueDate());
        assertEquals("17:45", stored.getDueTime());

        assertEquals(0, send(get("/reminders/get-by-date").param("userId", String.valueOf(userId))
                .param("date", "2099-03-10"), null, status().isOk()).get("data").size());
        assertEquals(1, send(get("/reminders/get-by-date").param("userId", String.valueOf(userId))
                .param("date", "2099-04-02"), null, status().isOk()).get("data").size());

        JsonNode march = send(get("/notes/calendar-summary").param("userId", String.valueOf(userId))
                .param("year", "2099").param("month", "3"), null, status().isOk()).get("data");
        assertEquals(0, march.get("totalReminders").asInt());
        JsonNode april = send(get("/notes/calendar-summary").param("userId", String.valueOf(userId))
                .param("year", "2099").param("month", "4"), null, status().isOk()).get("data");
        assertEquals(1, april.get("reminderCountsByDate").get("2099-04-02").asInt());
    }

    @Test
    public void explicitDueDateAndTimeStillWin() throws Exception {
        Map<String, Object> body = reminder("Explicit", "2099-05-01T10:00:00");
        body.put("dueDate", "2099-05-02");
        body.put("dueTime", "11:15");
        long id = createReminder(body);
        var stored = reminderRepository.findById(id).orElseThrow();
        assertEquals("2099-05-02", stored.getDueDate());
        assertEquals("11:15", stored.getDueTime());
    }

    @Test
    public void invalidReminderValuesAreRejectedWith400() throws Exception {
        Map<String, Object> badStatus = reminder("x", "2099-01-01T09:00:00");
        badStatus.put("status", "foo");
        String message = send(post("/reminders/create-reminder"), badStatus, status().isBadRequest())
                .get("message").asString();
        assertTrue(message.contains("status must be one of"), message);

        Map<String, Object> badInterval = reminder("x", "2099-01-01T09:00:00");
        badInterval.put("repeatInterval", "HOURLY");
        send(post("/reminders/create-reminder"), badInterval, status().isBadRequest());

        send(post("/reminders/create-reminder"), reminder("x", "2099-13-01T09:00:00"), status().isBadRequest());
        send(post("/reminders/create-reminder"), reminder("x", "tomorrow"), status().isBadRequest());
        send(post("/reminders/create-reminder"), reminder("x", null), status().isBadRequest());
        send(post("/reminders/create-reminder"), reminder(null, "2099-01-01T09:00:00"), status().isBadRequest());
        send(post("/reminders/create-reminder"), reminder("  ", "2099-01-01T09:00:00"), status().isBadRequest());

        Map<String, Object> badDueTime = reminder("x", "2099-01-01T09:00:00");
        badDueTime.put("dueTime", "25:00");
        send(post("/reminders/create-reminder"), badDueTime, status().isBadRequest());

        long id = createReminder(reminder("ok", "2099-01-01T09:00:00"));
        mockMvc.perform(put("/reminders/update-status").param("reminderId", String.valueOf(id)).param("status", "foo"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
        send(put("/reminders/update-reminder"), Map.of("reminderId", id, "status", "done"), status().isBadRequest());
        send(put("/reminders/update-reminder"), Map.of("reminderId", id, "dueDate", "01/02/2099"),
                status().isBadRequest());
        send(put("/reminders/update-reminder"), Map.of("reminderId", id, "title", ""), status().isBadRequest());

        assertEquals(ItemStatus.PENDING, reminderRepository.findById(id).orElseThrow().getStatus(),
                "nothing was stored by the rejected calls");
        assertEquals(1, reminderRepository.findByUserId(userId).size());
    }

    @Test
    public void statusValuesAreCaseInsensitive() throws Exception {
        long id = createReminder(reminder("ok", "2099-01-01T09:00:00"));
        setReminderStatus(id, "completed");
        assertEquals(ItemStatus.COMPLETED, reminderRepository.findById(id).orElseThrow().getStatus());
    }

    private Map<String, Object> task(String title) {
        Map<String, Object> body = new HashMap<>();
        body.put("userId", userId);
        body.put("title", title);
        body.put("isCompleted", false);
        return body;
    }

    private long createTask(Map<String, Object> body) throws Exception {
        return send(post("/tasks/create-task"), body, status().isCreated()).get("data").get("taskId").asLong();
    }

    @Test
    public void invalidTaskValuesAreRejectedWith400() throws Exception {
        Map<String, Object> badPriority = task("x");
        badPriority.put("priority", "URGENT");
        send(post("/tasks/create-task"), badPriority, status().isBadRequest());

        Map<String, Object> badStatus = task("x");
        badStatus.put("status", "DONE");
        send(post("/tasks/create-task"), badStatus, status().isBadRequest());

        Map<String, Object> badDate = task("x");
        badDate.put("dueDate", "2099-02-30");
        send(post("/tasks/create-task"), badDate, status().isBadRequest());

        send(post("/tasks/create-task"), task(null), status().isBadRequest());

        long id = createTask(task("ok"));
        mockMvc.perform(put("/tasks/toggle-status").param("taskId", String.valueOf(id)).param("status", "foo"))
                .andExpect(status().isBadRequest());
        assertEquals(1, taskRepository.findByUserId(userId).size());
    }

    @Test
    public void taskCompletionAlwaysFollowsStatus() throws Exception {
        // Old clients: isCompleted without a status creates a COMPLETED task.
        Map<String, Object> completedByFlag = task("flag");
        completedByFlag.put("isCompleted", true);
        var flagged = taskRepository.findById(createTask(completedByFlag)).orElseThrow();
        assertEquals(ItemStatus.COMPLETED, flagged.getStatus());
        assertTrue(flagged.isCompleted());

        // An explicit status wins over a contradicting flag.
        Map<String, Object> contradicting = task("contradicting");
        contradicting.put("isCompleted", true);
        contradicting.put("status", "PENDING");
        var pending = taskRepository.findById(createTask(contradicting)).orElseThrow();
        assertEquals(ItemStatus.PENDING, pending.getStatus());
        assertFalse(pending.isCompleted());

        long id = createTask(task("edit"));
        send(put("/tasks/update-task"), Map.of("taskId", id, "status", "COMPLETED", "isCompleted", false),
                status().isOk());
        assertTrue(taskRepository.findById(id).orElseThrow().isCompleted());

        // A partial update without a status leaves completion alone.
        send(put("/tasks/update-task"), Map.of("taskId", id, "title", "renamed", "isCompleted", false),
                status().isOk());
        var renamed = taskRepository.findById(id).orElseThrow();
        assertEquals(ItemStatus.COMPLETED, renamed.getStatus());
        assertTrue(renamed.isCompleted());

        send(put("/tasks/update-task"), Map.of("taskId", id, "status", "PENDING", "isCompleted", true),
                status().isOk());
        assertFalse(taskRepository.findById(id).orElseThrow().isCompleted());
    }
}
