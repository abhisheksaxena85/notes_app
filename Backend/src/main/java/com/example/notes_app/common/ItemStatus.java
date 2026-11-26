package com.example.notes_app.common;

/**
 * BE-04: status of a task or reminder. Stored as its name (VARCHAR), so the
 * values written before the enum existed still map.
 */
public enum ItemStatus {
    PENDING,
    COMPLETED,
    REJECTED,
    MISSED;

    /** Parses a request value (case-insensitive); null stays null, anything else is a 400. */
    public static ItemStatus parse(String value) {
        return Enums.parse(ItemStatus.class, value, "status");
    }
}
