package com.example.notes_app.auth.service;

import com.example.notes_app.common.exception.TooManyRequestsException;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;

import static org.junit.jupiter.api.Assertions.*;

class LoginRateLimiterTest {

    /** A clock the test can move forward. */
    private static final class MutableClock extends Clock {
        private Instant now = Instant.parse("2026-01-01T00:00:00Z");

        void advance(Duration duration) {
            now = now.plus(duration);
        }

        @Override
        public ZoneId getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return this;
        }

        @Override
        public Instant instant() {
            return now;
        }
    }

    private final MutableClock clock = new MutableClock();
    private final LoginRateLimiter limiter = new LoginRateLimiter(3, 5, Duration.ofMinutes(15), clock);

    @Test
    void locksAnEmailAfterTheLimitUntilTheWindowEnds() {
        for (int i = 0; i < 3; i++) {
            limiter.checkAllowed("1.1.1.1", "a@x.com");
            limiter.recordFailure("1.1.1.1", "a@x.com");
        }
        assertThrows(TooManyRequestsException.class, () -> limiter.checkAllowed("2.2.2.2", "a@x.com"));
        assertDoesNotThrow(() -> limiter.checkAllowed("1.1.1.1", "b@x.com"));

        clock.advance(Duration.ofMinutes(15));
        assertDoesNotThrow(() -> limiter.checkAllowed("1.1.1.1", "a@x.com"));
    }

    @Test
    void locksAnIpThatTriesManyEmails() {
        for (int i = 0; i < 5; i++) {
            limiter.recordFailure("9.9.9.9", "user" + i + "@x.com");
        }
        assertThrows(TooManyRequestsException.class, () -> limiter.checkAllowed("9.9.9.9", "new@x.com"));
        assertDoesNotThrow(() -> limiter.checkAllowed("8.8.8.8", "new@x.com"));
    }

    @Test
    void successClearsTheEmailCounterButNotTheIpCounter() {
        limiter.recordFailure("1.1.1.1", "a@x.com");
        limiter.recordFailure("1.1.1.1", "a@x.com");
        limiter.recordSuccess("a@x.com");
        limiter.recordFailure("1.1.1.1", "a@x.com");
        limiter.recordFailure("1.1.1.1", "a@x.com");
        assertDoesNotThrow(() -> limiter.checkAllowed("3.3.3.3", "a@x.com"));

        limiter.recordFailure("1.1.1.1", "c@x.com");
        assertThrows(TooManyRequestsException.class, () -> limiter.checkAllowed("1.1.1.1", "z@x.com"));
    }
}
