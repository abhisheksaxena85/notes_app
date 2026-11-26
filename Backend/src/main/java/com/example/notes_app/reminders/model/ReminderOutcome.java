package com.example.notes_app.reminders.model;

import com.example.notes_app.common.Enums;

/** REM-07: the user's answer to one occurrence of a reminder ("Done" / "Not done"). */
public enum ReminderOutcome {
    COMPLETED,
    MISSED;

    /** Parses a request value (case-insensitive); null stays null, anything else is a 400. */
    public static ReminderOutcome parse(String value) {
        return Enums.parse(ReminderOutcome.class, value, "outcome");
    }
}
