package com.example.notes_app;

import com.example.notes_app.auth.dto.request.LoginRequestDto;
import com.example.notes_app.auth.dto.request.SignupRequestDto;
import com.example.notes_app.auth.dto.request.UpdateUserRequestDto;
import com.example.notes_app.auth.dto.request.UserDetailsRequestDto;
import com.example.notes_app.auth.dto.response.LoginResponseDto;
import com.example.notes_app.auth.dto.response.SignupResponseDto;
import com.example.notes_app.auth.dto.response.UserDetailsResponseDto;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.notes.dto.request.CreateNoteRequestDto;
import com.example.notes_app.notes.dto.request.UpdateNoteRequestDto;
import com.example.notes_app.notes.dto.response.CalendarSummaryResponseDto;
import com.example.notes_app.notes.dto.response.CreateNoteResponseDto;
import com.example.notes_app.notes.dto.response.ExportNotesResponseDto;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.service.NotesService;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class NotesApiTests {

    @Autowired
    private AuthService authService;

    @Autowired
    private NotesService notesService;

    @Autowired
    private com.example.notes_app.tasks.service.TaskService taskService;

    @Autowired
    private com.example.notes_app.reminders.service.ReminderService reminderService;

    @Autowired
    private tools.jackson.databind.json.JsonMapper jsonMapper;

    /** "Today" below is LocalDate.now(), so days are bucketed in this JVM's zone. */
    private static final String ZONE = java.time.ZoneId.systemDefault().getId();

    private static long testUserId;
    private static long testNoteId;
    private static final String testEmail = "daymark_test_" + System.currentTimeMillis() + "@example.com";

    @Test
    @Order(1)
    public void testUserSignupAndLogin() {
        SignupRequestDto signupDto = new SignupRequestDto();
        signupDto.setName("Daymark Engineer");
        signupDto.setEmail(testEmail);
        signupDto.setPassword("SecurePass123!");
        signupDto.setMobile("9876543210");
        signupDto.setGender("Other");

        ResponseEntity<ApiResponse<SignupResponseDto>> signupResp = authService.createNewUser(signupDto);
        assertTrue(signupResp.getBody().isSuccess());
        assertNotNull(signupResp.getBody().getData());
        testUserId = signupResp.getBody().getData().getUserId();
        assertTrue(testUserId > 0);

        LoginRequestDto loginDto = new LoginRequestDto();
        loginDto.setEmail(testEmail);
        loginDto.setPassword("SecurePass123!");

        ResponseEntity<ApiResponse<LoginResponseDto>> loginResp = authService.login(loginDto);
        assertTrue(loginResp.getBody().isSuccess());
        assertEquals(testUserId, loginResp.getBody().getData().getUserId());
    }

    @Test
    @Order(2)
    public void testGetAndUpdateUserDetails() {
        UserDetailsRequestDto userReq = new UserDetailsRequestDto();
        userReq.setId(testUserId);

        ResponseEntity<ApiResponse<UserDetailsResponseDto>> detailsResp = authService.getUserDetails(userReq);
        assertTrue(detailsResp.getBody().isSuccess());
        assertEquals("Daymark Engineer", detailsResp.getBody().getData().getName());

        UpdateUserRequestDto updateDto = new UpdateUserRequestDto();
        updateDto.setUserId(testUserId);
        updateDto.setName("Daymark Architect");
        updateDto.setMobile("9999888877");
        updateDto.setGender("Non-binary");

        authService.updateUser(updateDto);

        ResponseEntity<ApiResponse<UserDetailsResponseDto>> updatedResp = authService.getUserDetails(userReq);
        assertEquals("Daymark Architect", updatedResp.getBody().getData().getName());
        assertEquals("9999888877", updatedResp.getBody().getData().getMobile());
    }

    @Test
    @Order(3)
    public void testCreateNoteWithTagsAndPin() {
        CreateNoteRequestDto noteDto = new CreateNoteRequestDto();
        noteDto.setUserId(testUserId);
        noteDto.setTitle("Architecture Review");
        noteDto.setContent("Verify Spring Boot REST endpoints and Flutter Riverpod sync.");
        noteDto.setCategory("Engineering");
        noteDto.setPinned(true);
        noteDto.setTags("Backend, SpringBoot, Architecture");

        ResponseEntity<ApiResponse<CreateNoteResponseDto>> createResp = notesService.createNote(noteDto);
        assertTrue(createResp.getBody().isSuccess());
        testNoteId = createResp.getBody().getData().getNoteId();
        assertTrue(testNoteId > 0);

        ResponseEntity<ApiResponse<NotesModel>> detailResp = notesService.getNoteDetails(testNoteId, testUserId);
        assertTrue(detailResp.getBody().isSuccess());
        assertEquals("Architecture Review", detailResp.getBody().getData().getTitle());
        assertTrue(detailResp.getBody().getData().isPinned());
        assertEquals("Backend, SpringBoot, Architecture", detailResp.getBody().getData().getTags());
    }

    @Test
    @Order(4)
    public void testTogglePinAndSearch() {
        ResponseEntity<ApiResponse<NotesModel>> toggleResp = notesService.togglePin(testNoteId, testUserId);
        assertTrue(toggleResp.getBody().isSuccess());
        assertFalse(toggleResp.getBody().getData().isPinned());

        ResponseEntity<ApiResponse<List<NotesModel>>> searchResp = notesService.searchNotes(testUserId, "SpringBoot");
        assertTrue(searchResp.getBody().isSuccess());
        assertFalse(searchResp.getBody().getData().isEmpty());
    }

    @Test
    @Order(5)
    public void testCalendarSummaryAndDateQuery() {
        LocalDate now = LocalDate.now();
        ResponseEntity<ApiResponse<CalendarSummaryResponseDto>> summaryResp =
                notesService.getCalendarSummary(testUserId, now.getYear(), now.getMonthValue(), ZONE);
        assertTrue(summaryResp.getBody().isSuccess());
        assertTrue(summaryResp.getBody().getData().getTotalNotes() >= 1);

        String today = now.toString();
        ResponseEntity<ApiResponse<List<NotesModel>>> dateResp = notesService.getNotesByDate(testUserId, today, ZONE);
        assertTrue(dateResp.getBody().isSuccess());
        assertFalse(dateResp.getBody().getData().isEmpty());
    }

    @Test
    @Order(6)
    public void testExportNotes() {
        ResponseEntity<ApiResponse<ExportNotesResponseDto>> exportResp = notesService.exportNotes(testUserId);
        assertTrue(exportResp.getBody().isSuccess());
        assertEquals(1, exportResp.getBody().getData().getExportVersion());
        assertTrue(exportResp.getBody().getData().getTotalNotes() >= 1);
        assertNotNull(exportResp.getBody().getData().getNotes());
    }

    @Test
    @Order(7)
    public void testDeleteNote() {
        ResponseEntity<ApiResponse<NotesModel>> deleteResp = notesService.deleteNote(testNoteId, testUserId);
        assertTrue(deleteResp.getBody().isSuccess());

        assertThrows(NotFoundException.class, () -> notesService.getNoteDetails(testNoteId, testUserId));
    }

    @Test
    @Order(8)
    public void testTaskAndReminderLifecycle() {
        LocalDate today = LocalDate.now();

        // 1. Create Task
        com.example.notes_app.tasks.dto.request.CreateTaskRequestDto taskDto =
                new com.example.notes_app.tasks.dto.request.CreateTaskRequestDto();
        taskDto.setUserId(testUserId);
        taskDto.setTitle("Backend Unit Verification");
        taskDto.setDescription("Verify task and reminder APIs");
        taskDto.setDueDate(today.toString());
        taskDto.setDueTime("14:30");
        taskDto.setCategory("Work");
        taskDto.setStatus("PENDING");
        taskDto.setCompleted(false);

        var taskCreateResp = taskService.createTask(taskDto);
        assertTrue(taskCreateResp.getBody().isSuccess());
        long taskId = taskCreateResp.getBody().getData().getTaskId();
        assertTrue(taskId > 0);

        // 2. Create Reminder
        com.example.notes_app.reminders.dto.request.CreateReminderRequestDto reminderDto =
                new com.example.notes_app.reminders.dto.request.CreateReminderRequestDto();
        reminderDto.setUserId(testUserId);
        reminderDto.setTitle("Submit Daily Standup");
        reminderDto.setRemindAt(today.toString() + "T10:00:00");
        reminderDto.setDueDate(today.toString());
        reminderDto.setDueTime("10:00");
        reminderDto.setCategory("Daily");
        reminderDto.setStatus("PENDING");

        var reminderCreateResp = reminderService.createReminder(reminderDto);
        assertTrue(reminderCreateResp.getBody().isSuccess());
        long reminderId = reminderCreateResp.getBody().getData().getReminderId();
        assertTrue(reminderId > 0);

        // 3. Toggle Task Status to COMPLETED
        var toggleTaskResp = taskService.toggleStatus(taskId, "COMPLETED", testUserId);
        assertTrue(toggleTaskResp.getBody().isSuccess());
        assertEquals(com.example.notes_app.common.ItemStatus.COMPLETED, toggleTaskResp.getBody().getData().getStatus());
        assertTrue(toggleTaskResp.getBody().getData().isCompleted());

        // 4. Verify Calendar Summary Aggregates Tasks & Reminders
        var summaryResp = notesService.getCalendarSummary(testUserId, today.getYear(), today.getMonthValue(), ZONE);
        assertTrue(summaryResp.getBody().isSuccess());
        var summary = summaryResp.getBody().getData();
        assertTrue(summary.getTotalTasks() >= 1);
        assertTrue(summary.getTotalReminders() >= 1);
        assertTrue(summary.getTotalItems() >= 2);
        assertTrue(summary.getCountsByDate().getOrDefault(today.toString(), 0) >= 2);

        // 5. Day activity returns the same items the calendar counted for that date
        var dayResp = notesService.getDayActivity(testUserId, today.toString(), ZONE);
        assertTrue(dayResp.getBody().isSuccess());
        var day = dayResp.getBody().getData();
        assertEquals(today.toString(), day.getDate());
        assertTrue(day.getTasks().stream().anyMatch(t -> t.getTaskId() == taskId));
        assertTrue(day.getReminders().stream().anyMatch(r -> r.getReminderId() == reminderId));
        assertEquals(summary.getCountsByDate().get(today.toString()).intValue(), day.getTotalCount());
        assertThrows(BadRequestException.class, () -> notesService.getDayActivity(testUserId, "not-a-date", ZONE));

        // 6. Cleanup
        assertTrue(taskService.deleteTask(taskId, testUserId).getBody().isSuccess());
        assertTrue(reminderService.deleteReminder(reminderId, testUserId).getBody().isSuccess());
    }

    @Test
    @Order(9)
    public void testTaskRequestAcceptsIsCompletedKeyFromClient() throws Exception {
        var create = jsonMapper.readValue(
                "{\"userId\":1,\"title\":\"t\",\"isCompleted\":true}",
                com.example.notes_app.tasks.dto.request.CreateTaskRequestDto.class);
        assertTrue(create.isCompleted());

        var update = jsonMapper.readValue(
                "{\"taskId\":1,\"isCompleted\":true}",
                com.example.notes_app.tasks.dto.request.UpdateTaskRequestDto.class);
        assertTrue(update.isCompleted());
    }
}
