package com.example.notes_app.notes.model;
import com.example.notes_app.auth.model.UserModel;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "notes", uniqueConstraints = @UniqueConstraint(
        name = "uk_notes_user_client", columnNames = {"user_id", "client_id"}))
public class NotesModel {
    @Id
    @GeneratedValue(strategy =  GenerationType.IDENTITY)
    long noteId;

    // Widened on existing databases by Flyway V3 (was VARCHAR(255)).
    @Column(name = "title", length = NoteLimits.TITLE_MAX)
    String title;

    @Column(name = "content", columnDefinition = "LONGTEXT")
    String content;

    @Column(name = "category")
    String category;

    @Column(name="isPinned")
    boolean isPinned;

    @Column(name = "tags", columnDefinition = "TEXT")
    String tags;

    @Column(name = "createdAt")
    String createdAt;

    @Column(name = "updatedAt")
    String updatedAt;

    /** FE-03: id the app generated when it queued the create; unique per user. Null for old clients. */
    @Column(name = "client_id", length = 36)
    String clientId;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private UserModel user;
}
