package com.example.notes_app.auth.service;

import com.example.notes_app.auth.model.LoginModel;
import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.PasswordHashing;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
    @Autowired
    AuthRepository repository;

    @Autowired
    PasswordHashing passwordHashing;

    @Transactional
    public ResponseEntity<ApiResponse<UserModel>> login(LoginModel loginModel) {
        ApiResponse<UserModel> response;
        try{
            UserModel user = repository.findByEmail(loginModel.getEmail()).orElse(null);
            if(user==null){
                throw new Exception("User does not exists!");
            }
            boolean isValidPassword = passwordHashing.verifyPassword(loginModel.getPassword(), user.getPassword());
            if(!isValidPassword){
                throw new Exception("Password does not match!");
            }

            response = new ApiResponse<>(true, "User logged in successfully!", user);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch(Exception e){
            response = new ApiResponse<>(true, e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<String>> createNewUser(UserModel newUser){
        ApiResponse<String> response;
        try{
            String hashedPassword = passwordHashing.hashPassword(newUser.getPassword()); // Hasing plain password
            newUser.setPassword(hashedPassword);
            repository.save(newUser);
            response = new ApiResponse<>(true, "User created successfully!",null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, "Failed to create user!",null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<String>> deleteUser(Long id){
        ApiResponse<String> response;
        try{
            UserModel user = repository.findById(id).orElse(null);
            String responseMsg = "";
            if(user!=null){
                repository.deleteById(id);
                responseMsg = "User deleted successfully!";
            }else{
                responseMsg = "User does not exists!";
            }
            response = new ApiResponse<>(true, responseMsg, null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, "Failed to delete user!",null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<UserModel>> updateUser(Long id, UserModel userData){
        ApiResponse<UserModel> response;
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
            response = new ApiResponse<>(true, responseMsg, null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch(Exception e){
            response = new ApiResponse<>(false, "Failed to update user", null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }
}
