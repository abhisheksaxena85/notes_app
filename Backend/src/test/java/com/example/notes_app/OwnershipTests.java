package com.example.notes_app;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * SEC-01: with a token, a user only reaches their own data. Alice creates,
 * Bob (with his own valid token) tries to read, change or delete it and gets
 * 404, and Alice's data is unchanged. Runs with the default AUTH_ENFORCED=false,
 * so it also proves a token is honoured during the rollout.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class OwnershipTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JsonMapper jsonMapper;

    private TestUsers.User alice;
    private TestUsers.User bob;

    @BeforeEach
    void setUp() throws Exception {
        alice = TestUsers.signUp(mockMvc, jsonMapper);
        bob = TestUsers.signUp(mockMvc, jsonMapper);
    }

    private long createAs(TestUsers.User user, MockHttpServletRequestBuilder request, String body, String idField)
            throws Exception {
        String response = mockMvc.perform(user.auth(TestUsers.json(request, body)))
                .andExpect(status().is2xxSuccessful())
                .andReturn().getResponse().getContentAsString();
        return jsonMapper.readTree(response).get("data").get(idField).asLong();
    }

    private void expectNotFoundForBob(List<MockHttpServletRequestBuilder> requests) throws Exception {
        for (MockHttpServletRequestBuilder request : requests) {
            mockMvc.perform(bob.auth(request))
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("$.success").value(false));
        }
    }

    @Test
    public void notesOfAnotherUserAre404() throws Exception {
        long noteId = createAs(alice, post("/notes/create-note"), "{\"title\":\"Alice's note\",\"content\":\"secret\"}", "noteId");
        String id = Long.toString(noteId);

        expectNotFoundForBob(List.of(
                get("/notes/get-details-by-noteId").param("id", id),
                TestUsers.json(put("/notes/update-note"), "{\"noteId\":" + id + ",\"title\":\"hacked\"}"),
                put("/notes/toggle-pin").param("id", id),
                delete("/notes/delete-note").param("id", id)));

        mockMvc.perform(alice.auth(get("/notes/get-details-by-noteId").param("id", id)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Alice's note"))
                .andExpect(jsonPath("$.data.pinned").value(false));
    }

    @Test
    public void tasksOfAnotherUserAre404() throws Exception {
        long taskId = createAs(alice, post("/tasks/create-task"), "{\"title\":\"Alice's task\"}", "taskId");
        String id = Long.toString(taskId);

        expectNotFoundForBob(List.of(
                get("/tasks/get-task-details").param("id", id),
                TestUsers.json(put("/tasks/update-task"), "{\"taskId\":" + id + ",\"title\":\"hacked\"}"),
                put("/tasks/toggle-status").param("taskId", id).param("status", "COMPLETED"),
                delete("/tasks/delete-task").param("id", id)));

        mockMvc.perform(alice.auth(get("/tasks/get-task-details").param("id", id)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.title").value("Alice's task"))
                .andExpect(jsonPath("$.data.status").value("PENDING"));
    }

    @Test
    public void remindersOfAnotherUserAre404() throws Exception {
        long reminderId = createAs(alice, post("/reminders/create-reminder"),
                "{\"title\":\"Alice's reminder\",\"remindAt\":\"2030-01-01T09:00:00\"}", "reminderId");
        String id = Long.toString(reminderId);

        expectNotFoundForBob(List.of(
                TestUsers.json(put("/reminders/update-reminder"), "{\"reminderId\":" + id + ",\"title\":\"hacked\"}"),
                put("/reminders/update-status").param("reminderId", id).param("status", "COMPLETED"),
                TestUsers.json(put("/reminders/complete-occurrence"),
                        "{\"reminderId\":" + id + ",\"occurrence\":\"2030-01-01T09:00:00\",\"outcome\":\"COMPLETED\"}"),
                delete("/reminders/delete-reminder").param("id", id)));

        mockMvc.perform(alice.auth(get("/reminders/get-all-reminders")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].reminderId").value(reminderId))
                .andExpect(jsonPath("$.data[0].title").value("Alice's reminder"))
                .andExpect(jsonPath("$.data[0].status").value("PENDING"));
    }

    @Test
    public void listsAndCreatesForAnotherUserIdAre404() throws Exception {
        String aliceId = Long.toString(alice.id());
        expectNotFoundForBob(List.of(
                get("/notes/get-all-notes").param("id", aliceId),
                get("/notes/calendar-summary").param("userId", aliceId).param("year", "2030").param("month", "1"),
                get("/notes/get-notes-by-date").param("userId", aliceId).param("date", "2030-01-01"),
                get("/notes/day-activity").param("userId", aliceId).param("date", "2030-01-01"),
                get("/notes/search").param("userId", aliceId).param("query", "a"),
                get("/notes/export").param("userId", aliceId),
                TestUsers.json(post("/notes/create-note"), "{\"userId\":" + aliceId + ",\"title\":\"planted\"}"),
                get("/tasks/get-all-tasks").param("userId", aliceId),
                get("/tasks/get-tasks-by-date").param("userId", aliceId).param("date", "2030-01-01"),
                TestUsers.json(post("/tasks/create-task"), "{\"userId\":" + aliceId + ",\"title\":\"planted\"}"),
                get("/reminders/get-all-reminders").param("userId", aliceId),
                get("/reminders/get-by-date").param("userId", aliceId).param("date", "2030-01-01"),
                TestUsers.json(post("/reminders/create-reminder"),
                        "{\"userId\":" + aliceId + ",\"title\":\"planted\",\"remindAt\":\"2030-01-01T09:00:00\"}")));

        mockMvc.perform(alice.auth(get("/notes/get-all-notes"))).andExpect(jsonPath("$.data.length()").value(0));
        mockMvc.perform(alice.auth(get("/tasks/get-all-tasks"))).andExpect(jsonPath("$.data.length()").value(0));
        mockMvc.perform(alice.auth(get("/reminders/get-all-reminders"))).andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    public void profileOfAnotherUserIs404() throws Exception {
        String aliceId = Long.toString(alice.id());
        expectNotFoundForBob(List.of(
                get("/auth/user-details-by-userid").param("id", aliceId),
                TestUsers.json(put("/auth/update-user"), "{\"userId\":" + aliceId + ",\"name\":\"hacked\"}"),
                TestUsers.json(put("/auth/change-password"),
                        "{\"userId\":" + aliceId + ",\"oldPassword\":\"CorrectHorse1\",\"newPassword\":\"Hacked12345\"}"),
                delete("/auth/delete-user").param("id", aliceId)));

        mockMvc.perform(alice.auth(get("/auth/user-details-by-userid")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Sec"));
    }

    @Test
    public void deleteUserWithATokenOnlyDeletesTheCaller() throws Exception {
        mockMvc.perform(bob.auth(delete("/auth/delete-user"))).andExpect(status().isOk());
        mockMvc.perform(alice.auth(get("/auth/user-details-by-userid"))).andExpect(status().isOk());
        mockMvc.perform(bob.auth(get("/auth/user-details-by-userid"))).andExpect(status().isNotFound());
    }
}
