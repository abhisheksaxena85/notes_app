package com.example.notes_app.tasks.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.IdempotentCreate;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.tasks.dto.request.CreateTaskRequestDto;
import com.example.notes_app.tasks.dto.request.UpdateTaskRequestDto;
import com.example.notes_app.tasks.dto.response.CreateTaskResponseDto;
import com.example.notes_app.tasks.model.TaskModel;
import com.example.notes_app.tasks.repository.TaskRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class TaskService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private AuthRepository authRepository;

    private TaskModel requireTask(long taskId) {
        return taskRepository.findById(taskId)
                .orElseThrow(() -> new NotFoundException("Task not found"));
    }

    /**
     * Not @Transactional on purpose: see {@link IdempotentCreate}. A repeat with
     * the same clientId returns the existing task with 200 instead of 201.
     */
    public ResponseEntity<ApiResponse<CreateTaskResponseDto>> createTask(CreateTaskRequestDto requestDto) {
        UserModel user = authRepository.findById(requestDto.getUserId())
                .orElseThrow(() -> new NotFoundException("User not found"));
        String clientId = IdempotentCreate.normalize(requestDto.getClientId());

        IdempotentCreate.Result<TaskModel> result = IdempotentCreate.createOnce(
                clientId,
                () -> taskRepository.findByUser_IdAndClientId(user.getId(), clientId),
                () -> taskRepository.save(newTask(requestDto, user, clientId)));

        if (!result.created()) {
            return ResponseEntity.ok(new ApiResponse<>(true, "Task already created",
                    new CreateTaskResponseDto(result.entity().getTaskId())));
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, "Task created successfully",
                        new CreateTaskResponseDto(result.entity().getTaskId())));
    }

    private static TaskModel newTask(CreateTaskRequestDto requestDto, UserModel user, String clientId) {
        TaskModel task = new TaskModel();
        task.setTitle(requestDto.getTitle());
        task.setDescription(requestDto.getDescription());
        task.setDueDate(requestDto.getDueDate());
        task.setDueTime(requestDto.getDueTime());
        task.setCategory(requestDto.getCategory() != null ? requestDto.getCategory() : "General");
        task.setPriority(requestDto.getPriority() != null ? requestDto.getPriority() : "MEDIUM");
        task.setStatus(requestDto.getStatus() != null ? requestDto.getStatus() : "PENDING");
        task.setCompleted(requestDto.isCompleted());
        task.setCreatedAt(LocalDateTime.now().toString());
        task.setUpdatedAt(LocalDateTime.now().toString());
        task.setUser(user);
        task.setClientId(clientId);
        return task;
    }

    public ResponseEntity<ApiResponse<List<TaskModel>>> getAllTasks(long userId) {
        List<TaskModel> tasks = taskRepository.findByUserId(userId);
        return ResponseEntity.ok(new ApiResponse<>(true, "Tasks fetched successfully", tasks));
    }

    public ResponseEntity<ApiResponse<List<TaskModel>>> getTasksByDate(long userId, String date) {
        List<TaskModel> tasks = taskRepository.findByUserIdAndDueDate(userId, date);
        return ResponseEntity.ok(new ApiResponse<>(true, "Tasks for date fetched", tasks));
    }

    public ResponseEntity<ApiResponse<TaskModel>> getTaskDetails(long taskId) {
        return ResponseEntity.ok(new ApiResponse<>(true, "Task details fetched", requireTask(taskId)));
    }

    @Transactional
    public ResponseEntity<ApiResponse<TaskModel>> updateTask(UpdateTaskRequestDto requestDto) {
        TaskModel task = requireTask(requestDto.getTaskId());

        if (requestDto.getTitle() != null) task.setTitle(requestDto.getTitle());
        if (requestDto.getDescription() != null) task.setDescription(requestDto.getDescription());
        if (requestDto.getDueDate() != null) task.setDueDate(requestDto.getDueDate());
        if (requestDto.getDueTime() != null) task.setDueTime(requestDto.getDueTime());
        if (requestDto.getCategory() != null) task.setCategory(requestDto.getCategory());
        if (requestDto.getPriority() != null) task.setPriority(requestDto.getPriority());
        if (requestDto.getStatus() != null) task.setStatus(requestDto.getStatus());
        task.setCompleted(requestDto.isCompleted() || "COMPLETED".equalsIgnoreCase(task.getStatus()));
        task.setUpdatedAt(LocalDateTime.now().toString());

        TaskModel saved = taskRepository.save(task);
        return ResponseEntity.ok(new ApiResponse<>(true, "Task updated successfully", saved));
    }

    @Transactional
    public ResponseEntity<ApiResponse<TaskModel>> toggleStatus(long taskId, String status) {
        TaskModel task = requireTask(taskId);

        String newStatus = status != null ? status.toUpperCase() : ("COMPLETED".equalsIgnoreCase(task.getStatus()) ? "PENDING" : "COMPLETED");
        task.setStatus(newStatus);
        task.setCompleted("COMPLETED".equalsIgnoreCase(newStatus));
        task.setUpdatedAt(LocalDateTime.now().toString());

        TaskModel saved = taskRepository.save(task);
        return ResponseEntity.ok(new ApiResponse<>(true, "Task status updated", saved));
    }

    @Transactional
    public ResponseEntity<ApiResponse<Boolean>> deleteTask(long taskId) {
        if (!taskRepository.existsById(taskId)) {
            throw new NotFoundException("Task not found");
        }
        taskRepository.deleteById(taskId);
        return ResponseEntity.ok(new ApiResponse<>(true, "Task deleted successfully", true));
    }
}
