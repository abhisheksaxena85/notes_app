package com.example.notes_app.auth.repository;

import com.example.notes_app.auth.model.UserModel;
import jakarta.persistence.Id;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;

public interface AuthRepository extends JpaRepository<UserModel, Long> {
    Optional<UserModel> findByEmail(String email);
}
