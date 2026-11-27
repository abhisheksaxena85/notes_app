package com.example.notes_app.reminders.controller;

import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.CurrentUser;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.reminders.dto.request.CompleteOccurrenceRequestDto;
import com.example.notes_app.reminders.dto.request.CreateReminderRequestDto;
import com.example.notes_app.reminders.dto.request.UpdateReminderRequestDto;
import com.example.notes_app.reminders.dto.response.CreateReminderResponseDto;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.reminders.service.ReminderService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reminders")
public class ReminderController {

    @Autowired
    private ReminderService reminderService;

    @Autowired
    private CurrentUser currentUser;

    @PostMapping("/create-reminder")
    public ResponseEntity<ApiResponse<CreateReminderResponseDto>> createReminder(@Valid @RequestBody CreateReminderRequestDto requestDto) {
        requestDto.setUserId(currentUser.resolve(requestDto.getUserId(), "userId"));
        return reminderService.createReminder(requestDto);
    }

    @GetMapping("/get-all-reminders")
    public ResponseEntity<ApiResponse<List<ReminderModel>>> getAllReminders(@RequestParam(required = false) Long userId) {
        return reminderService.getAllReminders(currentUser.resolve(userId, "userId"));
    }

    @GetMapping("/get-by-date")
    public ResponseEntity<ApiResponse<List<ReminderModel>>> getRemindersByDate(
            @RequestParam(required = false) Long userId,
            @RequestParam String date) {
        return reminderService.getRemindersByDate(currentUser.resolve(userId, "userId"), date);
    }

    @PutMapping("/update-reminder")
    public ResponseEntity<ApiResponse<ReminderModel>> updateReminder(@RequestBody UpdateReminderRequestDto requestDto) {
        return reminderService.updateReminder(requestDto, currentUser.ownerScope());
    }

    @PutMapping("/update-status")
    public ResponseEntity<ApiResponse<ReminderModel>> updateStatus(
            @RequestParam long reminderId,
            @RequestParam(required = false) String status) {
        return reminderService.updateStatus(reminderId, status, currentUser.ownerScope());
    }

    /** REM-07: "Done" / "Not done" for one occurrence; idempotent by occurrence. */
    @PutMapping("/complete-occurrence")
    public ResponseEntity<ApiResponse<ReminderModel>> completeOccurrence(
            @Valid @RequestBody CompleteOccurrenceRequestDto requestDto) {
        return reminderService.completeOccurrence(requestDto, currentUser.ownerScope());
    }

    @DeleteMapping("/delete-reminder")
    public ResponseEntity<ApiResponse<Boolean>> deleteReminder(
            @RequestParam(required = false) Long id,
            @RequestParam(required = false) Long reminderId) {
        Long targetId = id != null ? id : reminderId;
        if (targetId == null) {
            throw new BadRequestException("Reminder id is required");
        }
        return reminderService.deleteReminder(targetId, currentUser.ownerScope());
    }
}
