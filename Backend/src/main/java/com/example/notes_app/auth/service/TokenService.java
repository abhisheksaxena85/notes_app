package com.example.notes_app.auth.service;

import com.example.notes_app.config.JwtConfig;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

/** SEC-01: issues the access token returned by login and signup ({@code sub} = user id). */
@Service
public class TokenService {

    /** A signed access token and when it stops being accepted. */
    public record IssuedToken(String accessToken, Instant expiresAt) {
    }

    private final JwtEncoder encoder;
    private final Duration ttl;

    public TokenService(JwtEncoder encoder, @Value("${app.auth.jwt.ttl:7d}") Duration ttl) {
        this.encoder = encoder;
        this.ttl = ttl;
    }

    public IssuedToken issue(long userId) {
        Instant now = Instant.now().truncatedTo(ChronoUnit.SECONDS);
        Instant expiresAt = now.plus(ttl);
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(JwtConfig.ISSUER)
                .subject(Long.toString(userId))
                .issuedAt(now)
                .expiresAt(expiresAt)
                .build();
        String token = encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
                .getTokenValue();
        return new IssuedToken(token, expiresAt);
    }
}
