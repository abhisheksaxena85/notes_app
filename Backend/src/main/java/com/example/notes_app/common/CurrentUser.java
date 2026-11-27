package com.example.notes_app.common;

import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.common.exception.UnauthorizedException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.Optional;

/**
 * SEC-01: who the request acts for.
 *
 * <p>With a valid bearer token the user always comes from the token. A
 * {@code userId} the client still sends is only checked against it: a
 * different id is someone else's data and gets 404.
 *
 * <p>Without a token (only possible while {@code AUTH_ENFORCED=false}, for
 * app builds that predate tokens) the request keeps working as before: the
 * user is the {@code userId} it sends and by-id routes are not owner-scoped.
 */
@Component
public class CurrentUser {

    private final boolean authEnforced;

    public CurrentUser(@Value("${app.auth.enforced:false}") boolean authEnforced) {
        this.authEnforced = authEnforced;
    }

    /** The user id in the request's bearer token, if it has one. */
    public Optional<Long> tokenUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication instanceof JwtAuthenticationToken jwt) {
            // JwtConfig only accepts tokens with a positive numeric subject.
            return Optional.of(Long.parseLong(jwt.getToken().getSubject()));
        }
        return Optional.empty();
    }

    /**
     * Owner to scope by-id lookups to: the token's user, or {@code null} for a
     * legacy request without a token (no ownership check is possible then).
     */
    public Long ownerScope() {
        return tokenUserId().orElseGet(() -> {
            requireLegacyAllowed();
            return null;
        });
    }

    /**
     * The user a list/create/profile request acts for.
     *
     * @param requested the {@code userId} the client sent ({@code null} or 0 = not sent;
     *                  a JSON body without it binds to 0)
     * @param paramName its name, for the "missing parameter" message of legacy requests
     */
    public long resolve(Long requested, String paramName) {
        Optional<Long> fromToken = tokenUserId();
        if (fromToken.isPresent()) {
            long userId = fromToken.get();
            if (requested != null && requested != 0 && requested != userId) {
                throw new NotFoundException("User not found");
            }
            return userId;
        }
        requireLegacyAllowed();
        if (requested == null || requested == 0) {
            throw new BadRequestException("Missing required parameter '" + paramName + "'");
        }
        return requested;
    }

    private void requireLegacyAllowed() {
        // Security already rejects token-less data requests when enforced; this
        // guards any route that slips through the matcher list.
        if (authEnforced) {
            throw new UnauthorizedException("Authentication required");
        }
    }
}
