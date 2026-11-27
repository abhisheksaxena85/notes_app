package com.example.notes_app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.oauth2.jwt.JwtEncoder;
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

/** SEC-01 with {@code AUTH_ENFORCED=true}: every data route needs a valid token. */
@SpringBootTest(properties = "app.auth.enforced=true")
@AutoConfigureMockMvc
public class AuthEnforcedTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JsonMapper jsonMapper;

    @Autowired
    private JwtEncoder jwtEncoder;

    private static List<MockHttpServletRequestBuilder> dataRoutes(long userId) {
        String id = Long.toString(userId);
        return List.of(
                get("/notes/get-all-notes").param("id", id),
                get("/notes/get-details-by-noteId").param("id", "1"),
                get("/notes/day-activity").param("userId", id).param("date", "2026-01-01"),
                TestUsers.json(post("/notes/create-note"), "{\"userId\":" + id + ",\"title\":\"t\"}"),
                get("/tasks/get-all-tasks").param("userId", id),
                TestUsers.json(post("/tasks/create-task"), "{\"userId\":" + id + ",\"title\":\"t\"}"),
                get("/reminders/get-all-reminders").param("userId", id),
                put("/reminders/update-status").param("reminderId", "1"),
                get("/auth/user-details-by-userid").param("id", id),
                TestUsers.json(put("/auth/update-user"), "{\"userId\":" + id + ",\"name\":\"x\"}"),
                delete("/auth/delete-user").param("id", id));
    }

    @Test
    public void everyDataRouteIs401WithoutAToken() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        for (MockHttpServletRequestBuilder request : dataRoutes(user.id())) {
            mockMvc.perform(request)
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.success").value(false))
                    .andExpect(jsonPath("$.message").value("Authentication required"));
        }
    }

    @Test
    public void invalidAndExpiredTokensAre401() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        mockMvc.perform(TestUsers.bearer(get("/tasks/get-all-tasks"), "garbage"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(TestUsers.bearer(get("/tasks/get-all-tasks"), TestUsers.expiredToken(jwtEncoder, user.id())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    public void validTokenWorksWithoutAnyUserId() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        mockMvc.perform(user.auth(get("/notes/get-all-notes"))).andExpect(status().isOk());
        mockMvc.perform(user.auth(get("/tasks/get-all-tasks"))).andExpect(status().isOk());
        mockMvc.perform(user.auth(get("/reminders/get-all-reminders"))).andExpect(status().isOk());
        mockMvc.perform(user.auth(get("/auth/user-details-by-userid")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(user.id()));
        mockMvc.perform(user.auth(TestUsers.json(post("/tasks/create-task"), "{\"title\":\"From token\"}")))
                .andExpect(status().isCreated());
    }

    @Test
    public void loginSignupAndDocsStayOpen() throws Exception {
        TestUsers.signUp(mockMvc, jsonMapper);
        mockMvc.perform(TestUsers.json(post("/auth/login"), "{\"email\":\"nobody@example.com\",\"password\":\"x\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
        mockMvc.perform(get("/v3/api-docs")).andExpect(status().isOk());
    }

    @Test
    public void otherUsersDataIs404() throws Exception {
        TestUsers.User alice = TestUsers.signUp(mockMvc, jsonMapper);
        TestUsers.User bob = TestUsers.signUp(mockMvc, jsonMapper);
        long taskId = jsonMapper.readTree(mockMvc.perform(alice.auth(
                        TestUsers.json(post("/tasks/create-task"), "{\"title\":\"Alice's\"}")))
                .andReturn().getResponse().getContentAsString()).get("data").get("taskId").asLong();

        mockMvc.perform(bob.auth(get("/tasks/get-task-details").param("id", Long.toString(taskId))))
                .andExpect(status().isNotFound());
        mockMvc.perform(bob.auth(get("/tasks/get-all-tasks").param("userId", Long.toString(alice.id()))))
                .andExpect(status().isNotFound());
    }
}
