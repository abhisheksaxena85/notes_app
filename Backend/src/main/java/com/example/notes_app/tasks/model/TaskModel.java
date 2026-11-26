package com.example.notes_app.tasks.model;

import com.example.notes_app.auth.model.UserModel;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Entity
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "tasks", uniqueConstraints = @UniqueConstraint(
        name = "uk_tasks_user_client", columnNames = {"user_id", "client_id"}))
public class TaskModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long taskId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "due_date")
    private String dueDate; // Format: YYYY-MM-DD

    @Column(name = "due_time")
    private String dueTime; // Format: HH:mm

    @Column(name = "category")
    private String category;

    @Column(name = "priority")
    private String priority; // LOW, MEDIUM, HIGH

    @Column(name = "status", nullable = false)
    private String status; // PENDING, COMPLETED, REJECTED, MISSED

    @Column(name = "is_completed", nullable = false)
    private boolean isCompleted;

    @Column(name = "created_at")
    private String createdAt;

    @Column(name = "updated_at")
    private String updatedAt;

    /** FE-03: id the app generated when it queued the create; unique per user. Null for old clients. */
    @Column(name = "client_id", length = 36)
    private String clientId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    @JsonIgnore
    private UserModel user;
}
