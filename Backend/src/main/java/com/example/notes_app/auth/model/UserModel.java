package com.example.notes_app.auth.model;

import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.tasks.model.TaskModel;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

import java.util.ArrayList;
import java.util.List;

// BE-05: no @Data. Its toString/equals/hashCode would follow the two-way
// relations (user -> notes -> user ...) and the lazy collections. Entities keep
// identity equality.
@Getter
@Setter
@ToString
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

    @ToString.Exclude
    @Column(name = "password", columnDefinition = "TEXT")
    String password;

    @Column(name = "gender", columnDefinition = "TEXT")
    String gender;

    @Column(name = "mobile", columnDefinition = "TEXT")
    String mobile;

    @ToString.Exclude
    @OneToMany(
            mappedBy = "user",
            cascade = CascadeType.REMOVE,
            orphanRemoval = true
    )
    private List<NotesModel> articles = new ArrayList<>();

    @ToString.Exclude
    @OneToMany(
            mappedBy = "user",
            cascade = CascadeType.REMOVE,
            orphanRemoval = true
    )
    private List<TaskModel> tasks = new ArrayList<>();

    @ToString.Exclude
    @OneToMany(
            mappedBy = "user",
            cascade = CascadeType.REMOVE,
            orphanRemoval = true
    )
    private List<ReminderModel> reminders = new ArrayList<>();
}
