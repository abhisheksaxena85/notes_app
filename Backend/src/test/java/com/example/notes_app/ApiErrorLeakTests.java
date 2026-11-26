package com.example.notes_app;

import com.example.notes_app.notes.repository.NotesRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.dao.InvalidDataAccessResourceUsageException;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** BE-03: database and driver errors never reach the client. */
@SpringBootTest
@AutoConfigureMockMvc
public class ApiErrorLeakTests {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private NotesRepository notesRepository;

    @Test
    public void forcedDbErrorReturnsGeneric500() throws Exception {
        when(notesRepository.findById(anyLong())).thenThrow(new InvalidDataAccessResourceUsageException(
                "could not execute statement [SELECT secret_column FROM notes_table]"));

        mockMvc.perform(get("/notes/get-details-by-noteId").param("id", "1"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Something went wrong"))
                .andExpect(content().string(not(containsString("SELECT"))))
                .andExpect(content().string(not(containsString("notes_table"))));
    }

    @Test
    public void constraintViolationReturns409WithoutConstraintName() throws Exception {
        when(notesRepository.findById(anyLong())).thenThrow(new DataIntegrityViolationException(
                "Duplicate entry 'x' for key 'users.UK_secret_constraint'"));

        mockMvc.perform(get("/notes/get-details-by-noteId").param("id", "1"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(content().string(not(containsString("UK_secret_constraint"))));
    }
}
