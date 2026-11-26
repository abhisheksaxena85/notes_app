package com.example.notes_app.reminders.service;

import com.example.notes_app.reminders.model.RepeatInterval;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.temporal.TemporalAdjusters;

/**
 * REM-07: occurrences of a repeating reminder. Same rules as the app's
 * {@code nextOccurrence} (REM-05):
 *
 * <ul>
 *   <li>everything is wall-clock time ({@link LocalDateTime}, no zone), so a
 *       DST change never shifts the time of day;</li>
 *   <li>DAILY: same time every day; WEEKLY: same weekday and time;</li>
 *   <li>MONTHLY: same day of month as {@code start}, clamped to the month's
 *       length (Jan 31 → Feb 28/29 → Mar 31), always anchored to
 *       {@code start}, never drifting.</li>
 * </ul>
 */
public final class RecurrenceCalculator {

    private RecurrenceCalculator() {
    }

    /**
     * The first occurrence strictly after {@code after}; {@code start} itself
     * when {@code after} is before it. Null for {@link RepeatInterval#NONE}.
     */
    public static LocalDateTime next(LocalDateTime start, RepeatInterval interval, LocalDateTime after) {
        if (interval == null || interval == RepeatInterval.NONE) {
            return null;
        }
        if (after.isBefore(start)) {
            return start;
        }
        return switch (interval) {
            case DAILY -> {
                LocalDateTime candidate = LocalDateTime.of(after.toLocalDate(), start.toLocalTime());
                yield candidate.isAfter(after) ? candidate : candidate.plusDays(1);
            }
            case WEEKLY -> {
                LocalDate day = after.toLocalDate().with(TemporalAdjusters.nextOrSame(start.getDayOfWeek()));
                LocalDateTime candidate = LocalDateTime.of(day, start.toLocalTime());
                yield candidate.isAfter(after) ? candidate : candidate.plusWeeks(1);
            }
            case MONTHLY -> {
                YearMonth month = YearMonth.from(after);
                while (true) {
                    LocalDateTime candidate = monthly(start, month);
                    if (candidate.isAfter(after)) {
                        yield candidate;
                    }
                    month = month.plusMonths(1);
                }
            }
            case NONE -> null;
        };
    }

    private static LocalDateTime monthly(LocalDateTime start, YearMonth month) {
        int day = Math.min(start.getDayOfMonth(), month.lengthOfMonth());
        return LocalDateTime.of(month.atDay(day), start.toLocalTime());
    }
}
