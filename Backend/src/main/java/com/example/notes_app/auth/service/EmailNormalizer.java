package com.example.notes_app.auth.service;

import java.util.Locale;

/** One rule for emails everywhere: trimmed and lower-cased, so A@x.com and a@x.com are one account. */
public final class EmailNormalizer {

    private EmailNormalizer() {
    }

    public static String normalize(String email) {
        return email == null ? null : email.trim().toLowerCase(Locale.ROOT);
    }
}
