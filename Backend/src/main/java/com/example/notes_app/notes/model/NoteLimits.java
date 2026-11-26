package com.example.notes_app.notes.model;

/**
 * Size limits for note fields. Requests over these limits get a 400 with a
 * clear message instead of a database error.
 */
public final class NoteLimits {

    /** notes.title is VARCHAR(500). */
    public static final int TITLE_MAX = 500;

    /** notes.content is LONGTEXT; this cap keeps a single request reasonable. */
    public static final int CONTENT_MAX = 100_000;

    /** notes.category is VARCHAR(255). */
    public static final int CATEGORY_MAX = 255;

    /** notes.tags is TEXT (64 KB); 2,000 characters fit even with 4-byte characters. */
    public static final int TAGS_MAX = 2_000;

    private NoteLimits() {
    }
}
