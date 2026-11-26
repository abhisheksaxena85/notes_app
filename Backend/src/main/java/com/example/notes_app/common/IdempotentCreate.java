package com.example.notes_app.common;

import org.springframework.dao.DataIntegrityViolationException;

import java.util.Optional;
import java.util.function.Supplier;

/**
 * FE-03: creates that the app retries after a lost response carry a client
 * generated {@code clientId}. Notes, tasks and reminders have a unique key on
 * (user_id, client_id), so a retry finds the row the first attempt created and
 * returns it instead of inserting a duplicate.
 *
 * Callers must not wrap {@link #createOnce} in a transaction: if two requests
 * with the same clientId race, the loser's insert fails on the unique key and
 * the row is read again in a fresh transaction.
 */
public final class IdempotentCreate {

    /** The entity, and whether this call inserted it (false = it already existed). */
    public record Result<T>(T entity, boolean created) {
    }

    private IdempotentCreate() {
    }

    /** Blank or missing ids (old app builds) are treated as "no clientId". */
    public static String normalize(String clientId) {
        if (clientId == null) {
            return null;
        }
        String trimmed = clientId.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    public static <T> Result<T> createOnce(String clientId, Supplier<Optional<T>> findExisting, Supplier<T> create) {
        if (normalize(clientId) == null) {
            return new Result<>(create.get(), true);
        }
        Optional<T> existing = findExisting.get();
        if (existing.isPresent()) {
            return new Result<>(existing.get(), false);
        }
        try {
            return new Result<>(create.get(), true);
        } catch (DataIntegrityViolationException e) {
            // A concurrent request with the same clientId inserted it first.
            return findExisting.get()
                    .map(found -> new Result<>(found, false))
                    .orElseThrow(() -> e);
        }
    }
}
