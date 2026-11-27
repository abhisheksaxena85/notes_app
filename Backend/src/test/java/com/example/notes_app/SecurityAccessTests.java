package com.example.notes_app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import tools.jackson.databind.json.JsonMapper;

import java.util.List;

import static org.hamcrest.Matchers.startsWith;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * SEC-01 with {@code AUTH_ENFORCED=false} (the default, used during rollout):
 * tokens are issued and honoured, a bad token is always 401, and app builds
 * that send no token keep working. Enforced mode: {@link AuthEnforcedTests}.
 */
@SpringBootTest
@AutoConfigureMockMvc
public class SecurityAccessTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JsonMapper jsonMapper;

    @Autowired
    private JwtEncoder jwtEncoder;

    /** One read route per group, addressed by the caller's own user id. */
    private static List<MockHttpServletRequestBuilder> routeGroups(long userId) {
        String id = Long.toString(userId);
        return List.of(
                get("/notes/get-all-notes").param("id", id),
                get("/tasks/get-all-tasks").param("userId", id),
                get("/reminders/get-all-reminders").param("userId", id),
                get("/auth/user-details-by-userid").param("id", id));
    }

    @Test
    public void signupAndLoginReturnAToken() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        assertFalse(user.token().isBlank());

        String email = jsonMapper.readTree(mockMvc.perform(user.auth(get("/auth/user-details-by-userid")))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString()).get("data").get("email").asString();

        mockMvc.perform(TestUsers.json(post("/auth/login"), "{\"email\":\"" + email + "\",\"password\":\"CorrectHorse1\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.userId").value(user.id()))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.expiresAt").isNotEmpty());
    }

    @Test
    public void validTokenIsAcceptedOnEveryRouteGroup() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        for (MockHttpServletRequestBuilder request : routeGroups(user.id())) {
            mockMvc.perform(user.auth(request)).andExpect(status().isOk());
        }
        // With a token the user id is optional: it comes from the token.
        mockMvc.perform(user.auth(get("/tasks/get-all-tasks"))).andExpect(status().isOk());
    }

    @Test
    public void requestsWithoutATokenStillWorkWhileNotEnforced() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        for (MockHttpServletRequestBuilder request : routeGroups(user.id())) {
            mockMvc.perform(request).andExpect(status().isOk());
        }
        mockMvc.perform(get("/tasks/get-all-tasks"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Missing required parameter 'userId'"));
    }

    @Test
    public void invalidTokenIsAlways401() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        for (MockHttpServletRequestBuilder request : routeGroups(user.id())) {
            mockMvc.perform(TestUsers.bearer(request, "not-a-jwt"))
                    .andExpect(status().isUnauthorized())
                    .andExpect(header().string("WWW-Authenticate", startsWith("Bearer")))
                    .andExpect(jsonPath("$.success").value(false))
                    .andExpect(jsonPath("$.message").value("Invalid or expired token"));
        }
        // A token signed with another key is rejected too.
        String tampered = user.token().substring(0, user.token().lastIndexOf('.') + 1) + "AAAA";
        mockMvc.perform(TestUsers.bearer(get("/tasks/get-all-tasks"), tampered))
                .andExpect(status().isUnauthorized());
    }

    @Test
    public void expiredTokenIs401() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        String expired = TestUsers.expiredToken(jwtEncoder, user.id());
        mockMvc.perform(TestUsers.bearer(get("/notes/get-all-notes"), expired))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid or expired token"));
    }

    @Test
    public void loginIgnoresAStaleToken() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        String email = jsonMapper.readTree(mockMvc.perform(user.auth(get("/auth/user-details-by-userid")))
                .andReturn().getResponse().getContentAsString()).get("data").get("email").asString();

        mockMvc.perform(TestUsers.bearer(
                        TestUsers.json(post("/auth/login"), "{\"email\":\"" + email + "\",\"password\":\"CorrectHorse1\"}"),
                        TestUsers.expiredToken(jwtEncoder, user.id())))
                .andExpect(status().isOk());
    }
}
