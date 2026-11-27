package com.example.notes_app.reminders.repository;

import com.example.notes_app.reminders.model.ReminderModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ReminderRepository extends JpaRepository<ReminderModel, Long> {
    Optional<ReminderModel> findByUser_IdAndClientId(long userId, String clientId);

    /** SEC-01: a reminder only if it belongs to {@code userId}. */
    Optional<ReminderModel> findByReminderIdAndUser_Id(long reminderId, long userId);

    /** BE-04: pending first, then missed, completed, rejected; earliest first within each. */
    @Query("SELECT r FROM ReminderModel r WHERE r.user.id = :userId ORDER BY CASE"
            + " WHEN r.status = com.example.notes_app.common.ItemStatus.PENDING THEN 0"
            + " WHEN r.status = com.example.notes_app.common.ItemStatus.MISSED THEN 1"
            + " WHEN r.status = com.example.notes_app.common.ItemStatus.COMPLETED THEN 2"
            + " ELSE 3 END, r.remindAt ASC")
    List<ReminderModel> findByUserId(@Param("userId") long userId);

    @Query("SELECT r FROM ReminderModel r WHERE r.user.id = :userId AND r.dueDate = :date ORDER BY r.dueTime ASC")
    List<ReminderModel> findByUserIdAndDueDate(@Param("userId") long userId, @Param("date") String date);

    @Query("SELECT r FROM ReminderModel r WHERE r.user.id = :userId AND (r.dueDate LIKE CONCAT(:monthPrefix, '%') OR (r.dueDate IS NULL AND r.remindAt LIKE CONCAT(:monthPrefix, '%')))")
    List<ReminderModel> findByUserIdAndMonth(@Param("userId") long userId, @Param("monthPrefix") String monthPrefix);
}
