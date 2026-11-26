package com.example.notes_app;

import com.example.notes_app.auth.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** SEC-05: enumeration, email uniqueness, input validation and login rate limiting. */
@SpringBootTest
@AutoConfigureMockMvc
public class AuthHardeningTests {

    @Autowired
    private MockMvc mockMvc;

    @MockitoSpyBean
    private AuthService authService;

    private static String uniqueEmail() {
        return "sec05_" + UUID.randomUUID() + "@example.com";
    }

    private static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder builder, String body) {
        return builder.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private static String signupBody(String email, String password) {
        return "{\"name\":\"Sec\",\"email\":\"" + email + "\",\"password\":\"" + password + "\"}";
    }

    private static String loginBody(String email, String password) {
        return "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}";
    }

    private static MockHttpServletRequestBuilder fromIp(MockHttpServletRequestBuilder builder, String ip) {
        return builder.with(request -> {
            request.setRemoteAddr(ip);
            return request;
        });
    }

    @Test
    public void unknownEmailAndWrongPasswordLookIdentical() throws Exception {
        String email = uniqueEmail();
        mockMvc.perform(json(post("/auth/create-user"), signupBody(email, "CorrectHorse1")))
                .andExpect(status().isOk());

        String unknown = mockMvc.perform(fromIp(json(post("/auth/login"), loginBody(uniqueEmail(), "CorrectHorse1")), "10.0.0.1"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email or password"))
                .andReturn().getResponse().getContentAsString();
        String wrongPassword = mockMvc.perform(fromIp(json(post("/auth/login"), loginBody(email, "WrongHorse99")), "10.0.0.1"))
                .andExpect(status().isUnauthorized())
                .andReturn().getResponse().getContentAsString();

        assertEquals(unknown, wrongPassword);
    }

    @Test
    public void emailsAreCaseInsensitiveAndUnique() throws Exception {
        String email = uniqueEmail();
        mockMvc.perform(json(post("/auth/create-user"), signupBody(email, "CorrectHorse1")))
                .andExpect(status().isOk());

        mockMvc.perform(json(post("/auth/create-user"), signupBody("  " + email.toUpperCase() + " ", "CorrectHorse1")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Email id already used by another user"));

        mockMvc.perform(fromIp(json(post("/auth/login"), loginBody(email.toUpperCase(), "CorrectHorse1")), "10.0.0.2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }

    @Test
    public void passwordsAreNotTrimmed() throws Exception {
        String email = uniqueEmail();
        mockMvc.perform(json(post("/auth/create-user"), signupBody(email, " spaced pass ")))
                .andExpect(status().isOk());

        mockMvc.perform(fromIp(json(post("/auth/login"), loginBody(email, "spaced pass")), "10.0.0.3"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(fromIp(json(post("/auth/login"), loginBody(email, " spaced pass ")), "10.0.0.3"))
                .andExpect(status().isOk());
    }

    @Test
    public void invalidSignupReturns400WithFieldErrorsAndNeverReachesTheService() throws Exception {
        mockMvc.perform(json(post("/auth/create-user"), "{\"name\":\"\",\"email\":\"not-an-email\",\"password\":\"short\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.data.name").value("Name is required"))
                .andExpect(jsonPath("$.data.email").value("Enter a valid email address"))
                .andExpect(jsonPath("$.data.password").value("Password must be between 8 and 72 characters"));

        mockMvc.perform(json(post("/auth/create-user"), "{\"name\":\"N\",\"email\":\"a@b.com\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.password").value("Password is required"));

        verify(authService, never()).createNewUser(any());
    }

    @Test
    public void invalidLoginAndChangePasswordReturn400() throws Exception {
        mockMvc.perform(json(post("/auth/login"), "{\"email\":\"a@b.com\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.password").value("Password is required"));

        mockMvc.perform(json(put("/auth/change-password"), "{\"userId\":1,\"oldPassword\":\"old\",\"newPassword\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.newPassword").exists());

        verify(authService, never()).login(any());
        verify(authService, never()).changePassword(any());
    }

    @Test
    public void repeatedFailuresForOneEmailAreRateLimited() throws Exception {
        String email = uniqueEmail();
        mockMvc.perform(json(post("/auth/create-user"), signupBody(email, "CorrectHorse1")))
                .andExpect(status().isOk());

        for (int i = 0; i < 10; i++) {
            mockMvc.perform(fromIp(json(post("/auth/login"), loginBody(email, "WrongHorse" + i)), "10.0.0.4"))
                    .andExpect(status().isUnauthorized());
        }
        // Even the right password is refused while the email is locked.
        mockMvc.perform(fromIp(json(post("/auth/login"), loginBody(email, "CorrectHorse1")), "10.0.0.5"))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.message").value("Too many failed login attempts. Please try again later."));
    }
}
