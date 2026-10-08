package com.example.notes_app.notes.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.notes.dto.request.CreateNoteRequestDto;
import com.example.notes_app.notes.dto.request.UpdateNoteRequestDto;
import com.example.notes_app.notes.dto.response.CreateNoteResponseDto;
import com.example.notes_app.notes.dto.response.UpdateNoteResponseDto;
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
    public ResponseEntity<ApiResponse<NotesModel>> getNoteDetails(long noteId){
        ApiResponse<NotesModel> response;
        try{
            NotesModel currentNote = notesRepository.findById(noteId).orElse(null);
            if(currentNote==null){
                throw new Exception("Invalid id, not found in database");
            }
            response = new ApiResponse<>(true, "Successfully fetched the details", currentNote);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

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
    public ResponseEntity<ApiResponse<CreateNoteResponseDto>> createNote(CreateNoteRequestDto requestDto){
        ApiResponse<CreateNoteResponseDto> response;
        try{
            UserModel user = authRepository.findById(requestDto.getUserId()).orElse(null);
            if(user == null) {
                throw new Exception("User not found");
            }
            NotesModel newNote = new NotesModel();
            newNote.setTitle(requestDto.getTitle());
            newNote.setContent(requestDto.getContent());
            newNote.setCategory(requestDto.getCategory());
            newNote.setPinned(requestDto.isPinned());
            newNote.setUser(user);
            newNote.setCreatedAt(LocalDateTime.now().toString());
            newNote.setUpdatedAt(LocalDateTime.now().toString());


            NotesModel savedEntity = notesRepository.save(newNote);

            CreateNoteResponseDto responseDto = new CreateNoteResponseDto();
            responseDto.setNoteId(savedEntity.getNoteId());

            response = new ApiResponse<>(true, "Note saved successfully!", responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch (Exception e){
            response = new ApiResponse<>(false, "Failed to save note! "+e.getMessage(), null);
            return  ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<UpdateNoteResponseDto>> updateNote(UpdateNoteRequestDto requestDto){
        ApiResponse<UpdateNoteResponseDto> response;
        try{
            NotesModel currentNote = notesRepository.findById(requestDto.getNoteId()).orElse(null);
            if(currentNote==null){
                throw new Exception("Note does not exists!");
            }
            currentNote.setTitle(requestDto.getTitle());
            currentNote.setContent(requestDto.getContent());
            currentNote.setUpdatedAt(LocalDateTime.now().toString());
            currentNote.setCategory(requestDto.getCategory());
            currentNote.setPinned(requestDto.isPinned());
            notesRepository.save(currentNote);

            UpdateNoteResponseDto responseDto = new UpdateNoteResponseDto();
            responseDto.setNoteId(currentNote.getNoteId());
            responseDto.setTitle(currentNote.getTitle());
            responseDto.setContent(currentNote.getContent());
            responseDto.setCategory(currentNote.getCategory());
            responseDto.setCreatedAt(currentNote.getCreatedAt());
            responseDto.setUpdateAt(currentNote.getUpdatedAt());
            responseDto.setPinned(currentNote.isPinned());

            response = new ApiResponse<>(true, "Successfully updated note!", responseDto);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }catch(Exception e){
            response = new ApiResponse<>(false, "Failed to update note! "+e.getMessage(), null);
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
            response = new ApiResponse<>(false, "Failed to delete note "+e.getMessage(), null);
            return ResponseEntity.status(HttpStatus.OK).body(response);
        }
    }
}
