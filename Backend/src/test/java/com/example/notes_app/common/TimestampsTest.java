package com.example.notes_app.common;

import com.example.notes_app.common.exception.BadRequestException;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class TimestampsTest {

    private static final ZoneId KOLKATA = ZoneId.of("Asia/Kolkata");

    @Test
    void nowIsAUtcInstant() {
        String now = Timestamps.now();
        assertTrue(now.endsWith("Z"), now);
        assertTrue(Timestamps.parse(now).isPresent());
    }

    @Test
    void valuesWithoutAnOffsetAreUtc() {
        Instant expected = Instant.parse("2026-11-25T20:00:00Z");
        assertEquals(Optional.of(expected), Timestamps.parse("2026-11-25T20:00:00Z"));
        assertEquals(Optional.of(expected), Timestamps.parse("2026-11-25T20:00"));
        assertEquals(Optional.of(expected), Timestamps.parse("2026-11-25T20:00:00.000"));
        assertEquals(Optional.of(expected), Timestamps.parse("2026-11-26T01:30:00+05:30"));
    }

    @Test
    void unreadableValuesHaveNoDay() {
        assertTrue(Timestamps.parse(null).isEmpty());
        assertTrue(Timestamps.parse("  ").isEmpty());
        assertTrue(Timestamps.localDay("yesterday", KOLKATA).isEmpty());
    }

    @Test
    void daysAreBucketedInTheCallersZoneAroundMidnight() {
        // 01:30 on Nov 26 in India is 20:00 on Nov 25 in UTC.
        assertEquals(Optional.of(LocalDate.of(2026, 11, 26)),
                Timestamps.localDay("2026-11-25T20:00:00Z", KOLKATA));
        assertEquals(Optional.of(LocalDate.of(2026, 11, 25)),
                Timestamps.localDay("2026-11-25T20:00:00Z", ZoneOffset.UTC));
        // Midnight in Kolkata is 18:30 UTC: one millisecond either side.
        assertEquals(Optional.of(LocalDate.of(2026, 11, 25)),
                Timestamps.localDay("2026-11-25T18:29:59.999", KOLKATA));
        assertEquals(Optional.of(LocalDate.of(2026, 11, 26)),
                Timestamps.localDay("2026-11-25T18:30:00.000Z", KOLKATA));
    }

    @Test
    void zoneDefaultsToUtcAndRejectsUnknownNames() {
        assertEquals(ZoneOffset.UTC, Timestamps.zone(null));
        assertEquals(ZoneOffset.UTC, Timestamps.zone(""));
        assertEquals(KOLKATA, Timestamps.zone("Asia/Kolkata"));
        assertThrows(BadRequestException.class, () -> Timestamps.zone("Mars/Olympus_Mons"));
    }
}
