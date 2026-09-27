package com.example.notes_app.notes.model;
import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "notes")
public class NotesModel {
    @Id
    @GeneratedValue(strategy =  GenerationType.IDENTITY)
    long id;

    @Column(name = "title")
    String title;

    @Column(name = "content")
    String content;

    @Column(name = "category")
    String category;

    @Column(name="isPinned")
    boolean isPinned;

    @Column(name = "createdAt")
    String createdAt;

    @Column(name = "updatedAt")
    String updatedAt;
}
