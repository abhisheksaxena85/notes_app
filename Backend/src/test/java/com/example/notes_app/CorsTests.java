package com.example.notes_app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.test.web.servlet.MockMvc;
import tools.jackson.databind.json.JsonMapper;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * The account-deletion page (Website/, on GitHub Pages) calls the API from the
 * browser. Checked with AUTH_ENFORCED=true, where a token-less preflight would
 * otherwise be rejected before CORS runs.
 */
@SpringBootTest(properties = "app.auth.enforced=true")
@AutoConfigureMockMvc
public class CorsTests {

    private static final String PAGES_ORIGIN = "https://abhisheksaxena85.github.io";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JsonMapper jsonMapper;

    @Test
    public void preflightFromPagesOriginIsAllowedWithoutAToken() throws Exception {
        for (String[] route : new String[][]{{"/auth/login", "POST"}, {"/auth/delete-user", "DELETE"}}) {
            mockMvc.perform(options(route[0])
                            .header(HttpHeaders.ORIGIN, PAGES_ORIGIN)
                            .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, route[1])
                            .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "authorization,content-type"))
                    .andExpect(status().isOk())
                    .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, PAGES_ORIGIN));
        }
    }

    @Test
    public void deleteFromPagesOriginWorksAndCarriesCorsHeaders() throws Exception {
        TestUsers.User user = TestUsers.signUp(mockMvc, jsonMapper);
        // The page's request, same as the app's ApiClient.deleteUser: ?id=<userId> plus the bearer token.
        mockMvc.perform(user.auth(delete("/auth/delete-user").param("id", Long.toString(user.id())))
                        .header(HttpHeaders.ORIGIN, PAGES_ORIGIN))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, PAGES_ORIGIN));
        // The token's user is gone.
        mockMvc.perform(user.auth(get("/auth/user-details-by-userid")))
                .andExpect(status().isNotFound());
    }

    @Test
    public void unknownOriginIsRejected() throws Exception {
        mockMvc.perform(options("/auth/delete-user")
                        .header(HttpHeaders.ORIGIN, "https://evil.example")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "DELETE"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN));
    }
}
