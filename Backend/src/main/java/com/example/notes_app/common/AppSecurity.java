package com.example.notes_app.common;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.server.resource.InvalidBearerTokenException;
import org.springframework.security.oauth2.server.resource.web.BearerTokenAuthenticationEntryPoint;
import org.springframework.security.oauth2.server.resource.web.BearerTokenResolver;
import org.springframework.security.oauth2.server.resource.web.DefaultBearerTokenResolver;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.servlet.util.matcher.PathPatternRequestMatcher;
import org.springframework.security.web.util.matcher.OrRequestMatcher;
import org.springframework.security.web.util.matcher.RequestMatcher;
import tools.jackson.databind.json.JsonMapper;

/**
 * SEC-01: stateless JWT bearer auth.
 *
 * <p>{@code app.auth.enforced} ({@code AUTH_ENFORCED}) controls the rollout:
 * <ul>
 *   <li>{@code false} (default): data routes stay reachable without a token, for
 *       app builds that predate tokens. A request that does send a token is
 *       authenticated with it and owner-scoped (see {@link CurrentUser}).</li>
 *   <li>{@code true}: every route except login, signup and the API docs needs
 *       a valid token.</li>
 * </ul>
 * In both modes an invalid or expired token is rejected with 401.
 */
@Configuration
@EnableWebSecurity
public class AppSecurity {

    /** Login and signup: never need a token, and ignore one if sent (it may be stale). */
    private static final RequestMatcher CREDENTIAL_ROUTES = new OrRequestMatcher(
            PathPatternRequestMatcher.pathPattern(HttpMethod.POST, "/auth/login"),
            PathPatternRequestMatcher.pathPattern(HttpMethod.POST, "/auth/create-user"));

    private static final String[] DOC_ROUTES = {
            "/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**", "/v3/api-docs.yaml"};

    /** Data routes the pre-token app calls; open only while auth is not enforced. */
    private static final String[] LEGACY_OPEN_ROUTES = {"/auth/**", "/notes/**", "/tasks/**", "/reminders/**"};

    @Bean
    public SecurityFilterChain securityFilterChain(
            HttpSecurity http,
            @Value("${app.auth.enforced:false}") boolean authEnforced,
            JsonMapper jsonMapper) throws Exception {
        AuthenticationEntryPoint entryPoint = jsonEntryPoint(jsonMapper);
        http.csrf(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> {
                    auth.requestMatchers(CREDENTIAL_ROUTES).permitAll()
                            .requestMatchers(DOC_ROUTES).permitAll()
                            .requestMatchers("/error").permitAll();
                    if (!authEnforced) {
                        auth.requestMatchers(LEGACY_OPEN_ROUTES).permitAll();
                    }
                    auth.anyRequest().authenticated();
                })
                .oauth2ResourceServer(oauth -> oauth
                        .jwt(jwt -> { })
                        .bearerTokenResolver(bearerTokenResolver())
                        .authenticationEntryPoint(entryPoint))
                .exceptionHandling(exceptions -> exceptions.authenticationEntryPoint(entryPoint));
        return http.build();
    }

    /** Reads {@code Authorization: Bearer}, except on login/signup. */
    static BearerTokenResolver bearerTokenResolver() {
        DefaultBearerTokenResolver header = new DefaultBearerTokenResolver();
        return (HttpServletRequest request) -> CREDENTIAL_ROUTES.matches(request) ? null : header.resolve(request);
    }

    /** 401 with the standard WWW-Authenticate header and an {@link ApiResponse} body. */
    private static AuthenticationEntryPoint jsonEntryPoint(JsonMapper jsonMapper) {
        BearerTokenAuthenticationEntryPoint bearer = new BearerTokenAuthenticationEntryPoint();
        return (request, response, authException) -> {
            bearer.commence(request, response, authException);
            String message = authException instanceof InvalidBearerTokenException
                    ? "Invalid or expired token"
                    : "Authentication required";
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write(jsonMapper.writeValueAsString(new ApiResponse<Void>(false, message, null)));
        };
    }
}
