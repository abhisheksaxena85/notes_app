package com.example.notes_app;

import com.example.notes_app.config.JwtConfig;
import org.springframework.http.MediaType;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

import java.time.Instant;
import java.util.UUID;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** SEC-01 test helpers: sign up through the API and send its token. */
final class TestUsers {

    /** A signed-up user and the access token signup returned. */
    record User(long id, String token) {
        MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder request) {
            return bearer(request, token);
        }
    }

    private TestUsers() {
    }

    static User signUp(MockMvc mockMvc, JsonMapper jsonMapper) throws Exception {
        String email = "sec01_" + UUID.randomUUID() + "@example.com";
        String body = mockMvc.perform(post("/auth/create-user")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Sec\",\"email\":\"" + email + "\",\"password\":\"CorrectHorse1\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        JsonNode data = jsonMapper.readTree(body).get("data");
        return new User(data.get("userId").asLong(), data.get("accessToken").asString());
    }

    static MockHttpServletRequestBuilder bearer(MockHttpServletRequestBuilder request, String token) {
        return request.header("Authorization", "Bearer " + token);
    }

    static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, String body) {
        return request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    /** A correctly signed token for {@code userId} that expired a day ago. */
    static String expiredToken(JwtEncoder encoder, long userId) {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(JwtConfig.ISSUER)
                .subject(Long.toString(userId))
                .issuedAt(now.minusSeconds(8 * 24 * 3600))
                .expiresAt(now.minusSeconds(24 * 3600))
                .build();
        return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
                .getTokenValue();
    }
}
