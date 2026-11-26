package com.example.notes_app.reminders.model;

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
@Table(name = "reminders", uniqueConstraints = @UniqueConstraint(
        name = "uk_reminders_user_client", columnNames = {"user_id", "client_id"}))
public class ReminderModel {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long reminderId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "remind_at", nullable = false)
    private String remindAt; // Format: YYYY-MM-DDTHH:mm:ss

    @Column(name = "due_date")
    private String dueDate; // Format: YYYY-MM-DD

    @Column(name = "due_time")
    private String dueTime; // Format: HH:mm

    @Column(name = "category")
    private String category;

    @Column(name = "status", nullable = false)
    private String status; // PENDING, COMPLETED, REJECTED, MISSED

    @Column(name = "repeat_interval")
    private String repeatInterval; // NONE, DAILY, WEEKLY, MONTHLY

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
