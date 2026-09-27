package com.example.notes_app.notes.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.repository.NotesRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class NotesService {

    @Autowired
    NotesRepository notesRepository;

    @Autowired
    AuthRepository authRepository;

    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotes(long id){
        try{
            UserModel user = authRepository.findById(id).orElse(null);
            if(user == null) {  
                throw new Exception("User not found");
            }
            ApiResponse<List<NotesModel>> response = new ApiResponse<>(true, "Successfully fetched notes", user.getArticles());
            return new ResponseEntity<>(response, HttpStatus.OK);
        }catch (Exception e){
            ApiResponse<List<NotesModel>> response = new ApiResponse<>(false, "Failed to fetch user notes", null);
            return new ResponseEntity<>(response, HttpStatus.OK);
        }
    }

    public String createNote(NotesModel requestDto){
        try{
            NotesModel savedEntity = notesRepository.save(requestDto);
            return "Sucessfully created new note with id "+ savedEntity.getId();
        }catch (Exception e){
            return "Failed to crate note "+e.toString();
        }
    }
}
