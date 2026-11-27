package com.example.notes_app.config;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** SEC-01: the signing secret comes from JWT_SECRET; prod refuses to start without it. */
class JwtConfigTest {

    private static final String GOOD_SECRET = "0123456789abcdef0123456789abcdef";

    @Test
    void missingSecretFailsOutsideDev() {
        IllegalStateException missing = assertThrows(IllegalStateException.class, () -> JwtConfig.secretKey("", false));
        assertTrue(missing.getMessage().contains("JWT_SECRET"));
        assertThrows(IllegalStateException.class, () -> JwtConfig.secretKey(null, false));
        assertThrows(IllegalStateException.class, () -> JwtConfig.secretKey("   ", false));
    }

    @Test
    void shortSecretFailsEverywhere() {
        assertThrows(IllegalStateException.class, () -> JwtConfig.secretKey("too-short", false));
        assertThrows(IllegalStateException.class, () -> JwtConfig.secretKey("too-short", true));
    }

    @Test
    void devWithoutSecretUsesARandomKey() {
        assertEquals(32, JwtConfig.secretKey(null, true).getEncoded().length);
    }

    @Test
    void secretFromTheEnvironmentIsUsed() {
        assertNotNull(JwtConfig.secretKey(GOOD_SECRET, false));
        assertEquals("HmacSHA256", JwtConfig.secretKey(GOOD_SECRET, false).getAlgorithm());
    }
}
