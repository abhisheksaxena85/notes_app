package com.invospec.daymark.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.Text
import com.invospec.daymark.MainActivity
import com.invospec.daymark.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetScheduler
import es.antonborri.home_widget.actionStartActivity as startApp
import org.json.JSONObject

/**
 * W-05: "Next reminder". The first reminder occurrence later than now, its time and a relative
 * label; wide sizes add a Done button and the following reminder.
 *
 * It rolls over on its own: the snapshot holds the next few occurrences, every render picks the
 * first one later than now, and the receiver schedules a redraw just after each of them (and every
 * 5 minutes during the last hour, so "in 25 min" stays honest). Those alarms survive reboots
 * (home_widget's HomeWidgetScheduledUpdateReceiver).
 */
class NextReminderWidget : GlanceAppWidget() {

  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override val sizeMode = SizeMode.Exact

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent {
      val state = currentState<HomeWidgetGlanceState>()
      NextReminderContent(WidgetSnapshot.read(state.preferences))
    }
  }

  companion object {
    /** The upcoming occurrences, minus ones just answered here, soonest first. */
    fun upcoming(context: Context, snapshot: WidgetSnapshot, now: Long): List<WidgetReminder> {
      val answered = AnsweredReminders.read(context, now)
      return snapshot.reminders
          .filter { it.fireAt > now && AnsweredReminders.key(it) !in answered }
          .sortedBy { it.fireAt }
    }

    /** When this widget must redraw next (epoch millis). */
    fun refreshTimes(upcoming: List<WidgetReminder>, now: Long): List<Long> {
      val times = upcoming.map { it.fireAt + 1_000 }.toMutableList()
      val next = upcoming.firstOrNull()?.fireAt ?: return times
      val hour = 60 * 60_000L
      val step = 5 * 60_000L
      if (next - now <= hour) {
        var at = (now / step + 1) * step
        while (at < next) {
          times += at
          at += step
        }
      } else {
        times += next - hour
      }
      return times
    }
  }
}

class NextReminderWidgetReceiver : HomeWidgetGlanceWidgetReceiver<NextReminderWidget>() {
  override val glanceAppWidget = NextReminderWidget()

  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
    super.onUpdate(context, appWidgetManager, appWidgetIds)
    scheduleRefreshes(context)
  }

  override fun onEnabled(context: Context) {
    super.onEnabled(context)
    scheduleRefreshes(context)
  }

  override fun onDisabled(context: Context) {
    super.onDisabled(context)
    HomeWidgetScheduler.cancel(context, javaClass.name)
  }

  private fun scheduleRefreshes(context: Context) {
    val now = System.currentTimeMillis()
    val snapshot = WidgetSnapshot.read(HomeWidgetPlugin.getData(context))
    val times = NextReminderWidget.refreshTimes(NextReminderWidget.upcoming(context, snapshot, now), now)
    HomeWidgetScheduler.schedule(context, javaClass.name, times)
  }
}

/** Done: moves on to the next reminder at once, then Flutter answers the occurrence (W-02). */
class ReminderDoneCallback : ActionCallback {
  override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
    val id = parameters[REMINDER_ID] ?: return
    val occurrence = parameters[OCCURRENCE] ?: return
    val reminder = WidgetReminder(id, "", 0, occurrence, null, false)
    AnsweredReminders.add(context, reminder)
    updateAppWidgetState(context, HomeWidgetGlanceStateDefinition(), glanceId) { it }
    NextReminderWidget().update(context, glanceId)
    HomeWidgetBackgroundIntent.getBroadcast(context, WidgetLinks.reminderDone(reminder)).send()
  }

  companion object {
    val REMINDER_ID = ActionParameters.Key<Long>("reminderId")
    val OCCURRENCE = ActionParameters.Key<String>("occurrence")
  }
}

/**
 * Occurrences answered Done on the widget and not yet confirmed by a new snapshot, so the widget
 * shows the next one immediately (trusted for a minute).
 */
object AnsweredReminders {
  private const val PREFERENCES = "daymark_widgets"
  private const val KEY = "answeredReminders"
  private const val TRUST_MS = 60_000L

  fun key(reminder: WidgetReminder) = "${reminder.id}@${reminder.occurrence}"

  private fun prefs(context: Context) =
      context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)

  fun add(context: Context, reminder: WidgetReminder, at: Long = System.currentTimeMillis()) {
    val json = JSONObject()
    read(context, at).forEach { (key, time) -> json.put(key, time) }
    json.put(key(reminder), at)
    prefs(context).edit().putString(KEY, json.toString()).apply()
  }

  fun read(context: Context, now: Long = System.currentTimeMillis()): Map<String, Long> {
    val raw = prefs(context).getString(KEY, null) ?: return emptyMap()
    return try {
      val json = JSONObject(raw)
      json.keys().asSequence().mapNotNull { key ->
        val at = json.optLong(key)
        if (now - at < TRUST_MS) key to at else null
      }.toMap()
    } catch (error: Exception) {
      emptyMap()
    }
  }
}

@Composable
private fun NextReminderContent(snapshot: WidgetSnapshot) {
  val context = LocalContext.current
  val now = System.currentTimeMillis()
  val size = LocalSize.current
  val wide = size.width.value >= 220f
  val short = size.height.value < 100f
  WidgetFrame {
    if (!snapshot.loggedIn) {
      Column(
          modifier = GlanceModifier.fillMaxSize().clickable(startApp<MainActivity>(context)),
          verticalAlignment = Alignment.CenterVertically,
          horizontalAlignment = Alignment.CenterHorizontally,
      ) {
        BellTile()
        Spacer(GlanceModifier.height(8.dp))
        Text("Sign in to Daymark", style = WidgetText.section(R.color.widget_ink), maxLines = 1)
      }
      return@WidgetFrame
    }
    val upcoming = NextReminderWidget.upcoming(context, snapshot, now)
    val next = upcoming.firstOrNull()
    if (next == null) {
      if (short) {
        Row(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
          BellTile()
          Spacer(GlanceModifier.width(10.dp))
          Text(
              "No upcoming reminders",
              style = WidgetText.row(R.color.widget_muted),
              maxLines = 1,
              modifier = GlanceModifier.defaultWeight(),
          )
          AccentButton("New reminder", startApp<MainActivity>(context, WidgetLinks.newReminder))
        }
      } else {
        EmptyState(
            message = "No upcoming reminders",
            button = "New reminder",
            onClick = startApp<MainActivity>(context, WidgetLinks.newReminder),
        )
      }
      return@WidgetFrame
    }
    val following = upcoming.getOrNull(1)
    val open = startApp<MainActivity>(context, WidgetLinks.reminder(next.id))
    val done =
        actionRunCallback<ReminderDoneCallback>(
            actionParametersOf(
                ReminderDoneCallback.REMINDER_ID to next.id,
                ReminderDoneCallback.OCCURRENCE to next.occurrence,
            )
        )
    when {
      wide && short -> CompactRow(context, next, now, open, done)
      wide -> {
        Row(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
          Column(modifier = GlanceModifier.defaultWeight().clickable(open)) {
            Details(context, next, now)
          }
          Spacer(GlanceModifier.width(8.dp))
          AccentButton("Done", done)
        }
        if (following != null) {
          Text(
              "Then ${following.title} · ${WidgetFormat.reminderTime(context, following.fireAt, now)}",
              style = WidgetText.meta(R.color.widget_muted),
              maxLines = 1,
              modifier = GlanceModifier.fillMaxWidth(),
          )
        }
      }
      else -> Column(modifier = GlanceModifier.fillMaxSize().clickable(open)) { Details(context, next, now) }
    }
  }
}

/** Tile, "Next reminder", title (2 lines), time, relative label and repeat. */
@Composable
private fun Details(context: Context, reminder: WidgetReminder, now: Long) {
  Row(verticalAlignment = Alignment.CenterVertically) {
    BellTile()
    Spacer(GlanceModifier.width(8.dp))
    Text("Next reminder", style = WidgetText.caption(R.color.widget_muted), maxLines = 1)
  }
  Spacer(GlanceModifier.height(8.dp))
  Text(reminder.title, style = WidgetText.section(R.color.widget_ink), maxLines = 2)
  Spacer(GlanceModifier.height(4.dp))
  Text(
      WidgetFormat.reminderTime(context, reminder.fireAt, now),
      style = WidgetText.row(R.color.widget_ink),
      maxLines = 1,
  )
  Row(verticalAlignment = Alignment.CenterVertically) {
    Text(WidgetFormat.relative(reminder.fireAt, now), style = WidgetText.meta(R.color.widget_accent), maxLines = 1)
    RepeatLabel(reminder.repeat)
  }
}

@Composable
private fun CompactRow(
    context: Context,
    reminder: WidgetReminder,
    now: Long,
    open: androidx.glance.action.Action,
    done: androidx.glance.action.Action,
) {
  Row(modifier = GlanceModifier.fillMaxSize(), verticalAlignment = Alignment.CenterVertically) {
    Row(
        modifier = GlanceModifier.defaultWeight().clickable(open),
        verticalAlignment = Alignment.CenterVertically,
    ) {
      BellTile()
      Spacer(GlanceModifier.width(10.dp))
      Column(modifier = GlanceModifier.defaultWeight()) {
        Text(reminder.title, style = WidgetText.section(R.color.widget_ink), maxLines = 1)
        Row(verticalAlignment = Alignment.CenterVertically) {
          Text(
              "${WidgetFormat.reminderTime(context, reminder.fireAt, now)} · ${WidgetFormat.relative(reminder.fireAt, now)}",
              style = WidgetText.meta(R.color.widget_muted),
              maxLines = 1,
          )
          RepeatLabel(reminder.repeat)
        }
      }
    }
    Spacer(GlanceModifier.width(8.dp))
    AccentButton("Done", done)
  }
}

@Composable
private fun RepeatLabel(repeat: String?) {
  val label = WidgetFormat.repeatLabel(repeat) ?: return
  Spacer(GlanceModifier.width(6.dp))
  Image(
      provider = ImageProvider(R.drawable.ic_widget_repeat),
      contentDescription = null,
      modifier = GlanceModifier.size(12.dp),
      colorFilter = ColorFilter.tint(WidgetColors.of(R.color.widget_muted)),
  )
  Spacer(GlanceModifier.width(3.dp))
  Text(label, style = WidgetText.meta(R.color.widget_muted), maxLines = 1)
}

/** The 32 dp accentSoft tile with the bell (ic_reminder). */
@Composable
private fun BellTile() {
  Box(
      modifier =
          GlanceModifier.size(32.dp).background(ImageProvider(R.drawable.widget_tile_accent_soft)),
      contentAlignment = Alignment.Center,
  ) {
    Image(
        provider = ImageProvider(R.drawable.ic_widget_reminder),
        contentDescription = null,
        modifier = GlanceModifier.size(18.dp),
        colorFilter = ColorFilter.tint(WidgetColors.of(R.color.widget_accent)),
    )
  }
}
