package com.example.notes_app.auth.service;

import com.example.notes_app.common.exception.TooManyRequestsException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * In-memory brute-force protection for {@code /auth/login}. Failed attempts are
 * counted per client IP and per (normalised) email in a fixed time window; once
 * either limit is reached, further attempts get HTTP 429 until the window ends.
 * A successful login clears the email's counter (not the IP's, so one valid
 * account can't be used to reset an attacker's IP budget).
 *
 * State is per instance and lost on restart, which is acceptable for a single
 * instance deployment. Use a shared store if the backend is ever scaled out.
 */
@Component
public class LoginRateLimiter {

    static final String TOO_MANY_ATTEMPTS = "Too many failed login attempts. Please try again later.";

    /** Above this many tracked keys, expired entries are purged on the next failure. */
    private static final int PURGE_THRESHOLD = 10_000;

    private final int maxFailuresPerEmail;
    private final int maxFailuresPerIp;
    private final Duration window;
    private final Clock clock;
    private final Map<String, Counter> failures = new ConcurrentHashMap<>();

    @Autowired
    public LoginRateLimiter(
            @Value("${app.auth.login.max-failures-per-email:10}") int maxFailuresPerEmail,
            @Value("${app.auth.login.max-failures-per-ip:50}") int maxFailuresPerIp,
            @Value("${app.auth.login.window-minutes:15}") long windowMinutes) {
        this(maxFailuresPerEmail, maxFailuresPerIp, Duration.ofMinutes(windowMinutes), Clock.systemUTC());
    }

    LoginRateLimiter(int maxFailuresPerEmail, int maxFailuresPerIp, Duration window, Clock clock) {
        this.maxFailuresPerEmail = maxFailuresPerEmail;
        this.maxFailuresPerIp = maxFailuresPerIp;
        this.window = window;
        this.clock = clock;
    }

    /** Throws {@link TooManyRequestsException} if this IP or email is locked out. */
    public void checkAllowed(String ip, String email) {
        Instant now = clock.instant();
        if (isLimited(ipKey(ip), maxFailuresPerIp, now) || isLimited(emailKey(email), maxFailuresPerEmail, now)) {
            throw new TooManyRequestsException(TOO_MANY_ATTEMPTS);
        }
    }

    public void recordFailure(String ip, String email) {
        Instant now = clock.instant();
        if (failures.size() > PURGE_THRESHOLD) {
            failures.entrySet().removeIf(entry -> entry.getValue().isExpired(now, window));
        }
        increment(ipKey(ip), now);
        increment(emailKey(email), now);
    }

    public void recordSuccess(String email) {
        failures.remove(emailKey(email));
    }

    private boolean isLimited(String key, int limit, Instant now) {
        Counter counter = failures.get(key);
        return counter != null && !counter.isExpired(now, window) && counter.count >= limit;
    }

    private void increment(String key, Instant now) {
        failures.compute(key, (k, existing) ->
                existing == null || existing.isExpired(now, window)
                        ? new Counter(now, 1)
                        : new Counter(existing.windowStart, existing.count + 1));
    }

    private static String ipKey(String ip) {
        return "ip:" + (ip == null ? "unknown" : ip);
    }

    private static String emailKey(String email) {
        return "email:" + (email == null ? "" : email);
    }

    private record Counter(Instant windowStart, int count) {
        boolean isExpired(Instant now, Duration window) {
            return !now.isBefore(windowStart.plus(window));
        }
    }
}
