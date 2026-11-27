package com.example.notes_app.tasks.model;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.common.ItemStatus;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

// BE-05: no @Data (see UserModel). toString skips the user; identity equality.
@Getter
@Setter
@ToString
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

    // BE-04: enums stored by name in a VARCHAR column (see ReminderModel).
    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "priority")
    private Priority priority;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(name = "status", nullable = false)
    private ItemStatus status;

    /** Always {@code status == COMPLETED}; set only by TaskService.applyStatus. */
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
    @ToString.Exclude
    private UserModel user;
}
