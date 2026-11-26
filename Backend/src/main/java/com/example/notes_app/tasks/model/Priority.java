package com.example.notes_app.tasks.model;

import com.example.notes_app.common.Enums;

/** BE-04: task priority. Stored as its name (VARCHAR). */
public enum Priority {
    LOW,
    MEDIUM,
    HIGH;

    /** Parses a request value (case-insensitive); null stays null, anything else is a 400. */
    public static Priority parse(String value) {
        return Enums.parse(Priority.class, value, "priority");
    }
}
