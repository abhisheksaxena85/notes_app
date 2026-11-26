package com.example.notes_app;

import com.example.notes_app.auth.dto.request.SignupRequestDto;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.notes.dto.request.CreateNoteRequestDto;
import com.example.notes_app.notes.dto.request.UpdateNoteRequestDto;
import com.example.notes_app.notes.model.NoteLimits;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.service.NotesService;
import jakarta.persistence.Column;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.json.JsonMapper;

import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** BE-01: notes longer than 255 characters save; oversized input gets a clear 400. */
@SpringBootTest
@AutoConfigureMockMvc
public class NoteContentLengthTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private AuthService authService;

    @Autowired
    private NotesService notesService;

    @Autowired
    private JsonMapper jsonMapper;

    private long userId;

    @BeforeEach
    void createUser() {
        SignupRequestDto signup = new SignupRequestDto();
        signup.setName("Long Notes");
        signup.setEmail("long_" + UUID.randomUUID() + "@example.com");
        signup.setPassword("SecurePass123!");
        userId = authService.createNewUser(signup).getBody().getData().getUserId();
    }

    @Test
    public void entityColumnsAreWideEnough() throws Exception {
        Column title = NotesModel.class.getDeclaredField("title").getAnnotation(Column.class);
        Column content = NotesModel.class.getDeclaredField("content").getAnnotation(Column.class);
        assertEquals(NoteLimits.TITLE_MAX, title.length());
        assertEquals("LONGTEXT", content.columnDefinition());
    }

    @Test
    public void createAndUpdateNoteWithTenThousandCharacters() {
        String longContent = "x".repeat(10_000);
        String longTitle = "t".repeat(NoteLimits.TITLE_MAX);

        CreateNoteRequestDto create = new CreateNoteRequestDto();
        create.setUserId(userId);
        create.setTitle(longTitle);
        create.setContent(longContent);
        long noteId = notesService.createNote(create).getBody().getData().getNoteId();

        NotesModel saved = notesService.getNoteDetails(noteId).getBody().getData();
        assertEquals(10_000, saved.getContent().length());
        assertEquals(NoteLimits.TITLE_MAX, saved.getTitle().length());

        UpdateNoteRequestDto update = new UpdateNoteRequestDto();
        update.setNoteId(noteId);
        update.setTitle("Updated");
        update.setContent("y".repeat(20_000));
        assertTrue(notesService.updateNote(update).getBody().isSuccess());
        assertEquals(20_000, notesService.getNoteDetails(noteId).getBody().getData().getContent().length());
    }

    @Test
    public void longNoteOverHttpIsAccepted() throws Exception {
        String body = jsonMapper.writeValueAsString(Map.of(
                "userId", userId, "title", "Long", "content", "z".repeat(10_000)));
        mockMvc.perform(post("/notes/create-note").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    public void oversizedContentIsRejectedWith400() throws Exception {
        String body = jsonMapper.writeValueAsString(Map.of(
                "userId", userId, "title", "Too long", "content", "z".repeat(NoteLimits.CONTENT_MAX + 1)));
        mockMvc.perform(post("/notes/create-note").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Content must be at most " + NoteLimits.CONTENT_MAX + " characters"));
    }

    @Test
    public void oversizedTitleOnUpdateIsRejectedWith400() throws Exception {
        String body = jsonMapper.writeValueAsString(Map.of(
                "noteId", 1, "title", "t".repeat(NoteLimits.TITLE_MAX + 1), "content", "c"));
        mockMvc.perform(put("/notes/update-note").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Title must be at most " + NoteLimits.TITLE_MAX + " characters"));
    }
}
