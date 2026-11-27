package com.example.notes_app.reminders.service;

import com.example.notes_app.auth.model.UserModel;
import com.example.notes_app.auth.repository.AuthRepository;
import com.example.notes_app.common.ApiResponse;
import com.example.notes_app.common.IdempotentCreate;
import com.example.notes_app.common.ItemStatus;
import com.example.notes_app.common.Timestamps;
import com.example.notes_app.common.WallClock;
import com.example.notes_app.common.exception.BadRequestException;
import com.example.notes_app.common.exception.NotFoundException;
import com.example.notes_app.reminders.dto.request.CompleteOccurrenceRequestDto;
import com.example.notes_app.reminders.dto.request.CreateReminderRequestDto;
import com.example.notes_app.reminders.dto.request.UpdateReminderRequestDto;
import com.example.notes_app.reminders.dto.response.CreateReminderResponseDto;
import com.example.notes_app.reminders.model.ReminderModel;
import com.example.notes_app.reminders.model.ReminderOutcome;
import com.example.notes_app.reminders.model.RepeatInterval;
import com.example.notes_app.reminders.repository.ReminderRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class ReminderService {

    @Autowired
    private ReminderRepository reminderRepository;

    @Autowired
    private AuthRepository authRepository;

    /**
     * SEC-01: the reminder, scoped to {@code ownerId}. Another user's reminder
     * is "not found". {@code ownerId == null} is a legacy request without a
     * token (only while auth is not enforced, see CurrentUser): no owner check.
     */
    private ReminderModel requireReminder(long reminderId, Long ownerId) {
        Optional<ReminderModel> reminder = ownerId == null
                ? reminderRepository.findById(reminderId)
                : reminderRepository.findByReminderIdAndUser_Id(reminderId, ownerId);
        return reminder.orElseThrow(() -> new NotFoundException("Reminder not found"));
    }

    /**
     * Not @Transactional on purpose: see {@link IdempotentCreate}. A repeat with
     * the same clientId returns the existing reminder with 200 instead of 201.
     */
    public ResponseEntity<ApiResponse<CreateReminderResponseDto>> createReminder(CreateReminderRequestDto requestDto) {
        // Validate before the lookup so a bad request is a 400 whatever the user id.
        ReminderModel draft = newReminder(requestDto);
        UserModel user = authRepository.findById(requestDto.getUserId())
                .orElseThrow(() -> new NotFoundException("User not found"));
        String clientId = IdempotentCreate.normalize(requestDto.getClientId());

        IdempotentCreate.Result<ReminderModel> result = IdempotentCreate.createOnce(
                clientId,
                () -> reminderRepository.findByUser_IdAndClientId(user.getId(), clientId),
                () -> {
                    draft.setUser(user);
                    draft.setClientId(clientId);
                    return reminderRepository.save(draft);
                });

        if (!result.created()) {
            return ResponseEntity.ok(new ApiResponse<>(true, "Reminder already created",
                    new CreateReminderResponseDto(result.entity().getReminderId())));
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new ApiResponse<>(true, "Reminder created successfully",
                        new CreateReminderResponseDto(result.entity().getReminderId())));
    }

    /** A validated, unsaved reminder without its user and client id. */
    private static ReminderModel newReminder(CreateReminderRequestDto requestDto) {
        if (requestDto.getRemindAt() == null || requestDto.getRemindAt().isBlank()) {
            throw new BadRequestException("remindAt is required");
        }
        ReminderModel reminder = new ReminderModel();
        reminder.setTitle(requireTitle(requestDto.getTitle()));
        applyRemindAt(reminder, requestDto.getRemindAt(), requestDto.getDueDate(), requestDto.getDueTime());
        reminder.setStartAt(isBlank(requestDto.getStartAt())
                ? reminder.getRemindAt()
                : WallClock.format(WallClock.parseDateTime("startAt", requestDto.getStartAt())));
        reminder.setCategory(requestDto.getCategory() != null ? requestDto.getCategory() : "General");
        ItemStatus status = ItemStatus.parse(requestDto.getStatus());
        reminder.setStatus(status != null ? status : ItemStatus.PENDING);
        RepeatInterval interval = RepeatInterval.parse(requestDto.getRepeatInterval());
        reminder.setRepeatInterval(interval != null ? interval : RepeatInterval.NONE);
        reminder.setCreatedAt(Timestamps.now());
        reminder.setUpdatedAt(Timestamps.now());
        return reminder;
    }

    private static String requireTitle(String title) {
        if (title == null || title.isBlank()) {
            throw new BadRequestException("title is required");
        }
        return title;
    }

    /**
     * BE-04: sets {@code remindAt} and keeps {@code dueDate}/{@code dueTime} in
     * step with it. Explicit values win; otherwise they are derived from
     * {@code remindAt}, so moving a reminder to another day also moves it on
     * the calendar and in get-by-date.
     */
    private static void applyRemindAt(ReminderModel reminder, String remindAt, String dueDate, String dueTime) {
        LocalDateTime at = WallClock.parseDateTime("remindAt", remindAt);
        reminder.setRemindAt(WallClock.format(at));
        reminder.setDueDate(isBlank(dueDate)
                ? WallClock.formatDate(at.toLocalDate())
                : WallClock.formatDate(WallClock.parseDate("dueDate", dueDate)));
        reminder.setDueTime(isBlank(dueTime)
                ? WallClock.formatTime(at.toLocalTime())
                : WallClock.formatTime(WallClock.parseTime("dueTime", dueTime)));
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<List<ReminderModel>>> getAllReminders(long userId) {
        List<ReminderModel> reminders = reminderRepository.findByUserId(userId);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminders fetched successfully", reminders));
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<List<ReminderModel>>> getRemindersByDate(long userId, String date) {
        List<ReminderModel> reminders = reminderRepository.findByUserIdAndDueDate(userId, date);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminders for date fetched", reminders));
    }

    @Transactional
    public ResponseEntity<ApiResponse<ReminderModel>> updateReminder(UpdateReminderRequestDto requestDto, Long ownerId) {
        ReminderModel reminder = requireReminder(requestDto.getReminderId(), ownerId);

        if (requestDto.getTitle() != null) reminder.setTitle(requireTitle(requestDto.getTitle()));
        if (requestDto.getRemindAt() != null) {
            String previous = reminder.getRemindAt();
            applyRemindAt(reminder, requestDto.getRemindAt(), requestDto.getDueDate(), requestDto.getDueTime());
            // REM-07: moving remindAt without a startAt re-anchors the series there.
            if (isBlank(requestDto.getStartAt()) && !Objects.equals(previous, reminder.getRemindAt())) {
                reminder.setStartAt(reminder.getRemindAt());
            }
        } else {
            if (requestDto.getDueDate() != null) {
                reminder.setDueDate(WallClock.formatDate(WallClock.parseDate("dueDate", requestDto.getDueDate())));
            }
            if (requestDto.getDueTime() != null) {
                reminder.setDueTime(WallClock.formatTime(WallClock.parseTime("dueTime", requestDto.getDueTime())));
            }
        }
        if (requestDto.getCategory() != null) reminder.setCategory(requestDto.getCategory());
        ItemStatus status = ItemStatus.parse(requestDto.getStatus());
        if (status != null) reminder.setStatus(status);
        RepeatInterval interval = RepeatInterval.parse(requestDto.getRepeatInterval());
        if (interval != null) reminder.setRepeatInterval(interval);
        if (!isBlank(requestDto.getStartAt())) {
            reminder.setStartAt(WallClock.format(WallClock.parseDateTime("startAt", requestDto.getStartAt())));
        }
        ReminderOutcome outcome = ReminderOutcome.parse(requestDto.getLastOutcome());
        if (outcome != null) {
            reminder.setLastOutcome(outcome);
            reminder.setLastOutcomeAt(isBlank(requestDto.getLastOutcomeAt()) ? null
                    : WallClock.format(WallClock.parseDateTime("lastOutcomeAt", requestDto.getLastOutcomeAt())));
        }
        reminder.setUpdatedAt(Timestamps.now());

        ReminderModel saved = reminderRepository.save(reminder);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminder updated successfully", saved));
    }

    @Transactional
    public ResponseEntity<ApiResponse<ReminderModel>> updateStatus(long reminderId, String status, Long ownerId) {
        ItemStatus requested = ItemStatus.parse(status);
        ReminderModel reminder = requireReminder(reminderId, ownerId);

        // Without a status the call toggles between COMPLETED and PENDING.
        ItemStatus newStatus = requested != null ? requested
                : (reminder.getStatus() == ItemStatus.COMPLETED ? ItemStatus.PENDING : ItemStatus.COMPLETED);
        reminder.setStatus(newStatus);
        reminder.setUpdatedAt(Timestamps.now());

        ReminderModel saved = reminderRepository.save(reminder);
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminder status updated", saved));
    }

    /**
     * REM-07: the user answered one occurrence ("Done" / "Not done").
     *
     * <ul>
     *   <li>One-off reminder: the status becomes the outcome.</li>
     *   <li>Repeating reminder: only when {@code occurrence} is the current
     *       {@code remindAt}, the reminder moves to its next occurrence (anchored
     *       to {@code startAt}), stays PENDING and records the outcome. Any other
     *       occurrence was already handled (a retried or duplicated request), so
     *       the reminder is returned unchanged: the call is idempotent.</li>
     * </ul>
     */
    @Transactional
    public ResponseEntity<ApiResponse<ReminderModel>> completeOccurrence(CompleteOccurrenceRequestDto requestDto, Long ownerId) {
        LocalDateTime occurrence = WallClock.parseDateTime("occurrence", requestDto.getOccurrence());
        ReminderOutcome outcome = ReminderOutcome.parse(requestDto.getOutcome());
        if (outcome == null) {
            throw new BadRequestException("outcome is required");
        }
        ReminderModel reminder = requireReminder(requestDto.getReminderId(), ownerId);
        RepeatInterval interval = reminder.getRepeatInterval() != null ? reminder.getRepeatInterval() : RepeatInterval.NONE;

        if (interval == RepeatInterval.NONE) {
            reminder.setStatus(outcome == ReminderOutcome.COMPLETED ? ItemStatus.COMPLETED : ItemStatus.MISSED);
        } else {
            LocalDateTime current = WallClock.tryParseDateTime(reminder.getRemindAt()).orElse(null);
            if (!occurrence.equals(current)) {
                return ResponseEntity.ok(new ApiResponse<>(true, "Occurrence already handled", reminder));
            }
            LocalDateTime start = WallClock.tryParseDateTime(reminder.getStartAt()).orElse(current);
            applyRemindAt(reminder, WallClock.format(RecurrenceCalculator.next(start, interval, occurrence)), null, null);
            reminder.setStatus(ItemStatus.PENDING);
        }
        reminder.setLastOutcome(outcome);
        reminder.setLastOutcomeAt(WallClock.format(occurrence));
        reminder.setUpdatedAt(Timestamps.now());

        ReminderModel saved = reminderRepository.save(reminder);
        return ResponseEntity.ok(new ApiResponse<>(true, "Occurrence recorded", saved));
    }

    @Transactional
    public ResponseEntity<ApiResponse<Boolean>> deleteReminder(long reminderId, Long ownerId) {
        reminderRepository.delete(requireReminder(reminderId, ownerId));
        return ResponseEntity.ok(new ApiResponse<>(true, "Reminder deleted successfully", true));
    }
}
