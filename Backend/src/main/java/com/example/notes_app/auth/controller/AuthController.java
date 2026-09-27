package com.example.notes_app.auth.controller;

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

    @PostMapping("/create-user")
    public ResponseEntity<ApiResponse<String>> createNewUser(@RequestBody UserModel newUser){
        return service.createNewUser(newUser);
    }

    @DeleteMapping("/delete-user")
    public ResponseEntity<ApiResponse<String>> deleteUser(@RequestParam Long id){
        return service.deleteUser(id);
    }

    @PutMapping("/update-user")
    public ResponseEntity<ApiResponse<UserModel>> updateUser(@RequestBody UserModel newUser){
        return service.updateUser(newUser.getId(), newUser);
    }
}
