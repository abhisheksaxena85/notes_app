package com.example.notes_app.tasks.controller;

import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.tasks.dto.request.CreateTaskRequestDto;
import com.example.notes_app.tasks.dto.request.UpdateTaskRequestDto;
import com.example.notes_app.tasks.dto.response.CreateTaskResponseDto;
import com.example.notes_app.tasks.model.TaskModel;
import com.example.notes_app.tasks.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/tasks")
public class TaskController {

    @Autowired
    private TaskService taskService;

    @PostMapping("/create-task")
    public ResponseEntity<ApiResponse<CreateTaskResponseDto>> createTask(@RequestBody CreateTaskRequestDto requestDto) {
        return taskService.createTask(requestDto);
    }

    @GetMapping("/get-all-tasks")
    public ResponseEntity<ApiResponse<List<TaskModel>>> getAllTasks(@RequestParam long userId) {
        return taskService.getAllTasks(userId);
    }

    @GetMapping("/get-tasks-by-date")
    public ResponseEntity<ApiResponse<List<TaskModel>>> getTasksByDate(
            @RequestParam long userId,
            @RequestParam String date) {
        return taskService.getTasksByDate(userId, date);
    }

    @GetMapping("/get-task-details")
    public ResponseEntity<ApiResponse<TaskModel>> getTaskDetails(@RequestParam long id) {
        return taskService.getTaskDetails(id);
    }

    @PutMapping("/update-task")
    public ResponseEntity<ApiResponse<TaskModel>> updateTask(@RequestBody UpdateTaskRequestDto requestDto) {
        return taskService.updateTask(requestDto);
    }

    @PutMapping("/toggle-status")
    public ResponseEntity<ApiResponse<TaskModel>> toggleStatus(
            @RequestParam long taskId,
            @RequestParam(required = false) String status) {
        return taskService.toggleStatus(taskId, status);
    }

    @DeleteMapping("/delete-task")
    public ResponseEntity<ApiResponse<Boolean>> deleteTask(
            @RequestParam(required = false) Long id,
            @RequestParam(required = false) Long taskId) {
        long targetId = id != null ? id : (taskId != null ? taskId : 0L);
        return taskService.deleteTask(targetId);
    }
}
