package com.example.notes_app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * The Flutter client sends no credentials, so task/reminder routes must be
 * reachable the same way /notes/** is; otherwise offline-queued items never sync.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class SecurityAccessTests {

    @Autowired
    private MockMvc mockMvc;

    @Test
    public void taskAndReminderRoutesAreReachableWithoutCredentials() throws Exception {
        mockMvc.perform(get("/tasks/get-all-tasks").param("userId", "1"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/reminders/get-all-reminders").param("userId", "1"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/notes/day-activity").param("userId", "1").param("date", "2026-01-01"))
                .andExpect(status().isOk());
    }
}
