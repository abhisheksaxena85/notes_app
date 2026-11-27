package com.example.notes_app.auth.controller;

import com.example.notes_app.auth.dto.request.*;
import com.example.notes_app.auth.dto.response.*;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.auth.service.EmailNormalizer;
import com.example.notes_app.auth.service.LoginRateLimiter;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.CurrentUser;
import com.example.notes_app.common.exception.UnauthorizedException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    AuthService service;

    @Autowired
    LoginRateLimiter loginRateLimiter;

    @Autowired
    CurrentUser currentUser;

    // SEC-01: the profile routes below act only on the token's user. The id the
    // client still sends must match it (else 404); old token-less builds keep
    // passing the id while AUTH_ENFORCED is false.

    @GetMapping("/user-details-by-userid")
    public ResponseEntity<ApiResponse<UserDetailsResponseDto>> getUserDetails(
            @RequestParam(name = "id", required = false) Long paramId,
            UserDetailsRequestDto requestDto) {
        Long requested = paramId != null ? paramId : requestDto.getId();
        UserDetailsRequestDto resolved = new UserDetailsRequestDto();
        resolved.setId(currentUser.resolve(requested, "id"));
        return service.getUserDetails(resolved);
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponseDto>> loginUser(
            @Valid @RequestBody LoginRequestDto requestDto, HttpServletRequest request) {
        String clientIp = request.getRemoteAddr();
        String email = EmailNormalizer.normalize(requestDto.getEmail());
        loginRateLimiter.checkAllowed(clientIp, email);
        try {
            ResponseEntity<ApiResponse<LoginResponseDto>> response = service.login(requestDto);
            loginRateLimiter.recordSuccess(email);
            return response;
        } catch (UnauthorizedException e) {
            loginRateLimiter.recordFailure(clientIp, email);
            throw e;
        }
    }

    @PostMapping("/create-user")
    public ResponseEntity<ApiResponse<SignupResponseDto>> createNewUser(@Valid @RequestBody SignupRequestDto requestDto) {
        return service.createNewUser(requestDto);
    }

    @DeleteMapping("/delete-user")
    public ResponseEntity<ApiResponse<DeleteUserResponseDto>> deleteUser(
            @RequestParam(name = "id", required = false) Long paramId,
            @RequestBody(required = false) DeleteUserRequestDto bodyDto) {
        Long requested = paramId != null ? paramId : (bodyDto != null ? Long.valueOf(bodyDto.getId()) : null);
        DeleteUserRequestDto requestDto = new DeleteUserRequestDto();
        requestDto.setId(currentUser.resolve(requested, "id"));
        return service.deleteUser(requestDto);
    }

    @PutMapping("/update-user")
    public ResponseEntity<ApiResponse<UpdateUserResponseDto>> updateUser(@Valid @RequestBody UpdateUserRequestDto requestDto) {
        requestDto.setUserId(currentUser.resolve(requestDto.getUserId(), "userId"));
        return service.updateUser(requestDto);
    }

    @PutMapping("/change-password")
    public ResponseEntity<ApiResponse<Boolean>> changePassword(@Valid @RequestBody ChangePasswordRequestDto requestDto) {
        requestDto.setUserId(currentUser.resolve(requestDto.getUserId(), "userId"));
        return service.changePassword(requestDto);
    }
}
