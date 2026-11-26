package com.example.notes_app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** BE-03: failures use real HTTP status codes and keep the ApiResponse envelope. */
@SpringBootTest
@AutoConfigureMockMvc
public class ApiErrorHandlingTests {

    @Autowired
    private MockMvc mockMvc;

    private static String uniqueEmail() {
        return "errors_" + UUID.randomUUID() + "@example.com";
    }

    private void signUp(String email, String password) throws Exception {
        mockMvc.perform(post("/auth/create-user")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Err\",\"email\":\"" + email + "\",\"password\":\"" + password
                                + "\",\"mobile\":\"123\",\"gender\":\"other\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    public void missingNoteReturns404WithEnvelope() throws Exception {
        mockMvc.perform(get("/notes/get-details-by-noteId").param("id", "987654321"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Note not found"));
    }

    @Test
    public void missingTaskAndReminderReturn404() throws Exception {
        mockMvc.perform(get("/tasks/get-task-details").param("id", "987654321"))
                .andExpect(status().isNotFound());
        mockMvc.perform(delete("/reminders/delete-reminder").param("reminderId", "987654321"))
                .andExpect(status().isNotFound());
    }

    @Test
    public void missingRequiredParamReturns400() throws Exception {
        mockMvc.perform(get("/notes/get-details-by-noteId"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Missing required parameter 'id'"));
    }

    @Test
    public void deleteWithoutIdReturns400InsteadOfDefaultingToZero() throws Exception {
        mockMvc.perform(delete("/notes/delete-note"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Note id is required"));
        mockMvc.perform(delete("/tasks/delete-task"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(delete("/reminders/delete-reminder"))
                .andExpect(status().isBadRequest());
    }

    @Test
    public void typeMismatchReturns400() throws Exception {
        mockMvc.perform(get("/notes/get-details-by-noteId").param("id", "abc"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    public void malformedJsonReturns400() throws Exception {
        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{not json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Malformed or missing request body"));
    }

    @Test
    public void duplicateSignupReturns409() throws Exception {
        String email = uniqueEmail();
        signUp(email, "Password123");
        mockMvc.perform(post("/auth/create-user")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Err\",\"email\":\"" + email + "\",\"password\":\"Password123\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Email id already used by another user"));
    }

    @Test
    public void wrongPasswordReturns401() throws Exception {
        String email = uniqueEmail();
        signUp(email, "Password123");
        mockMvc.perform(post("/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"WrongPass999\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    public void unknownRouteReturns404NotGeneric500() throws Exception {
        mockMvc.perform(get("/notes/does-not-exist"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }
}
