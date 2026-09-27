package com.example.notes_app.auth.model;

import com.example.notes_app.notes.model.NotesModel;
import jakarta.persistence.*;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
@Entity
@Table(name = "users")
public class UserModel {

    @Id
    @Column(name = "id")
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    long id;

    @Column(name = "name")
    String name;

    @Column(name = "email")
    String email;

    @Column(name = "password")
    String password;

    @Column(name = "gender")
    String gender;

    @Column(name = "mobile")
    String mobile;

    @OneToMany(mappedBy = "user_id")
    private List<NotesModel> articles = new ArrayList<>();

}
