package com.example.notes_app.reminders.model;

import com.example.notes_app.common.Enums;

/** BE-04: how a reminder repeats. Stored as its name (VARCHAR). */
public enum RepeatInterval {
    NONE,
    DAILY,
    WEEKLY,
    MONTHLY;

    /** Parses a request value (case-insensitive); null stays null, anything else is a 400. */
    public static RepeatInterval parse(String value) {
        return Enums.parse(RepeatInterval.class, value, "repeatInterval");
    }
}
