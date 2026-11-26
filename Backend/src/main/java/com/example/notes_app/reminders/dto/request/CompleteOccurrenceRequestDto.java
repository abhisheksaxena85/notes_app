package com.example.notes_app.reminders.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/** REM-07: the user's answer to one occurrence ({@code PUT /reminders/complete-occurrence}). */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CompleteOccurrenceRequestDto {
    private long reminderId;

    /** The occurrence being answered, as the app saw it: {@code yyyy-MM-ddTHH:mm[:ss]}. */
    @NotBlank(message = "occurrence is required")
    private String occurrence;

    /** COMPLETED or MISSED. */
    @NotBlank(message = "outcome is required")
    private String outcome;
}
