package com.example.notes_app.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Browser origins allowed to call the API. The mobile app doesn't need CORS;
 * this is for web pages such as the account-deletion site on GitHub Pages
 * ({@code Website/}).
 *
 * <p>AppSecurity applies it with {@code http.cors(...)}, so the CORS preflight
 * (sent without a token) is answered before authentication, also when
 * {@code AUTH_ENFORCED=true}.
 */
@Configuration
public class CrossOriginConfig {

    /** Comma-separated origins, e.g. {@code https://user.github.io} (no path, no trailing slash). */
    private static final String DEFAULT_ORIGINS =
            "https://notesapp-production-d43adec7.up.railway.app,https://abhisheksaxena85.github.io";

    @Bean
    public CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origins:" + DEFAULT_ORIGINS + "}") List<String> allowedOrigins) {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(allowedOrigins.stream().map(String::trim).filter(o -> !o.isEmpty()).toList());
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
