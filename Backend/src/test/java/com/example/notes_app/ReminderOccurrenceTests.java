package com.example.notes_app;

import com.example.notes_app.auth.dto.request.SignupRequestDto;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.common.ItemStatus;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.reminders.model.ReminderOutcome;
import com.example.notes_app.reminders.repository.ReminderRepository;
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

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** REM-07: startAt, complete-occurrence (idempotent by occurrence) and re-anchoring on edit. */
@SpringBootTest
@AutoConfigureMockMvc
public class ReminderOccurrenceTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JsonMapper jsonMapper;

    @Autowired
    private AuthService authService;

    @Autowired
    private ReminderRepository reminderRepository;

    private long userId;

    @BeforeEach
    void setUp() {
        SignupRequestDto signup = new SignupRequestDto();
        signup.setName("Occurrence");
        signup.setEmail("occurrence_" + UUID.randomUUID() + "@example.com");
        signup.setPassword("SecurePass123!");
        userId = authService.createNewUser(signup).getBody().getData().getUserId();
    }

    private JsonNode send(org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder request,
                          Object body, ResultMatcher expected) throws Exception {
        String response = mockMvc.perform(request.contentType(MediaType.APPLICATION_JSON)
                        .content(jsonMapper.writeValueAsString(body)))
                .andExpect(expected).andReturn().getResponse().getContentAsString();
        return jsonMapper.readTree(response);
    }

    private long create(String remindAt, String interval, String clientId) throws Exception {
        Map<String, Object> body = new HashMap<>(Map.of(
                "userId", userId, "title", "Water plants", "remindAt", remindAt, "repeatInterval", interval));
        if (clientId != null) body.put("clientId", clientId);
        return send(post("/reminders/create-reminder"), body, status().is2xxSuccessful())
                .get("data").get("reminderId").asLong();
    }

    private JsonNode complete(long id, String occurrence, String outcome) throws Exception {
        return send(put("/reminders/complete-occurrence"),
                Map.of("reminderId", id, "occurrence", occurrence, "outcome", outcome), status().isOk()).get("data");
    }

    private ReminderModel stored(long id) {
        return reminderRepository.findById(id).orElseThrow();
    }

    @Test
    public void createDefaultsStartAtToRemindAt() throws Exception {
        long id = create("2099-01-31T09:00:00", "MONTHLY", null);
        assertEquals("2099-01-31T09:00:00", stored(id).getStartAt());
        assertNull(stored(id).getLastOutcome());
    }

    @Test
    public void oneOffOccurrenceSetsTheStatus() throws Exception {
        long done = create("2099-01-01T09:00:00", "NONE", null);
        JsonNode body = complete(done, "2099-01-01T09:00:00", "COMPLETED");
        assertEquals("COMPLETED", body.get("status").asString());
        assertEquals(ItemStatus.COMPLETED, stored(done).getStatus());

        long notDone = create("2099-01-01T09:00:00", "NONE", null);
        complete(notDone, "2099-01-01T09:00", "MISSED");
        assertEquals(ItemStatus.MISSED, stored(notDone).getStatus());
        assertEquals(ReminderOutcome.MISSED, stored(notDone).getLastOutcome());
    }

    @Test
    public void repeatingOccurrenceAdvancesOnceAndIsIdempotent() throws Exception {
        long id = create("2099-01-01T08:00:00", "DAILY", null);

        JsonNode first = complete(id, "2099-01-01T08:00:00", "COMPLETED");
        assertEquals("2099-01-02T08:00:00", first.get("remindAt").asString());
        assertEquals("PENDING", first.get("status").asString());
        assertEquals("COMPLETED", first.get("lastOutcome").asString());
        assertEquals("2099-01-01T08:00:00", first.get("lastOutcomeAt").asString());

        // The same answer again (retry, second device): nothing changes.
        JsonNode second = complete(id, "2099-01-01T08:00:00", "COMPLETED");
        assertEquals("2099-01-02T08:00:00", second.get("remindAt").asString());

        ReminderModel reminder = stored(id);
        assertEquals("2099-01-02T08:00:00", reminder.getRemindAt());
        assertEquals("2099-01-02", reminder.getDueDate());
        assertEquals("08:00", reminder.getDueTime());
        assertEquals(ItemStatus.PENDING, reminder.getStatus());
        assertEquals("2099-01-01T08:00:00", reminder.getStartAt(), "the anchor never moves");
    }

    @Test
    public void notDoneOnARepeatingReminderAlsoAdvances() throws Exception {
        long id = create("2099-01-01T08:00:00", "WEEKLY", null);
        complete(id, "2099-01-01T08:00:00", "MISSED");
        ReminderModel reminder = stored(id);
        assertEquals("2099-01-08T08:00:00", reminder.getRemindAt());
        assertEquals(ItemStatus.PENDING, reminder.getStatus());
        assertEquals(ReminderOutcome.MISSED, reminder.getLastOutcome());
    }

    @Test
    public void monthlyKeepsTheAnchorDayAcrossShortMonths() throws Exception {
        long id = create("2099-01-31T09:00:00", "MONTHLY", null);
        assertEquals("2099-02-28T09:00:00", complete(id, "2099-01-31T09:00:00", "COMPLETED").get("remindAt").asString());
        assertEquals("2099-03-31T09:00:00", complete(id, "2099-02-28T09:00:00", "COMPLETED").get("remindAt").asString());
    }

    @Test
    public void invalidOccurrenceRequestsAre400() throws Exception {
        long id = create("2099-01-01T08:00:00", "DAILY", null);
        send(put("/reminders/complete-occurrence"),
                Map.of("reminderId", id, "occurrence", "2099-01-01T08:00:00", "outcome", "DONE"),
                status().isBadRequest());
        send(put("/reminders/complete-occurrence"),
                Map.of("reminderId", id, "occurrence", "yesterday", "outcome", "COMPLETED"),
                status().isBadRequest());
        send(put("/reminders/complete-occurrence"), Map.of("reminderId", id, "outcome", "COMPLETED"),
                status().isBadRequest());
        send(put("/reminders/complete-occurrence"),
                Map.of("reminderId", 987654321L, "occurrence", "2099-01-01T08:00:00", "outcome", "COMPLETED"),
                status().isNotFound());
        assertEquals("2099-01-01T08:00:00", stored(id).getRemindAt());
    }

    @Test
    public void duplicateCreateWithTheSameClientIdReturnsTheSameReminder() throws Exception {
        String clientId = UUID.randomUUID().toString();
        long first = create("2099-01-01T08:00:00", "DAILY", clientId);
        long second = create("2099-01-01T08:00:00", "DAILY", clientId);
        assertEquals(first, second);
        assertEquals(1, reminderRepository.findByUserId(userId).size());
    }

    @Test
    public void movingRemindAtWithoutStartAtReAnchorsTheSeries() throws Exception {
        long id = create("2099-01-31T09:00:00", "MONTHLY", null);
        send(put("/reminders/update-reminder"), Map.of("reminderId", id, "remindAt", "2099-02-10T07:00:00"),
                status().isOk());
        assertEquals("2099-02-10T07:00:00", stored(id).getStartAt());
    }

    @Test
    public void movingRemindAtWithAnExplicitStartAtKeepsIt() throws Exception {
        long id = create("2099-01-31T09:00:00", "MONTHLY", null);
        // The app's catch-up: next occurrence, same anchor, last one missed.
        send(put("/reminders/update-reminder"), Map.of(
                        "reminderId", id,
                        "remindAt", "2099-02-28T09:00:00",
                        "startAt", "2099-01-31T09:00:00",
                        "lastOutcome", "MISSED",
                        "lastOutcomeAt", "2099-01-31T09:00:00"),
                status().isOk());
        ReminderModel reminder = stored(id);
        assertEquals("2099-01-31T09:00:00", reminder.getStartAt());
        assertEquals(ReminderOutcome.MISSED, reminder.getLastOutcome());
        assertEquals("2099-03-31T09:00:00",
                complete(id, "2099-02-28T09:00:00", "COMPLETED").get("remindAt").asString());
    }

    @Test
    public void oldClientsWithoutTheNewFieldsStillWork() throws Exception {
        // The pre-REM-07 app sends no startAt, and updates status via update-status.
        long id = create("2099-01-01T08:00:00", "NONE", null);
        mockMvc.perform(put("/reminders/update-status").param("reminderId", String.valueOf(id))
                        .param("status", "COMPLETED"))
                .andExpect(status().isOk());
        send(put("/reminders/update-reminder"), Map.of("reminderId", id, "title", "Renamed"), status().isOk());
        ReminderModel reminder = stored(id);
        assertEquals("Renamed", reminder.getTitle());
        assertEquals(ItemStatus.COMPLETED, reminder.getStatus());
        assertEquals("2099-01-01T08:00:00", reminder.getStartAt());
    }
}
