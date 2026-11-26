package com.example.notes_app.tasks.repository;

import com.example.notes_app.tasks.model.TaskModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TaskRepository extends JpaRepository<TaskModel, Long> {
    Optional<TaskModel> findByUser_IdAndClientId(long userId, String clientId);

    @Query("SELECT t FROM TaskModel t WHERE t.user.id = :userId ORDER BY t.isCompleted ASC, t.dueDate ASC, t.createdAt DESC")
    List<TaskModel> findByUserId(@Param("userId") long userId);

    @Query("SELECT t FROM TaskModel t WHERE t.user.id = :userId AND t.dueDate = :date ORDER BY t.isCompleted ASC, t.dueTime ASC")
    List<TaskModel> findByUserIdAndDueDate(@Param("userId") long userId, @Param("date") String date);

    /**
     * Calendar candidates: tasks due in the period ({@code datePrefix} is a
     * month {@code YYYY-MM} or a day), plus every task without a due date.
     * Undated tasks are bucketed by their createdAt in the caller's time zone,
     * which SQL can't do on the stored strings, so the caller filters them.
     */
    @Query("SELECT t FROM TaskModel t WHERE t.user.id = :userId AND (t.dueDate LIKE CONCAT(:datePrefix, '%') OR t.dueDate IS NULL OR LENGTH(t.dueDate) < 10)")
    List<TaskModel> findDueInPeriodOrUndated(@Param("userId") long userId, @Param("datePrefix") String datePrefix);
}
