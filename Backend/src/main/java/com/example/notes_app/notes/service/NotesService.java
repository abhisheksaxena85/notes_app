package com.example.notes_app.notes.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.repository.NotesRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class NotesService {

    @Autowired
    NotesRepository notesRepository;

    @Autowired
    AuthRepository authRepository;

    @Transactional
    public ResponseEntity<ApiResponse<List<NotesModel>>> getNotes(long id){
        ApiResponse<List<NotesModel>> response;
        try{
            UserModel user = authRepository.findById(id).orElse(null);
            if(user == null) {  
                throw new Exception("User not found");
            }
            response = new ApiResponse<>(true, "Successfully fetched notes", user.getArticles());
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, "Failed to fetch user notes "+e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> createNote(long userId, NotesModel requestDto){
        ApiResponse<NotesModel> response;
        try{
            UserModel user = authRepository.findById(userId).orElse(null);
            if(user == null) {
                throw new Exception("User not found");
            }
            requestDto.setUser(user);
            requestDto.setCreatedAt(LocalDateTime.now().toString());
            requestDto.setUpdatedAt(LocalDateTime.now().toString());
            NotesModel savedEntity = notesRepository.save(requestDto);
            response = new ApiResponse<>(true, "Note saved successfully!", savedEntity);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(true, "Failed to save note! "+e.getMessage(), null);
            return  ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> updateNote(long id, NotesModel updatedNote){
        ApiResponse<NotesModel> response;
        try{
            NotesModel currentNote = notesRepository.findById(id).orElse(null);
            if(currentNote==null){
                throw new Exception("Note does not exists!");
            }
            currentNote.setTitle(updatedNote.getTitle());
            currentNote.setContent(updatedNote.getContent());
            currentNote.setUpdatedAt(LocalDateTime.now().toString());
            currentNote.setCategory(updatedNote.getCategory());
            currentNote.setPinned(updatedNote.isPinned());
            notesRepository.save(currentNote);

            response = new ApiResponse<>(true, "Successfully updated note!", currentNote);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch(Exception e){
            response = new ApiResponse<>(true, "Failed to update note! "+e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<NotesModel>> deleteNote(long id){
        ApiResponse<NotesModel> response;
        try{
            NotesModel currentNote = notesRepository.findById(id).orElse(null);
            if(currentNote==null){
                throw new Exception("Note does not exists!");
            }
            notesRepository.deleteById(id);
            response = new ApiResponse<>(true, "Successfully deleted note", currentNote);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        } catch (Exception e) {
            response = new ApiResponse<>(true, "Failed to delete note "+e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }
}
