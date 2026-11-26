package com.example.notes_app.reminders.controller;

import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.reminders.dto.request.CreateReminderRequestDto;
import com.example.notes_app.reminders.dto.request.UpdateReminderRequestDto;
import com.example.notes_app.reminders.dto.response.CreateReminderResponseDto;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.reminders.service.ReminderService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reminders")
public class ReminderController {

    @Autowired
    private ReminderService reminderService;

    @PostMapping("/create-reminder")
    public ResponseEntity<ApiResponse<CreateReminderResponseDto>> createReminder(@RequestBody CreateReminderRequestDto requestDto) {
        return reminderService.createReminder(requestDto);
    }

    @GetMapping("/get-all-reminders")
    public ResponseEntity<ApiResponse<List<ReminderModel>>> getAllReminders(@RequestParam long userId) {
        return reminderService.getAllReminders(userId);
    }

    @GetMapping("/get-by-date")
    public ResponseEntity<ApiResponse<List<ReminderModel>>> getRemindersByDate(
            @RequestParam long userId,
            @RequestParam String date) {
        return reminderService.getRemindersByDate(userId, date);
    }

    @PutMapping("/update-reminder")
    public ResponseEntity<ApiResponse<ReminderModel>> updateReminder(@RequestBody UpdateReminderRequestDto requestDto) {
        return reminderService.updateReminder(requestDto);
    }

    @PutMapping("/update-status")
    public ResponseEntity<ApiResponse<ReminderModel>> updateStatus(
            @RequestParam long reminderId,
            @RequestParam(required = false) String status) {
        return reminderService.updateStatus(reminderId, status);
    }

    @DeleteMapping("/delete-reminder")
    public ResponseEntity<ApiResponse<Boolean>> deleteReminder(
            @RequestParam(required = false) Long id,
            @RequestParam(required = false) Long reminderId) {
        long targetId = id != null ? id : (reminderId != null ? reminderId : 0L);
        return reminderService.deleteReminder(targetId);
    }
}
