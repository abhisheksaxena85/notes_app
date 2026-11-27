package com.example.notes_app;

import com.example.notes_app.auth.dto.request.DeleteUserRequestDto;
import com.example.notes_app.auth.dto.request.UpdateUserRequestDto;
import com.example.notes_app.auth.dto.response.UpdateUserResponseDto;
import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.notes.dto.response.ExportNotesResponseDto;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.repository.NotesRepository;
import com.example.notes_app.notes.service.NotesService;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.tasks.model.TaskModel;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.support.TransactionTemplate;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

/** BE-05: entity toString, ordered notes, and the auth service fixes. */
@SpringBootTest
class EntityAndServiceFixesTests {

    @Autowired
    private AuthService authService;
    @Autowired
    private AuthRepository authRepository;
    @Autowired
    private NotesService notesService;
    @Autowired
    private NotesRepository notesRepository;
    @Autowired
    private TransactionTemplate transactionTemplate;

    private UserModel saveUser() {
        UserModel user = new UserModel();
        user.setName("Entity Tester");
        user.setEmail("be05_" + UUID.randomUUID() + "@example.com");
        user.setPassword("stored-hash");
        user.setMobile("12345");
        user.setGender("Other");
        return authRepository.save(user);
    }

    private NotesModel saveNote(UserModel user, String title, boolean pinned, String createdAt) {
        NotesModel note = new NotesModel();
        note.setTitle(title);
        note.setContent("content");
        note.setPinned(pinned);
        note.setCreatedAt(createdAt);
        note.setUpdatedAt(createdAt);
        note.setUser(user);
        return notesRepository.save(note);
    }

    @Test
    void toStringOnAUserWithChildrenDoesNotRecurse() {
        UserModel user = new UserModel();
        user.setName("Loop");
        user.setPassword("secret-hash");
        NotesModel note = new NotesModel();
        note.setUser(user);
        TaskModel task = new TaskModel();
        task.setUser(user);
        ReminderModel reminder = new ReminderModel();
        reminder.setUser(user);
        user.getArticles().add(note);
        user.getTasks().add(task);
        user.getReminders().add(reminder);

        String text = assertDoesNotThrow(user::toString);
        assertFalse(text.contains("secret-hash"), "password must not be in toString");
        assertDoesNotThrow(note::toString);
        assertDoesNotThrow(task::toString);
        assertDoesNotThrow(reminder::toString);
    }

    @Test
    void toStringOnAPersistedUserDoesNotTouchLazyCollections() {
        UserModel saved = saveUser();
        saveNote(saved, "n", false, "2026-01-01T00:00:00Z");
        transactionTemplate.executeWithoutResult(status -> {
            UserModel loaded = authRepository.findById(saved.getId()).orElseThrow();
            assertDoesNotThrow(loaded::toString);
            assertDoesNotThrow(() -> loaded.getArticles().get(0).toString());
        });
    }

    @Test
    void getNotesAndExportArePinnedFirstThenNewestFirst() {
        UserModel user = saveUser();
        saveNote(user, "old", false, "2026-01-01T00:00:00Z");
        saveNote(user, "pinned-oldest", true, "2025-06-01T00:00:00Z");
        saveNote(user, "new", false, "2026-03-01T00:00:00Z");
        saveNote(user, "pinned-newer", true, "2025-07-01T00:00:00Z");

        List<String> expected = List.of("pinned-newer", "pinned-oldest", "new", "old");
        List<NotesModel> notes = notesService.getNotes(user.getId()).getBody().getData();
        assertEquals(expected, notes.stream().map(NotesModel::getTitle).toList());

        ExportNotesResponseDto export = notesService.exportNotes(user.getId()).getBody().getData();
        assertEquals(expected, export.getNotes().stream().map(NotesModel::getTitle).toList());
    }

    @Test
    void deleteUserThatDoesNotExistIsNotFound() {
        DeleteUserRequestDto request = new DeleteUserRequestDto();
        request.setId(987_654_321L);
        assertThrows(NotFoundException.class, () -> authService.deleteUser(request));
    }

    @Test
    void partialUpdateUserReturnsTheStoredValues() {
        UserModel user = saveUser();
        UpdateUserRequestDto request = new UpdateUserRequestDto();
        request.setUserId(user.getId());
        request.setName("Renamed");

        UpdateUserResponseDto response = authService.updateUser(request).getBody().getData();
        assertEquals(user.getId(), response.getUserId());
        assertEquals("Renamed", response.getName());
        assertEquals("12345", response.getMobile());
        assertEquals("Other", response.getGender());
    }
}
