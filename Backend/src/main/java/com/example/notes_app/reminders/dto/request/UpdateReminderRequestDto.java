package com.example.notes_app.reminders.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateReminderRequestDto {
    private long reminderId;
    private String title;
    private String remindAt;
    private String dueDate;
    private String dueTime;
    private String category;
    private String status;
    private String repeatInterval;
}
