package com.example.notes_app.auth.repository;

import com.example.notes_app.auth.model.UserModel;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthRepository extends JpaRepository<UserModel, Long> {
}
