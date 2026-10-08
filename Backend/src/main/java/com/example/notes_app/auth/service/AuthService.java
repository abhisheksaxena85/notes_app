package com.example.notes_app.auth.service;

import com.example.notes_app.auth.dto.request.*;
import com.example.notes_app.auth.dto.response.*;
import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.PasswordHashing;
import com.example.notes_app.notes.model.NotesModel;
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
    public ResponseEntity<ApiResponse<UserDetailsResponseDto>> getUserDetails(UserDetailsRequestDto requestDto){
        ApiResponse<UserDetailsResponseDto> response;
        try{
            UserModel user = repository.findById(requestDto.getId()).orElse(null);
            if(user==null){
                throw new Exception("User Not found");
            }
            UserDetailsResponseDto responseDto = new UserDetailsResponseDto();
            responseDto.setId(user.getId());
            responseDto.setName(user.getName());
            responseDto.setEmail(user.getEmail());
            responseDto.setMobile(user.getMobile());
            responseDto.setGender(user.getGender());
            response = new ApiResponse<>(true, "User details found", responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<LoginResponseDto>> login(LoginRequestDto requestDto) {
        ApiResponse<LoginResponseDto> response;
        try{
            UserModel user = repository.findByEmail(requestDto.getEmail()).orElse(null);
            if(user==null){
                throw new Exception("User does not exists!");
            }
            boolean isValidPassword = passwordHashing.verifyPassword(requestDto.getPassword(), user.getPassword());
            if(!isValidPassword){
                throw new Exception("Password does not match!");
            }
            LoginResponseDto responseDto = new LoginResponseDto();
            responseDto.setUserId(user.getId());
            response = new ApiResponse<>(true, "User logged in successfully!", responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch(Exception e){
            response = new ApiResponse<>(false, e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<SignupResponseDto>> createNewUser(SignupRequestDto requestDto){
        ApiResponse<SignupResponseDto> response;
        try{
            String hashedPassword = passwordHashing.hashPassword(requestDto.getPassword()); // Hasing plain password
            UserModel newUser = new UserModel();
            newUser.setName(requestDto.getName());
            newUser.setEmail(requestDto.getEmail());
            newUser.setMobile(requestDto.getMobile());
            newUser.setGender(requestDto.getGender());
            newUser.setPassword(hashedPassword);
            UserModel savedUser = repository.save(newUser);

            SignupResponseDto responseDto = new SignupResponseDto();
            responseDto.setUserId(savedUser.getId());
            response = new ApiResponse<>(true, "User created successfully!",responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, "Failed to create user!",null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<DeleteUserResponseDto>> deleteUser(DeleteUserRequestDto requestDto){
        ApiResponse<DeleteUserResponseDto> response;
        try{
            UserModel user = repository.findById(requestDto.getId()).orElse(null);
            String responseMsg = "";
            if(user!=null){
                repository.deleteById(requestDto.getId());
                responseMsg = "User deleted successfully!";
            }else{
                responseMsg = "User does not exists!";
            }
            DeleteUserResponseDto responseDto = new DeleteUserResponseDto();
            responseDto.setDeleted(true);
            response = new ApiResponse<>(true, responseMsg, responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, "Failed to delete user!",null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<UpdateUserResponseDto>> updateUser(UpdateUserRequestDto requestDto){
        ApiResponse<UpdateUserResponseDto> response;
        try{
            String responseMsg = "";
            UserModel currentUser = repository.findById(requestDto.getUserId()).orElse(null);
            if(currentUser == null){
                throw new Exception("User does not exists to update details!");
            }
            currentUser.setName(requestDto.getName()!=null ? requestDto.getName(): currentUser.getName());
            currentUser.setMobile(requestDto.getMobile()!=null ? requestDto.getMobile() : currentUser.getMobile());
            currentUser.setGender(requestDto.getGender() != null ? requestDto.getGender() : currentUser.getGender());
            repository.save(currentUser);
            responseMsg = "User details updated successfully!";
            UpdateUserResponseDto responseDto = new UpdateUserResponseDto();
            responseDto.setUserId(requestDto.getUserId());
            responseDto.setName(requestDto.getName());
            responseDto.setMobile(requestDto.getMobile());
            responseDto.setGender(requestDto.getGender());
            response = new ApiResponse<>(true, responseMsg, responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch(Exception e){
            response = new ApiResponse<>(false, "Failed to update user", null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }
}
