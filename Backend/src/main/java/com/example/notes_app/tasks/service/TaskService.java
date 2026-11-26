package com.example.notes_app.tasks.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
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

    @Transactional
    public ResponseEntity<ApiResponse<CreateTaskResponseDto>> createTask(CreateTaskRequestDto requestDto) {
        try {
            UserModel user = authRepository.findById(requestDto.getUserId()).orElse(null);
            if (user == null) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(new ApiResponse<>(false, "User not found!", null));
            }

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

            TaskModel saved = taskRepository.save(task);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(new ApiResponse<>(true, "Task created successfully", new CreateTaskResponseDto(saved.getTaskId())));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "Failed to create task: " + e.getMessage(), null));
        }
    }

    public ResponseEntity<ApiResponse<List<TaskModel>>> getAllTasks(long userId) {
        try {
            List<TaskModel> tasks = taskRepository.findByUserId(userId);
            return ResponseEntity.ok(new ApiResponse<>(true, "Tasks fetched successfully", tasks));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "Failed to fetch tasks: " + e.getMessage(), null));
        }
    }

    public ResponseEntity<ApiResponse<List<TaskModel>>> getTasksByDate(long userId, String date) {
        try {
            List<TaskModel> tasks = taskRepository.findByUserIdAndDueDate(userId, date);
            return ResponseEntity.ok(new ApiResponse<>(true, "Tasks for date fetched", tasks));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "Failed to fetch tasks by date: " + e.getMessage(), null));
        }
    }

    public ResponseEntity<ApiResponse<TaskModel>> getTaskDetails(long taskId) {
        try {
            TaskModel task = taskRepository.findById(taskId).orElse(null);
            if (task == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>(false, "Task not found", null));
            }
            return ResponseEntity.ok(new ApiResponse<>(true, "Task details fetched", task));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "Failed to fetch task: " + e.getMessage(), null));
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<TaskModel>> updateTask(UpdateTaskRequestDto requestDto) {
        try {
            TaskModel task = taskRepository.findById(requestDto.getTaskId()).orElse(null);
            if (task == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>(false, "Task not found", null));
            }

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
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "Failed to update task: " + e.getMessage(), null));
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<TaskModel>> toggleStatus(long taskId, String status) {
        try {
            TaskModel task = taskRepository.findById(taskId).orElse(null);
            if (task == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>(false, "Task not found", null));
            }

            String newStatus = status != null ? status.toUpperCase() : ("COMPLETED".equalsIgnoreCase(task.getStatus()) ? "PENDING" : "COMPLETED");
            task.setStatus(newStatus);
            task.setCompleted("COMPLETED".equalsIgnoreCase(newStatus));
            task.setUpdatedAt(LocalDateTime.now().toString());

            TaskModel saved = taskRepository.save(task);
            return ResponseEntity.ok(new ApiResponse<>(true, "Task status updated", saved));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "Failed to toggle status: " + e.getMessage(), null));
        }
    }

    @Transactional
    public ResponseEntity<ApiResponse<Boolean>> deleteTask(long taskId) {
        try {
            if (!taskRepository.existsById(taskId)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ApiResponse<>(false, "Task does not exist", false));
            }
            taskRepository.deleteById(taskId);
            return ResponseEntity.ok(new ApiResponse<>(true, "Task deleted successfully", true));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(new ApiResponse<>(false, "Failed to delete task: " + e.getMessage(), false));
        }
    }
}
