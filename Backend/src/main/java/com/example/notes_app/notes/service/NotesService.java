package com.example.notes_app.notes.service;

import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.notes.repository.NotesRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class NotesService {

    @Autowired
    NotesRepository repository;

    public List<NotesModel> getNotes(long id){
        try{
//            Optional<NotesModel> repository.findById(id);
        }catch (Exception e){
        }
            return new ArrayList<>();
    }

    public String createNote(NotesModel requestDto){
        try{
            NotesModel savedEntity = repository.save(requestDto);
            return "Sucessfully created new note with id "+ savedEntity.getId();
        }catch (Exception e){
            return "Failed to crate note "+e.toString();
        }
    }
}
