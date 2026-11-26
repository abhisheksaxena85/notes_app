package com.example.notes_app.auth.controller;

import com.example.notes_app.auth.dto.request.*;
import com.example.notes_app.auth.dto.response.*;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.exception.BadRequestException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    AuthService service;

    @GetMapping("/user-details-by-userid")
    public ResponseEntity<ApiResponse<UserDetailsResponseDto>> getUserDetails(
            @RequestParam(name = "id", required = false) Long paramId,
            UserDetailsRequestDto requestDto) {
        if (paramId != null) {
            requestDto = new UserDetailsRequestDto();
            requestDto.setId(paramId);
        }
        return service.getUserDetails(requestDto);
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponseDto>> loginUser(@RequestBody LoginRequestDto requestDto) {
        return service.login(requestDto);
    }

    @PostMapping("/create-user")
    public ResponseEntity<ApiResponse<SignupResponseDto>> createNewUser(@RequestBody SignupRequestDto requestDto) {
        return service.createNewUser(requestDto);
    }

    @DeleteMapping("/delete-user")
    public ResponseEntity<ApiResponse<DeleteUserResponseDto>> deleteUser(
            @RequestParam(name = "id", required = false) Long paramId,
            @RequestBody(required = false) DeleteUserRequestDto bodyDto) {
        DeleteUserRequestDto requestDto = new DeleteUserRequestDto();
        if (paramId != null) {
            requestDto.setId(paramId);
        } else if (bodyDto != null) {
            requestDto.setId(bodyDto.getId());
        } else {
            throw new BadRequestException("User id is required");
        }
        return service.deleteUser(requestDto);
    }

    @PutMapping("/update-user")
    public ResponseEntity<ApiResponse<UpdateUserResponseDto>> updateUser(@RequestBody UpdateUserRequestDto requestDto) {
        return service.updateUser(requestDto);
    }

    @PutMapping("/change-password")
    public ResponseEntity<ApiResponse<Boolean>> changePassword(@RequestBody ChangePasswordRequestDto requestDto) {
        return service.changePassword(requestDto);
    }
}
