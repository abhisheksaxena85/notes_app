package com.example.notes_app.reminders.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.reminders.dto.request.CreateReminderRequestDto;
import com.example.notes_app.reminders.dto.request.UpdateReminderRequestDto;
import com.example.notes_app.reminders.dto.response.CreateReminderResponseDto;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.reminders.repository.ReminderRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class ReminderService {

    @Autowired
    private ReminderRepository reminderRepository;

    @Autowired
    private AuthRepository authRepository;

    private ReminderModel requireReminder(long reminderId) {
        return reminderRepository.findById(reminderId)
                .orElseThrow(() -> new NotFoundException("Reminder not found"));
    }

    @Transactional
    public ResponseEntity<ApiResponse<CreateReminderResponseDto>> createReminder(CreateReminderRequestDto requestDto) {
        UserModel user = authRepository.findById(requestDto.getUserId())
                .orElseThrow(() -> new NotFoundException("User not found"));

        ReminderModel reminder = new ReminderModel();
        reminder.setTitle(requestDto.getTitle());
        reminder.setRemindAt(requestDto.getRemindAt());

        String dueDate = requestDto.getDueDate();
        if ((dueDate == null || dueDate.isEmpty()) && requestDto.getRemindAt() != null && requestDto.getRemindAt().length() >= 10) {
            dueDate = requestDto.getRemindAt().substring(0, 10);
        }
        reminder.setDueDate(dueDate);

        String dueTime = requestDto.getDueTime();
        if ((dueTime == null || dueTime.isEmpty()) && requestDto.getRemindAt() != null && requestDto.getRemindAt().length() >= 16) {
            dueTime = requestDto.getRemindAt().substring(11, 16);
        }
        reminder.setDueTime(dueTime);

        reminder.setCategory(requestDto.getCategory() != null ? requestDto.getCategory() : "General");
        reminder.setStatus(requestDto.getStatus() != null ? requestDto.getStatus() : "PENDING");
        reminder.setRepeatInterval(requestDto.getRepeatInterval() != null ? requestDto.getRepeatInterval() : "NONE");
        reminder.setCreatedAt(LocalDateTime.now().toString());
        reminder.setUpdatedAt(LocalDateTime.now().toString());
        reminder.setUser(user);

        ReminderModel saved = reminderRepository.save(reminder);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, "Reminder created successfully", new CreateReminderResponseDto(saved.getReminderId())));
    }

    public ResponseEntity<ApiResponse<List<ReminderModel>>> getAllReminders(long userId) {
        List<ReminderModel> reminders = reminderRepository.findByUserId(userId);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminders fetched successfully", reminders));
    }

    public ResponseEntity<ApiResponse<List<ReminderModel>>> getRemindersByDate(long userId, String date) {
        List<ReminderModel> reminders = reminderRepository.findByUserIdAndDueDate(userId, date);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminders for date fetched", reminders));
    }

    @Transactional
    public ResponseEntity<ApiResponse<ReminderModel>> updateReminder(UpdateReminderRequestDto requestDto) {
        ReminderModel reminder = requireReminder(requestDto.getReminderId());

        if (requestDto.getTitle() != null) reminder.setTitle(requestDto.getTitle());
        if (requestDto.getRemindAt() != null) reminder.setRemindAt(requestDto.getRemindAt());
        if (requestDto.getDueDate() != null) reminder.setDueDate(requestDto.getDueDate());
        if (requestDto.getDueTime() != null) reminder.setDueTime(requestDto.getDueTime());
        if (requestDto.getCategory() != null) reminder.setCategory(requestDto.getCategory());
        if (requestDto.getStatus() != null) reminder.setStatus(requestDto.getStatus());
        if (requestDto.getRepeatInterval() != null) reminder.setRepeatInterval(requestDto.getRepeatInterval());
        reminder.setUpdatedAt(LocalDateTime.now().toString());

        ReminderModel saved = reminderRepository.save(reminder);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminder updated successfully", saved));
    }

    @Transactional
    public ResponseEntity<ApiResponse<ReminderModel>> updateStatus(long reminderId, String status) {
        ReminderModel reminder = requireReminder(reminderId);

        String newStatus = status != null ? status.toUpperCase() : ("COMPLETED".equalsIgnoreCase(reminder.getStatus()) ? "PENDING" : "COMPLETED");
        reminder.setStatus(newStatus);
        reminder.setUpdatedAt(LocalDateTime.now().toString());

        ReminderModel saved = reminderRepository.save(reminder);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminder status updated", saved));
    }

    @Transactional
    public ResponseEntity<ApiResponse<Boolean>> deleteReminder(long reminderId) {
        if (!reminderRepository.existsById(reminderId)) {
            throw new NotFoundException("Reminder not found");
        }
        reminderRepository.deleteById(reminderId);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminder deleted successfully", true));
    }
}
