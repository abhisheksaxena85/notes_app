import 'package:notes_app/data/network/dto/response/reminder/reminder_item.dart';

class ReminderState {
  final List<ReminderItem> reminders;
  final bool isLoading;
  final String? errorMessage;

  const ReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ReminderState copyWith({
    List<ReminderItem>? reminders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
