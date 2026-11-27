package com.example.notes_app.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.env.Environment;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;

/**
 * SEC-01: HS256 access tokens signed with {@code JWT_SECRET}.
 *
 * <p>The secret must be at least 32 bytes. Outside the {@code dev} profile
 * (i.e. in prod) the app refuses to start without it. Under {@code dev} a
 * random per-run secret is used instead, so tokens stop working on restart.
 */
@Configuration
public class JwtConfig {

    /** {@code iss} claim of every token this server issues, and the only one it accepts. */
    public static final String ISSUER = "daymark";

    static final int MIN_SECRET_BYTES = 32;

    private static final Logger log = LoggerFactory.getLogger(JwtConfig.class);

    @Bean
    SecretKey jwtSecretKey(@Value("${app.auth.jwt.secret:}") String secret, Environment environment) {
        return secretKey(secret, environment.matchesProfiles("dev"));
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey jwtSecretKey) {
        return NimbusJwtEncoder.withSecretKey(jwtSecretKey).algorithm(MacAlgorithm.HS256).build();
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey jwtSecretKey) {
        NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(jwtSecretKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        // Default validators check exp/nbf (60 s clock skew); also pin the issuer
        // and require a numeric subject, which CurrentUser reads as the user id.
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                JwtValidators.createDefaultWithIssuer(ISSUER), JwtConfig::validateSubject));
        return decoder;
    }

    /** The signing key, or a startup failure when the secret is missing or too short. */
    static SecretKey secretKey(String secret, boolean devProfile) {
        if (secret == null || secret.isBlank()) {
            if (!devProfile) {
                throw new IllegalStateException(
                        "JWT_SECRET is not set. Set it to a random value of at least " + MIN_SECRET_BYTES + " bytes.");
            }
            log.warn("JWT_SECRET is not set; using a random secret for this dev run. Tokens will not survive a restart.");
            byte[] random = new byte[MIN_SECRET_BYTES];
            new SecureRandom().nextBytes(random);
            return new SecretKeySpec(random, "HmacSHA256");
        }
        byte[] bytes = secret.getBytes(StandardCharsets.UTF_8);
        if (bytes.length < MIN_SECRET_BYTES) {
            throw new IllegalStateException("JWT_SECRET must be at least " + MIN_SECRET_BYTES + " bytes long.");
        }
        return new SecretKeySpec(bytes, "HmacSHA256");
    }

    private static OAuth2TokenValidatorResult validateSubject(Jwt jwt) {
        String subject = jwt.getSubject();
        try {
            if (subject != null && Long.parseLong(subject) > 0) {
                return OAuth2TokenValidatorResult.success();
            }
        } catch (NumberFormatException ignored) {
            // fall through
        }
        return OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token", "Invalid subject", null));
    }
}
