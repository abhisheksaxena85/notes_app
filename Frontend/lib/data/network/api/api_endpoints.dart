// SCREAMING_CASE is this project's convention for endpoint constants.
// ignore_for_file: non_constant_identifier_names
class ApiEndpoints {
  static String LOGIN = "/auth/login";
  static String CREATE_USER = "/auth/create-user";
  static String GET_ALL_NOTES = "/notes/get-all-notes";
  static String USER_DETAILS = "/auth/user-details-by-userid";
  static String CREATE_NOTE = "/notes/create-note";
  static String UPDATE_NOTE = "/notes/update-note";
  static String GET_NOTE_DETAILS = "/notes/get-details-by-noteId";
  static String DELETE_NOTE = "/notes/delete-note";
  static String TOGGLE_PIN = "/notes/toggle-pin";
  static String CALENDAR_SUMMARY = "/notes/calendar-summary";
  static String GET_NOTES_BY_DATE = "/notes/get-notes-by-date";
  static String SEARCH_NOTES = "/notes/search";
  static String EXPORT_NOTES = "/notes/export";
  static String UPDATE_USER = "/auth/update-user";
  static String CHANGE_PASSWORD = "/auth/change-password";
  static String DELETE_USER = "/auth/delete-user";

  // Tasks
  static String CREATE_TASK = "/tasks/create-task";
  static String GET_ALL_TASKS = "/tasks/get-all-tasks";
  static String GET_TASKS_BY_DATE = "/tasks/get-tasks-by-date";
  static String UPDATE_TASK = "/tasks/update-task";
  static String TOGGLE_TASK_STATUS = "/tasks/toggle-status";
  static String DELETE_TASK = "/tasks/delete-task";

  // Reminders
  static String CREATE_REMINDER = "/reminders/create-reminder";
  static String GET_ALL_REMINDERS = "/reminders/get-all-reminders";
  static String GET_REMINDERS_BY_DATE = "/reminders/get-by-date";
  static String UPDATE_REMINDER = "/reminders/update-reminder";
  static String UPDATE_REMINDER_STATUS = "/reminders/update-status";
  static String DELETE_REMINDER = "/reminders/delete-reminder";
  static String COMPLETE_REMINDER_OCCURRENCE = "/reminders/complete-occurrence";
}
