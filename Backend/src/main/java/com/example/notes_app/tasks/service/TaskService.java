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
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class TaskService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private AuthRepository authRepository;

    /**
     * SEC-01: the task, scoped to {@code ownerId}. Another user's task is "not
     * found". {@code ownerId == null} is a legacy request without a token
     * (only while auth is not enforced, see CurrentUser): no owner check.
     */
    private TaskModel requireTask(long taskId, Long ownerId) {
        Optional<TaskModel> task = ownerId == null
                ? taskRepository.findById(taskId)
                : taskRepository.findByTaskIdAndUser_Id(taskId, ownerId);
        return task.orElseThrow(() -> new NotFoundException("Task not found"));
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

    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<List<TaskModel>>> getAllTasks(long userId) {
        List<TaskModel> tasks = taskRepository.findByUserId(userId);
        return ResponseEntity.ok(new ApiResponse<>(true, "Tasks fetched successfully", tasks));
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<List<TaskModel>>> getTasksByDate(long userId, String date) {
        List<TaskModel> tasks = taskRepository.findByUserIdAndDueDate(userId, date);
        return ResponseEntity.ok(new ApiResponse<>(true, "Tasks for date fetched", tasks));
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<TaskModel>> getTaskDetails(long taskId, Long ownerId) {
        return ResponseEntity.ok(new ApiResponse<>(true, "Task details fetched", requireTask(taskId, ownerId)));
    }

    @Transactional
    public ResponseEntity<ApiResponse<TaskModel>> updateTask(UpdateTaskRequestDto requestDto, Long ownerId) {
        TaskModel task = requireTask(requestDto.getTaskId(), ownerId);

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
    public ResponseEntity<ApiResponse<TaskModel>> toggleStatus(long taskId, String status, Long ownerId) {
        ItemStatus requested = ItemStatus.parse(status);
        TaskModel task = requireTask(taskId, ownerId);

        // Without a status the call toggles between COMPLETED and PENDING.
        applyStatus(task, requested != null ? requested
                : (task.getStatus() == ItemStatus.COMPLETED ? ItemStatus.PENDING : ItemStatus.COMPLETED));
        task.setUpdatedAt(Timestamps.now());

        TaskModel saved = taskRepository.save(task);
        return ResponseEntity.ok(new ApiResponse<>(true, "Task status updated", saved));
    }

    @Transactional
    public ResponseEntity<ApiResponse<Boolean>> deleteTask(long taskId, Long ownerId) {
        taskRepository.delete(requireTask(taskId, ownerId));
        return ResponseEntity.ok(new ApiResponse<>(true, "Task deleted successfully", true));
    }
}
