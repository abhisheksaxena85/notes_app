package com.example.notes_app.tasks.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.IdempotentCreate;
import com.example.notes_app.common.ItemStatus;
import com.example.notes_app.common.Timestamps;
import com.example.notes_app.common.WallClock;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.tasks.dto.request.CreateTaskRequestDto;
import com.example.notes_app.tasks.dto.request.UpdateTaskRequestDto;
import com.example.notes_app.tasks.dto.response.CreateTaskResponseDto;
import com.example.notes_app.tasks.model.Priority;
import com.example.notes_app.tasks.model.TaskModel;
import com.example.notes_app.tasks.repository.TaskRepository;
import jakarta.transaction.Transactional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;

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
        // Validate before the lookup so a bad request is a 400 whatever the user id.
        TaskModel draft = newTask(requestDto);
        UserModel user = authRepository.findById(requestDto.getUserId())
                .orElseThrow(() -> new NotFoundException("User not found"));
        String clientId = IdempotentCreate.normalize(requestDto.getClientId());

        IdempotentCreate.Result<TaskModel> result = IdempotentCreate.createOnce(
                clientId,
                () -> taskRepository.findByUser_IdAndClientId(user.getId(), clientId),
                () -> {
                    draft.setUser(user);
                    draft.setClientId(clientId);
                    return taskRepository.save(draft);
                });

        if (!result.created()) {
            return ResponseEntity.ok(new ApiResponse<>(true, "Task already created",
                    new CreateTaskResponseDto(result.entity().getTaskId())));
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, "Task created successfully",
                        new CreateTaskResponseDto(result.entity().getTaskId())));
    }

    /** A validated, unsaved task without its user and client id. */
    private static TaskModel newTask(CreateTaskRequestDto requestDto) {
        TaskModel task = new TaskModel();
        task.setTitle(requireTitle(requestDto.getTitle()));
        task.setDescription(requestDto.getDescription());
        task.setDueDate(dueDate(requestDto.getDueDate()));
        task.setDueTime(dueTime(requestDto.getDueTime()));
        task.setCategory(requestDto.getCategory() != null ? requestDto.getCategory() : "General");
        Priority priority = Priority.parse(requestDto.getPriority());
        task.setPriority(priority != null ? priority : Priority.MEDIUM);
        // Old clients may send only isCompleted; status is the single source of truth after that.
        ItemStatus status = ItemStatus.parse(requestDto.getStatus());
        applyStatus(task, status != null ? status
                : (requestDto.isCompleted() ? ItemStatus.COMPLETED : ItemStatus.PENDING));
        task.setCreatedAt(Timestamps.now());
        task.setUpdatedAt(Timestamps.now());
        return task;
    }

    /** BE-04: {@code isCompleted} is always derived from the status, here and only here. */
    private static void applyStatus(TaskModel task, ItemStatus status) {
        task.setStatus(status);
        task.setCompleted(status == ItemStatus.COMPLETED);
    }

    private static String requireTitle(String title) {
        if (title == null || title.isBlank()) {
            throw new BadRequestException("title is required");
        }
        return title;
    }

    /** Optional {@code yyyy-MM-dd}; blank clears it. */
    private static String dueDate(String value) {
        return value == null || value.isBlank() ? null : WallClock.formatDate(WallClock.parseDate("dueDate", value));
    }

    /** Optional {@code HH:mm}; blank clears it. */
    private static String dueTime(String value) {
        return value == null || value.isBlank() ? null : WallClock.formatTime(WallClock.parseTime("dueTime", value));
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

        if (requestDto.getTitle() != null) task.setTitle(requireTitle(requestDto.getTitle()));
        if (requestDto.getDescription() != null) task.setDescription(requestDto.getDescription());
        if (requestDto.getDueDate() != null) task.setDueDate(dueDate(requestDto.getDueDate()));
        if (requestDto.getDueTime() != null) task.setDueTime(dueTime(requestDto.getDueTime()));
        if (requestDto.getCategory() != null) task.setCategory(requestDto.getCategory());
        Priority priority = Priority.parse(requestDto.getPriority());
        if (priority != null) task.setPriority(priority);
        // The request's isCompleted is ignored: a partial update can't tell
        // "false" from "not sent", so the status alone decides.
        ItemStatus status = ItemStatus.parse(requestDto.getStatus());
        applyStatus(task, status != null ? status : task.getStatus());
        task.setUpdatedAt(Timestamps.now());

        TaskModel saved = taskRepository.save(task);
        return ResponseEntity.ok(new ApiResponse<>(true, "Task updated successfully", saved));
    }

    @Transactional
    public ResponseEntity<ApiResponse<TaskModel>> toggleStatus(long taskId, String status) {
        ItemStatus requested = ItemStatus.parse(status);
        TaskModel task = requireTask(taskId);

        // Without a status the call toggles between COMPLETED and PENDING.
        applyStatus(task, requested != null ? requested
                : (task.getStatus() == ItemStatus.COMPLETED ? ItemStatus.PENDING : ItemStatus.COMPLETED));
        task.setUpdatedAt(Timestamps.now());

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
