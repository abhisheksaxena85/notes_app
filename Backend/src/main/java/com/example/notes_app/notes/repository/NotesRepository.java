package com.example.notes_app.notes.repository;

import com.example.notes_app.notes.model.NotesModel;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotesRepository extends JpaRepository<NotesModel, Long> {
}
