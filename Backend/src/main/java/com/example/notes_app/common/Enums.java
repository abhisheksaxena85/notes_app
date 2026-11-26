package com.example.notes_app.common;

import com.example.notes_app.common.exception.BadRequestException;

import java.util.Arrays;
import java.util.Locale;
import java.util.stream.Collectors;

/** BE-04: parses enum values sent as strings by the app, with a 400 on unknown values. */
public final class Enums {

    private Enums() {
    }

    /**
     * The constant named {@code value} (case-insensitive, surrounding spaces
     * ignored). Null or blank returns null so callers can apply their default.
     *
     * @throws BadRequestException naming {@code field} and the allowed values
     */
    public static <E extends Enum<E>> E parse(Class<E> type, String value, String field) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return Enum.valueOf(type, value.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            String allowed = Arrays.stream(type.getEnumConstants())
                    .map(Enum::name)
                    .collect(Collectors.joining(", "));
            throw new BadRequestException(field + " must be one of: " + allowed);
        }
    }
}
