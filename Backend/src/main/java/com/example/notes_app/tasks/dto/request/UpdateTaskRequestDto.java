package com.example.notes_app.tasks.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class UpdateTaskRequestDto {
    private long taskId;
    private String title;
    private String description;
    private String dueDate;
    private String dueTime;
    private String category;
    private String priority;
    private String status;
    // Lombok exposes this as "completed"; accept the "isCompleted" key the client sends.
    @JsonProperty("isCompleted")
    private boolean isCompleted;
}
