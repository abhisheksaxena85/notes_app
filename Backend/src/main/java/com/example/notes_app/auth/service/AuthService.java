package com.example.notes_app.auth.service;

import com.example.notes_app.auth.dto.request.*;
import com.example.notes_app.auth.dto.response.*;
import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.PasswordHashing;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.common.exception.ConflictException;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.common.exception.UnauthorizedException;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AuthService {
    @Autowired
    AuthRepository repository;

    @Autowired
    PasswordHashing passwordHashing;

    static final String INVALID_CREDENTIALS = "Invalid email or password";
    static final String EMAIL_IN_USE = "Email id already used by another user";

    private volatile String dummyPasswordHash;

    /** A real BCrypt hash to compare against when the email is unknown. */
    private String dummyPasswordHash() {
        String hash = dummyPasswordHash;
        if (hash == null) {
            hash = passwordHashing.hashPassword(UUID.randomUUID().toString());
            dummyPasswordHash = hash;
        }
        return hash;
    }

    @Transactional
    public ResponseEntity<ApiResponse<UserDetailsResponseDto>> getUserDetails(UserDetailsRequestDto requestDto) {
        UserModel user = repository.findById(requestDto.getId())
                .orElseThrow(() -> new NotFoundException("User not found"));
        UserDetailsResponseDto responseDto = new UserDetailsResponseDto();
        responseDto.setId(user.getId());
        responseDto.setName(user.getName());
        responseDto.setEmail(user.getEmail());
        responseDto.setMobile(user.getMobile());
        responseDto.setGender(user.getGender());
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "User details found", responseDto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<LoginResponseDto>> login(LoginRequestDto requestDto) {
        UserModel user = repository.findByEmail(EmailNormalizer.normalize(requestDto.getEmail())).orElse(null);
        // Unknown email and wrong password must be indistinguishable (same status,
        // message and roughly the same time), so a hash check runs either way.
        String hashToCheck = user != null ? user.getPassword() : dummyPasswordHash();
        boolean isValidPassword = passwordHashing.verifyPassword(requestDto.getPassword(), hashToCheck);
        if (user == null || !isValidPassword) {
            throw new UnauthorizedException(INVALID_CREDENTIALS);
        }
        LoginResponseDto responseDto = new LoginResponseDto();
        responseDto.setUserId(user.getId());
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "User logged in successfully!", responseDto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<SignupResponseDto>> createNewUser(SignupRequestDto requestDto) {
        String email = EmailNormalizer.normalize(requestDto.getEmail());
        if (repository.findByEmail(email).isPresent()) {
            throw new ConflictException(EMAIL_IN_USE);
        }

        String hashedPassword = passwordHashing.hashPassword(requestDto.getPassword());
        UserModel newUser = new UserModel();
        newUser.setName(requestDto.getName());
        newUser.setEmail(email);
        newUser.setMobile(requestDto.getMobile());
        newUser.setGender(requestDto.getGender());
        newUser.setPassword(hashedPassword);
        UserModel savedUser;
        try {
            // Flush now so a concurrent signup that slipped past the check above
            // hits the unique index here and becomes a 409, not a 500.
            savedUser = repository.saveAndFlush(newUser);
        } catch (DataIntegrityViolationException e) {
            throw new ConflictException(EMAIL_IN_USE);
        }

        SignupResponseDto responseDto = new SignupResponseDto();
        responseDto.setUserId(savedUser.getId());
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "User created successfully!", responseDto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<DeleteUserResponseDto>> deleteUser(DeleteUserRequestDto requestDto) {
        if (!repository.existsById(requestDto.getId())) {
            throw new NotFoundException("User not found");
        }
        repository.deleteById(requestDto.getId());
        DeleteUserResponseDto responseDto = new DeleteUserResponseDto();
        responseDto.setDeleted(true);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "User deleted successfully!", responseDto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<UpdateUserResponseDto>> updateUser(UpdateUserRequestDto requestDto) {
        UserModel currentUser = repository.findById(requestDto.getUserId())
                .orElseThrow(() -> new NotFoundException("User not found"));
        currentUser.setName(requestDto.getName() != null ? requestDto.getName() : currentUser.getName());
        currentUser.setMobile(requestDto.getMobile() != null ? requestDto.getMobile() : currentUser.getMobile());
        currentUser.setGender(requestDto.getGender() != null ? requestDto.getGender() : currentUser.getGender());
        repository.save(currentUser);
        UpdateUserResponseDto responseDto = new UpdateUserResponseDto();
        responseDto.setUserId(requestDto.getUserId());
        responseDto.setName(requestDto.getName());
        responseDto.setMobile(requestDto.getMobile());
        responseDto.setGender(requestDto.getGender());
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "User details updated successfully!", responseDto));
    }

    @Transactional
    public ResponseEntity<ApiResponse<Boolean>> changePassword(ChangePasswordRequestDto requestDto) {
        UserModel user = repository.findById(requestDto.getUserId())
                .orElseThrow(() -> new NotFoundException("User not found"));
        boolean isValidPassword = passwordHashing.verifyPassword(requestDto.getOldPassword(), user.getPassword());
        if (!isValidPassword) {
            // 400, not 401: the caller is known, only the confirmation input is wrong.
            throw new BadRequestException("Old password does not match!");
        }
        user.setPassword(passwordHashing.hashPassword(requestDto.getNewPassword()));
        repository.save(user);
        return ResponseEntity.status(HttpStatus.OK)
                .body(new ApiResponse<>(true, "Password changed successfully!", true));
    }
}
