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

    /**
     * REM-07: first occurrence of the series. When remindAt changes without it,
     * the new remindAt becomes the start (the user re-anchored the series).
     */
    private String startAt;

    /** REM-07: answer to the last handled occurrence (COMPLETED or MISSED), e.g. after a catch-up. */
    private String lastOutcome;
    private String lastOutcomeAt;
}
