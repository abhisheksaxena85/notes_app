package com.example.notes_app.auth.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    @Autowired
    AuthRepository repository;

    @Transactional
    public ResponseEntity<ApiResponse<String>> createNewUser(UserModel newUser){
        try{
            repository.save(newUser);
            ApiResponse<String> response = new ApiResponse<>(true, "User created successfully!",null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            ApiResponse<String> response = new ApiResponse<>(false, "Failed to create user!",null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<String>> deleteUser(Long id){
        try{
            UserModel user = repository.findById(id).orElse(null);
            String responseMsg = "";
            if(user!=null){
                repository.deleteById(id);
                responseMsg = "User deleted successfully!";
            }else{
                responseMsg = "User does not exists!";
            }
            ApiResponse<String> response = new ApiResponse<>(true, responseMsg, null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            ApiResponse<String> response = new ApiResponse<>(false, "Failed to delete user!",null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<UserModel>> updateUser(Long id, UserModel userData){
        try{
            String responseMsg = "";
            UserModel currentUser = repository.findById(id).orElse(null);
            if(currentUser != null){
                currentUser.setName(userData.getName());
                currentUser.setMobile(userData.getMobile());
                currentUser.setGender(userData.getGender());
                repository.save(currentUser);
                responseMsg = "User details updated successfully!";
            }else{
                responseMsg = "User does not exists to update details!";
            }
            ApiResponse<UserModel> response = new ApiResponse<>(true, responseMsg, null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch(Exception e){
            ApiResponse<UserModel> response = new ApiResponse<>(false, "Failed to update user", null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }
}
