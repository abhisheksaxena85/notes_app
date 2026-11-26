package com.example.notes_app.reminders.service;

import com.example.notes_app.reminders.model.RepeatInterval;
import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;

/** REM-07: same cases as the app's nextOccurrence tests (REM-05). */
class RecurrenceCalculatorTest {

    private static LocalDateTime at(String value) {
        return LocalDateTime.parse(value);
    }

    private static LocalDateTime next(String start, RepeatInterval interval, String after) {
        return RecurrenceCalculator.next(at(start), interval, at(after));
    }

    @Test
    void noneHasNoNextOccurrence() {
        assertNull(next("2026-01-01T08:00", RepeatInterval.NONE, "2026-01-01T08:00"));
        assertNull(RecurrenceCalculator.next(at("2026-01-01T08:00"), null, at("2026-01-01T08:00")));
    }

    @Test
    void beforeTheStartTheStartIsNext() {
        assertEquals(at("2026-03-10T08:00"), next("2026-03-10T08:00", RepeatInterval.DAILY, "2026-03-01T00:00"));
    }

    @Test
    void dailyAcrossMonthAndYearEnds() {
        assertEquals(at("2026-02-01T08:00"), next("2026-01-01T08:00", RepeatInterval.DAILY, "2026-01-31T08:00"));
        assertEquals(at("2027-01-01T08:00"), next("2026-12-01T08:00", RepeatInterval.DAILY, "2026-12-31T08:00"));
        // Later on the same day: tomorrow; earlier on the same day: today.
        assertEquals(at("2026-05-06T08:00"), next("2026-05-01T08:00", RepeatInterval.DAILY, "2026-05-05T09:15"));
        assertEquals(at("2026-05-05T08:00"), next("2026-05-01T08:00", RepeatInterval.DAILY, "2026-05-05T07:59"));
    }

    @Test
    void afterEqualToAnOccurrenceReturnsTheFollowingOne() {
        assertEquals(at("2026-01-02T08:00"), next("2026-01-01T08:00", RepeatInterval.DAILY, "2026-01-01T08:00"));
        assertEquals(at("2026-01-08T08:00"), next("2026-01-01T08:00", RepeatInterval.WEEKLY, "2026-01-01T08:00"));
        assertEquals(at("2026-02-01T08:00"), next("2026-01-01T08:00", RepeatInterval.MONTHLY, "2026-01-01T08:00"));
    }

    @Test
    void weeklyKeepsTheWeekday() {
        // 2026-11-26 is a Thursday.
        assertEquals(at("2026-12-03T18:00"), next("2026-11-26T18:00", RepeatInterval.WEEKLY, "2026-11-26T18:00"));
        assertEquals(at("2026-12-03T18:00"), next("2026-11-26T18:00", RepeatInterval.WEEKLY, "2026-11-28T10:00"));
        assertEquals(at("2027-01-07T18:00"), next("2026-11-26T18:00", RepeatInterval.WEEKLY, "2026-12-31T18:00"));
    }

    @Test
    void monthlyFromThe31stClampsAndKeepsTheAnchor() {
        String start = "2026-01-31T09:00";
        String feb = "2026-02-28T09:00";
        assertEquals(at(feb), next(start, RepeatInterval.MONTHLY, start));
        assertEquals(at("2026-03-31T09:00"), next(start, RepeatInterval.MONTHLY, feb));
        assertEquals(at("2026-04-30T09:00"), next(start, RepeatInterval.MONTHLY, "2026-03-31T09:00"));
        assertEquals(at("2026-05-31T09:00"), next(start, RepeatInterval.MONTHLY, "2026-04-30T09:00"));
        // Leap year.
        assertEquals(at("2028-02-29T09:00"), next("2028-01-31T09:00", RepeatInterval.MONTHLY, "2028-01-31T09:00"));
    }

    @Test
    void monthlyAcrossTheYearEnd() {
        assertEquals(at("2027-01-15T12:00"), next("2026-06-15T12:00", RepeatInterval.MONTHLY, "2026-12-15T12:00"));
    }

    @Test
    void wallClockTimeIsKeptAcrossDstChanges() {
        // US DST starts 2026-03-08; the time of day must not shift.
        assertEquals(at("2026-03-08T02:30"), next("2026-03-01T02:30", RepeatInterval.DAILY, "2026-03-07T02:30"));
        assertEquals(at("2026-03-09T08:00"), next("2026-03-01T08:00", RepeatInterval.DAILY, "2026-03-08T08:00"));
    }
}
