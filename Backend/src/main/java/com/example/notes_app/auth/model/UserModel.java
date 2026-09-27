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
    @Column(name = "id" )
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    long id;

    @Column(name = "name", columnDefinition = "TEXT")
    String name;

    @Column(name = "email", columnDefinition = "TEXT")
    String email;

    @Column(name = "password", columnDefinition = "TEXT")
    String password;

    @Column(name = "gender", columnDefinition = "TEXT")
    String gender;

    @Column(name = "mobile", columnDefinition = "TEXT")
    String mobile;

    @OneToMany(
            mappedBy = "user",
            cascade = CascadeType.REMOVE,
            orphanRemoval = true
    )
    private List<NotesModel> articles = new ArrayList<>();
}
