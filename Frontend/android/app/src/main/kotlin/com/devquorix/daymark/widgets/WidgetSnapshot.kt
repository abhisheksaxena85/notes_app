package com.devquorix.daymark.widgets

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.text.format.DateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

/**
 * The snapshot the Flutter app writes for the widgets (W-01, lib/utils/services/home_widgets/
 * widget_snapshot.dart), read from home_widget's SharedPreferences.
 *
 * Times are epoch milliseconds, so the widgets decide "overdue", "Tomorrow, 9:00 AM" and which
 * reminder is next when they render, and stay right after the time passes without the app.
 */
data class WidgetSnapshot(
    val loggedIn: Boolean,
    val taskCount: Int,
    val tasks: List<WidgetTask>,
    val reminders: List<WidgetReminder>,
) {
  companion object {
    /** Same key as WidgetSnapshot.storageKey in Dart. */
    const val KEY = "daymark_widget_snapshot"

    val signedOut = WidgetSnapshot(false, 0, emptyList(), emptyList())

    fun read(preferences: SharedPreferences): WidgetSnapshot =
        parse(preferences.getString(KEY, null))

    /** Anything missing or unreadable reads as signed out (the app was never opened). */
    fun parse(raw: String?): WidgetSnapshot {
      if (raw.isNullOrEmpty()) return signedOut
      return try {
        val json = JSONObject(raw)
        if (!json.optBoolean("loggedIn", false)) return signedOut
        val tasks = json.optJSONObject("tasks")
        WidgetSnapshot(
            loggedIn = true,
            taskCount = tasks?.optInt("count", 0) ?: 0,
            tasks = tasks?.optJSONArray("items").objects().mapNotNull(WidgetTask::parse),
            reminders = json.optJSONArray("reminders").objects().mapNotNull(WidgetReminder::parse),
        )
      } catch (error: Exception) {
        signedOut
      }
    }

    private fun JSONArray?.objects(): List<JSONObject> =
        if (this == null) emptyList() else (0 until length()).mapNotNull { optJSONObject(it) }
  }
}

data class WidgetTask(
    val id: Long,
    val title: String,
    val dueAt: Long?,
    val hasTime: Boolean,
    val overdue: Boolean,
    val doneAt: Long?,
) {
  companion object {
    fun parse(json: JSONObject): WidgetTask? {
      if (!json.has("id")) return null
      return WidgetTask(
          id = json.getLong("id"),
          title = json.optString("title"),
          dueAt = json.optLongOrNull("dueAt"),
          hasTime = json.optBoolean("hasTime", false),
          overdue = json.optBoolean("overdue", false),
          doneAt = json.optLongOrNull("doneAt"),
      )
    }
  }
}

data class WidgetReminder(
    val id: Long,
    val title: String,
    val fireAt: Long,
    val occurrence: String,
    val repeat: String?,
    val snoozed: Boolean,
) {
  companion object {
    fun parse(json: JSONObject): WidgetReminder? {
      val fireAt = json.optLongOrNull("fireAt") ?: return null
      if (!json.has("id")) return null
      return WidgetReminder(
          id = json.getLong("id"),
          title = json.optString("title"),
          fireAt = fireAt,
          occurrence = json.optString("occurrence"),
          repeat = json.optString("repeat").takeIf { it.isNotEmpty() && it != "null" },
          snoozed = json.optBoolean("snoozed", false),
      )
    }
  }
}

private fun JSONObject.optLongOrNull(key: String): Long? =
    if (!has(key) || isNull(key)) null else optLong(key)

/** The daymark:// links the widgets open (W-01) and the background actions (W-02). */
object WidgetLinks {
  fun task(id: Long): Uri = Uri.parse("daymark://task/$id")

  fun reminder(id: Long): Uri = Uri.parse("daymark://reminder/$id")

  val workspace: Uri = Uri.parse("daymark://workspace")
  val newReminder: Uri = Uri.parse("daymark://new-reminder")

  fun toggleTask(id: Long): Uri = Uri.parse("daymark://widget/toggle-task?id=$id")

  fun reminderDone(reminder: WidgetReminder): Uri =
      Uri.Builder()
          .scheme("daymark")
          .authority("widget")
          .path("/reminder-done")
          .appendQueryParameter("id", reminder.id.toString())
          .appendQueryParameter("occurrence", reminder.occurrence)
          .build()
}

/** Dates and times in the device's locale and 12/24-hour setting. */
object WidgetFormat {
  fun time(context: Context, at: Long): String = DateFormat.getTimeFormat(context).format(Date(at))

  /** Whole days from today to [at] (0 = today, 1 = tomorrow, -1 = yesterday). */
  fun daysFromToday(at: Long, now: Long = System.currentTimeMillis()): Int {
    fun startOfDay(millis: Long): Calendar =
        Calendar.getInstance().apply {
          timeInMillis = millis
          set(Calendar.HOUR_OF_DAY, 12) // noon: immune to DST shifts
          set(Calendar.MINUTE, 0)
          set(Calendar.SECOND, 0)
          set(Calendar.MILLISECOND, 0)
        }
    val diff = startOfDay(at).timeInMillis - startOfDay(now).timeInMillis
    return Math.round(diff / 86_400_000.0).toInt()
  }

  private fun shortDate(at: Long): String =
      DateFormat.format(DateFormat.getBestDateTimePattern(Locale.getDefault(), "d MMM"), at).toString()

  private fun weekdayDate(at: Long): String =
      DateFormat.format(DateFormat.getBestDateTimePattern(Locale.getDefault(), "EEE d MMM"), at)
          .toString()

  /** A task's due label: its time today, "Today", "Yesterday", or the date. */
  fun taskDue(context: Context, task: WidgetTask, now: Long = System.currentTimeMillis()): String? {
    val due = task.dueAt ?: return null
    return when (daysFromToday(due, now)) {
      0 -> if (task.hasTime) time(context, due) else "Today"
      -1 -> "Yesterday"
      1 -> if (task.hasTime) "Tomorrow, ${time(context, due)}" else "Tomorrow"
      else -> shortDate(due)
    }
  }

  /** "6:00 PM", "Tomorrow, 9:00 AM" or "Fri 4 Dec, 9:00 AM". */
  fun reminderTime(context: Context, at: Long, now: Long = System.currentTimeMillis()): String {
    val clock = time(context, at)
    return when (daysFromToday(at, now)) {
      0 -> clock
      1 -> "Tomorrow, $clock"
      else -> "${weekdayDate(at)}, $clock"
    }
  }

  /** "in 25 min", "in 3 h", "in 2 days", "now". */
  fun relative(at: Long, now: Long = System.currentTimeMillis()): String {
    val minutes = Math.ceil((at - now) / 60_000.0).toLong()
    return when {
      minutes <= 0 -> "now"
      minutes < 60 -> "in $minutes min"
      minutes < 24 * 60 -> {
        val hours = minutes / 60
        val rest = minutes % 60
        if (rest == 0L || hours >= 3) "in $hours h" else "in $hours h $rest min"
      }
      else -> {
        val days = daysFromToday(at, now)
        if (days <= 1) "tomorrow" else "in $days days"
      }
    }
  }

  fun repeatLabel(repeat: String?): String? =
      when (repeat) {
        "DAILY" -> "Daily"
        "WEEKLY" -> "Weekly"
        "MONTHLY" -> "Monthly"
        else -> null
      }
}

/**
 * Ticks shown the moment a checkbox is tapped, before the Flutter callback (which takes a moment
 * to start) has saved the task and redrawn the widget (W-04).
 */
object OptimisticTicks {
  private const val PREFERENCES = "daymark_widgets"
  private const val KEY = "optimisticDone"

  /** How long a tap is trusted without the snapshot confirming it. */
  private const val TRUST_MS = 60_000L

  private fun prefs(context: Context) =
      context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

  fun add(context: Context, taskId: Long, at: Long = System.currentTimeMillis()) {
    val entries = read(context, at).toMutableMap().apply { put(taskId, at) }
    val json = JSONObject()
    entries.forEach { (id, time) -> json.put(id.toString(), time) }
    prefs(context).edit().putString(KEY, json.toString()).apply()
  }

  fun read(context: Context, now: Long = System.currentTimeMillis()): Map<Long, Long> {
    val raw = prefs(context).getString(KEY, null) ?: return emptyMap()
    return try {
      val json = JSONObject(raw)
      json.keys().asSequence().mapNotNull { key ->
        val id = key.toLongOrNull() ?: return@mapNotNull null
        val at = json.optLong(key)
        if (now - at < TRUST_MS) id to at else null
      }.toMap()
    } catch (error: Exception) {
      emptyMap()
    }
  }

  fun clear(context: Context) {
    prefs(context).edit().remove(KEY).apply()
  }
}
