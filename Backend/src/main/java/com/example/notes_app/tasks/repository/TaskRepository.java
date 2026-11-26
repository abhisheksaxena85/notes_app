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

    @Query("SELECT t FROM TaskModel t WHERE t.user.id = :userId AND (t.dueDate LIKE CONCAT(:monthPrefix, '%') OR (t.dueDate IS NULL AND t.createdAt LIKE CONCAT(:monthPrefix, '%')))")
    List<TaskModel> findByUserIdAndMonth(@Param("userId") long userId, @Param("monthPrefix") String monthPrefix);
}
