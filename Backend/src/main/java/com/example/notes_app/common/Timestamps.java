package com.example.notes_app.common;

import com.example.notes_app.common.exception.BadRequestException;

import java.time.DateTimeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.Optional;

/**
 * BE-02: {@code createdAt} / {@code updatedAt} are absolute instants, written
 * as ISO-8601 UTC ({@code 2026-11-25T20:00:00Z}).
 *
 * <p>Rows written before BE-02 hold {@code LocalDateTime.now()} values without
 * an offset. The server ran in UTC, so they are read as UTC and are not
 * rewritten.
 *
 * <p>Task {@code dueDate}/{@code dueTime} and reminder {@code remindAt} are
 * wall-clock values the user picked; they are not instants and are never
 * converted.
 */
public final class Timestamps {

    private Timestamps() {
    }

    /** Now, as stored in {@code createdAt} / {@code updatedAt}. */
    public static String now() {
        return Instant.now().truncatedTo(ChronoUnit.MILLIS).toString();
    }

    /** The instant of a stored timestamp. Values without an offset are UTC. */
    public static Optional<Instant> parse(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        String text = value.trim();
        try {
            return Optional.of(OffsetDateTime.parse(text).toInstant());
        } catch (DateTimeParseException withoutOffset) {
            try {
                return Optional.of(LocalDateTime.parse(text).toInstant(ZoneOffset.UTC));
            } catch (DateTimeParseException unreadable) {
                return Optional.empty();
            }
        }
    }

    /** The calendar day of a stored timestamp in {@code zone}. */
    public static Optional<LocalDate> localDay(String value, ZoneId zone) {
        return parse(value).map(instant -> instant.atZone(zone).toLocalDate());
    }

    /**
     * The zone to bucket days in: an IANA name such as {@code Asia/Kolkata}
     * from the {@code tz} request parameter, or UTC when none was sent.
     */
    public static ZoneId zone(String tz) {
        if (tz == null || tz.isBlank()) {
            return ZoneOffset.UTC;
        }
        try {
            return ZoneId.of(tz.trim());
        } catch (DateTimeException e) {
            throw new BadRequestException("Unknown time zone: use an IANA name such as Asia/Kolkata");
        }
    }
}
