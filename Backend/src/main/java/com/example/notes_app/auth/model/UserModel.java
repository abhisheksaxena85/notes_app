package com.example.notes_app.auth.model;

import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.tasks.model.TaskModel;
import jakarta.persistence.*;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
@Entity
// The unique index is created by Flyway migration V2 on existing databases; the
// name must match so Hibernate's ddl-auto=update sees it and doesn't add another.
@Table(name = "users", uniqueConstraints = @UniqueConstraint(name = "uk_users_email", columnNames = "email"))
public class UserModel {

    @Id
    @Column(name = "id" )
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    long id;

    @Column(name = "name", columnDefinition = "TEXT")
    String name;

    /** Always stored trimmed and lower-cased (see EmailNormalizer). 320 = max email length. */
    @Column(name = "email", length = 320)
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

    @OneToMany(
            mappedBy = "user",
            cascade = CascadeType.REMOVE,
            orphanRemoval = true
    )
    private List<TaskModel> tasks = new ArrayList<>();

    @OneToMany(
            mappedBy = "user",
            cascade = CascadeType.REMOVE,
            orphanRemoval = true
    )
    private List<ReminderModel> reminders = new ArrayList<>();
}
