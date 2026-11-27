package com.example.notes_app.tasks.controller;

import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.CurrentUser;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.tasks.dto.request.CreateTaskRequestDto;
import com.example.notes_app.tasks.dto.request.UpdateTaskRequestDto;
import com.example.notes_app.tasks.dto.response.CreateTaskResponseDto;
import com.example.notes_app.tasks.model.TaskModel;
import com.example.notes_app.tasks.service.TaskService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tasks")
public class TaskController {

    @Autowired
    private TaskService taskService;

    @Autowired
    private CurrentUser currentUser;

    @PostMapping("/create-task")
    public ResponseEntity<ApiResponse<CreateTaskResponseDto>> createTask(@Valid @RequestBody CreateTaskRequestDto requestDto) {
        requestDto.setUserId(currentUser.resolve(requestDto.getUserId(), "userId"));
        return taskService.createTask(requestDto);
    }

    @GetMapping("/get-all-tasks")
    public ResponseEntity<ApiResponse<List<TaskModel>>> getAllTasks(@RequestParam(required = false) Long userId) {
        return taskService.getAllTasks(currentUser.resolve(userId, "userId"));
    }

    @GetMapping("/get-tasks-by-date")
    public ResponseEntity<ApiResponse<List<TaskModel>>> getTasksByDate(
            @RequestParam(required = false) Long userId,
            @RequestParam String date) {
        return taskService.getTasksByDate(currentUser.resolve(userId, "userId"), date);
    }

    @GetMapping("/get-task-details")
    public ResponseEntity<ApiResponse<TaskModel>> getTaskDetails(@RequestParam long id) {
        return taskService.getTaskDetails(id, currentUser.ownerScope());
    }

    @PutMapping("/update-task")
    public ResponseEntity<ApiResponse<TaskModel>> updateTask(@RequestBody UpdateTaskRequestDto requestDto) {
        return taskService.updateTask(requestDto, currentUser.ownerScope());
    }

    @PutMapping("/toggle-status")
    public ResponseEntity<ApiResponse<TaskModel>> toggleStatus(
            @RequestParam long taskId,
            @RequestParam(required = false) String status) {
        return taskService.toggleStatus(taskId, status, currentUser.ownerScope());
    }

    @DeleteMapping("/delete-task")
    public ResponseEntity<ApiResponse<Boolean>> deleteTask(
            @RequestParam(required = false) Long id,
            @RequestParam(required = false) Long taskId) {
        Long targetId = id != null ? id : taskId;
        if (targetId == null) {
            throw new BadRequestException("Task id is required");
        }
        return taskService.deleteTask(targetId, currentUser.ownerScope());
    }
}
