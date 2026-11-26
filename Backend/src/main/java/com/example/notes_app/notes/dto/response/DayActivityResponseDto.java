package com.example.notes_app.notes.dto.response;

import com.example.notes_app.notes.model.NotesModel;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.tasks.model.TaskModel;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DayActivityResponseDto {
    private String date;
    private int totalCount;
    private List<NotesModel> notes;
    private List<TaskModel> tasks;
    private List<ReminderModel> reminders;
}
