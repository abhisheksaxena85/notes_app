package com.example.notes_app.common;

import com.example.notes_app.common.exception.BadRequestException;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.Optional;

/**
 * BE-04: the wall-clock values the user picks ({@code remindAt},
 * {@code dueDate}, {@code dueTime}). They have no zone and are never
 * converted (see {@link Timestamps}); this only validates and formats them.
 */
public final class WallClock {

    /** {@code yyyy-MM-dd'T'HH:mm} with optional {@code :ss}. */
    private static final DateTimeFormatter DATE_TIME_INPUT = new DateTimeFormatterBuilder()
            .appendPattern("uuuu-MM-dd'T'HH:mm")
            .optionalStart().appendPattern(":ss").optionalEnd()
            .toFormatter()
            .withResolverStyle(ResolverStyle.STRICT);

    /** How date-times are stored and returned: always with seconds. */
    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("uuuu-MM-dd'T'HH:mm:ss")
            .withResolverStyle(ResolverStyle.STRICT);
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("uuuu-MM-dd")
            .withResolverStyle(ResolverStyle.STRICT);
    private static final DateTimeFormatter TIME = DateTimeFormatter.ofPattern("HH:mm")
            .withResolverStyle(ResolverStyle.STRICT);

    private WallClock() {
    }

    /** Parses {@code yyyy-MM-ddTHH:mm[:ss]}, or throws a 400 naming {@code field}. */
    public static LocalDateTime parseDateTime(String field, String value) {
        return tryParseDateTime(value).orElseThrow(() ->
                new BadRequestException(field + " must be a date and time like 2026-11-26T18:00:00"));
    }

    /** Lenient read of a stored value: empty if it is missing or not in the expected format. */
    public static Optional<LocalDateTime> tryParseDateTime(String value) {
        if (value == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(LocalDateTime.parse(value.trim(), DATE_TIME_INPUT));
        } catch (DateTimeParseException e) {
            return Optional.empty();
        }
    }

    /** Parses {@code yyyy-MM-dd}, or throws a 400 naming {@code field}. */
    public static LocalDate parseDate(String field, String value) {
        try {
            return LocalDate.parse(value.trim(), DATE);
        } catch (DateTimeParseException | NullPointerException e) {
            throw new BadRequestException(field + " must be a date like 2026-11-26");
        }
    }

    /** Parses {@code HH:mm}, or throws a 400 naming {@code field}. */
    public static LocalTime parseTime(String field, String value) {
        try {
            return LocalTime.parse(value.trim(), TIME);
        } catch (DateTimeParseException | NullPointerException e) {
            throw new BadRequestException(field + " must be a time like 18:00");
        }
    }

    public static String format(LocalDateTime value) {
        return value.format(DATE_TIME);
    }

    public static String formatDate(LocalDate value) {
        return value.format(DATE);
    }

    public static String formatTime(LocalTime value) {
        return value.format(TIME);
    }
}
