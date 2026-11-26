package com.example.notes_app.notes.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CalendarSummaryResponseDto {
    private int year;
    private int month;
    private int totalNotes;
    private int totalTasks;
    private int totalReminders;
    private int totalItems;
    private Map<String, Integer> countsByDate;
    private Map<String, Integer> noteCountsByDate;
    private Map<String, Integer> taskCountsByDate;
    private Map<String, Integer> reminderCountsByDate;

    public CalendarSummaryResponseDto(int year, int month, int totalNotes, Map<String, Integer> countsByDate) {
        this.year = year;
        this.month = month;
        this.totalNotes = totalNotes;
        this.totalItems = totalNotes;
        this.countsByDate = countsByDate;
    }
}
