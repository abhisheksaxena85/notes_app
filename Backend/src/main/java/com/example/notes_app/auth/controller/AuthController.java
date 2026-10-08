package com.example.notes_app.auth.controller;

import com.example.notes_app.auth.dto.request.*;
import com.example.notes_app.auth.dto.response.*;
import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.service.AuthService;
import com.example.notes_app.common.ApiResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    AuthService service;

    @GetMapping("/user-details-by-userid")
    public ResponseEntity<ApiResponse<UserDetailsResponseDto>> getUserDetails(UserDetailsRequestDto requestDto){
        return service.getUserDetails(requestDto);
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponseDto>> loginUser(@RequestBody LoginRequestDto requestDto){
        return service.login(requestDto);
    }

    @PostMapping("/create-user")
    public ResponseEntity<ApiResponse<SignupResponseDto>> createNewUser(@RequestBody SignupRequestDto requestDto){
        return service.createNewUser(requestDto);
    }

    @DeleteMapping("/delete-user")
    public ResponseEntity<ApiResponse<DeleteUserResponseDto>> deleteUser(DeleteUserRequestDto reqeustDto){
        return service.deleteUser(reqeustDto);
    }

    @PutMapping("/update-user")
    public ResponseEntity<ApiResponse<UpdateUserResponseDto>> updateUser(@RequestBody UpdateUserRequestDto requestDto){
        return service.updateUser(requestDto);
    }
}
