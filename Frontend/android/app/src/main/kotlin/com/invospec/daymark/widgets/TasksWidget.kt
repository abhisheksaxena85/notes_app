package com.invospec.daymark.widgets

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.ColorFilter
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
import androidx.glance.appwidget.action.actionStartActivity
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
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.Text
import androidx.glance.text.TextDecoration
import com.invospec.daymark.MainActivity
import com.invospec.daymark.R
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.HomeWidgetScheduler
import es.antonborri.home_widget.actionStartActivity as startApp

/**
 * W-04: "Daymark Tasks". Today's pending tasks (overdue and due today first, then undated) with a
 * checkbox that completes the task in place, a quick-add button and "+N more".
 *
 * Resizable from 2x2 to 4x4: 3 rows when it is medium height, 6 when large, fewer if they don't
 * fit. Data comes from the snapshot the app writes (WidgetSnapshot); nothing is computed here
 * except what depends on the current time.
 */
class TasksWidget : GlanceAppWidget() {

  /** Needed so home_widget's updateWidget redraws with the new data. */
  override val stateDefinition = HomeWidgetGlanceStateDefinition()

  override val sizeMode = SizeMode.Exact

  override suspend fun provideGlance(context: Context, id: GlanceId) {
    provideContent {
      val state = currentState<HomeWidgetGlanceState>()
      TasksContent(WidgetSnapshot.read(state.preferences))
    }
  }

  companion object {
    /** A ticked task shows its tick this long before the row drops off. */
    const val SHOW_DONE_MS = 4_000L
  }
}

class TasksWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TasksWidget>() {
  override val glanceAppWidget = TasksWidget()
}

/** The checkbox: ticks the row at once, then lets Flutter complete the task (W-02). */
class ToggleTaskCallback : ActionCallback {
  override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
    val id = parameters[TASK_ID] ?: return
    val now = System.currentTimeMillis()
    OptimisticTicks.add(context, id, now)
    // Redraw now with the tick (a new state object makes Glance recompose).
    updateAppWidgetState(context, HomeWidgetGlanceStateDefinition(), glanceId) { it }
    TasksWidget().update(context, glanceId)
    // And once more when the ticked row should drop off.
    HomeWidgetScheduler.schedule(
        context,
        TasksWidgetReceiver::class.java.name,
        listOf(now + TasksWidget.SHOW_DONE_MS + 500),
    )
    HomeWidgetBackgroundIntent.getBroadcast(context, WidgetLinks.toggleTask(id)).send()
  }

  companion object {
    val TASK_ID = ActionParameters.Key<Long>("taskId")
  }
}

/** Opens the quick-add pop-up (QuickAddTaskActivity) over the home screen. */
internal fun quickAddAction(context: Context) =
    actionStartActivity(
        Intent(context, QuickAddTaskActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
    )

private data class TaskRow(val task: WidgetTask, val doneAt: Long?)

@Composable
private fun TasksContent(snapshot: WidgetSnapshot) {
  val context = LocalContext.current
  WidgetFrame {
    if (!snapshot.loggedIn) {
      SignedOut(context)
    } else {
      TaskList(context, snapshot)
    }
  }
}

@Composable
private fun TaskList(context: Context, snapshot: WidgetSnapshot) {
  val now = System.currentTimeMillis()
  val optimistic = OptimisticTicks.read(context, now)
  val rows =
      snapshot.tasks
          .map { task ->
            val tapped = optimistic[task.id]
            val doneAt =
                if (tapped != null && task.doneAt != null) minOf(tapped, task.doneAt)
                else tapped ?: task.doneAt
            TaskRow(task, doneAt)
          }
          .filter { it.doneAt == null || now - it.doneAt < TasksWidget.SHOW_DONE_MS }
  // Ticked here but not saved yet: they no longer count as pending.
  val tickedPending = snapshot.tasks.count { it.doneAt == null && optimistic.containsKey(it.id) }
  val pending = maxOf(0, snapshot.taskCount - tickedPending)

  val height = LocalSize.current.height.value
  val largest = if (height >= 220f) 6 else 3
  // Padding 32, header 40, footer 20; rows are 34 high.
  val fits = ((height - 32f - 40f - 20f) / 34f).toInt()
  val shown = rows.take(maxOf(1, minOf(largest, fits)))
  val more = pending - shown.count { it.doneAt == null }

  Column(modifier = GlanceModifier.fillMaxSize()) {
    Row(
        modifier = GlanceModifier.fillMaxWidth().height(32.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
      Row(
          modifier = GlanceModifier.defaultWeight().clickable(startApp<MainActivity>(context, WidgetLinks.workspace)),
          verticalAlignment = Alignment.CenterVertically,
      ) {
        Text("Today", style = WidgetText.section(R.color.widget_ink), maxLines = 1)
        Spacer(GlanceModifier.width(6.dp))
        Text("$pending", style = WidgetText.section(R.color.widget_muted, medium = true), maxLines = 1)
      }
      AccentCircleButton(
          icon = R.drawable.ic_widget_plus,
          description = "Add task",
          onClick = quickAddAction(context),
      )
    }
    Spacer(GlanceModifier.height(8.dp))
    if (shown.isEmpty()) {
      EmptyState(
          message = "All clear for today",
          button = "Add task",
          onClick = quickAddAction(context),
      )
    } else {
      shown.forEach { TaskRowView(context, it, now) }
      Spacer(GlanceModifier.defaultWeight())
      if (more > 0) {
        Text(
            "+$more more",
            style = WidgetText.meta(R.color.widget_muted),
            modifier =
                GlanceModifier.fillMaxWidth()
                    .height(20.dp)
                    .clickable(startApp<MainActivity>(context, WidgetLinks.workspace)),
        )
      }
    }
  }
}

@Composable
private fun TaskRowView(context: Context, row: TaskRow, now: Long) {
  val task = row.task
  val done = row.doneAt != null
  val overdue = !done && (task.overdue || (task.dueAt != null && task.dueAt < now))
  val due = WidgetFormat.taskDue(context, task, now)
  Row(
      modifier =
          GlanceModifier.fillMaxWidth()
              .height(34.dp)
              .clickable(startApp<MainActivity>(context, WidgetLinks.task(task.id))),
      verticalAlignment = Alignment.CenterVertically,
  ) {
    // 32 dp touch target around the 20 dp ring.
    Box(
        modifier =
            GlanceModifier.size(32.dp)
                .semantics { contentDescription = if (done) "Done" else "Complete ${task.title}" }
                .clickable(
                    actionRunCallback<ToggleTaskCallback>(
                        actionParametersOf(ToggleTaskCallback.TASK_ID to task.id)
                    )
                ),
        contentAlignment = Alignment.CenterStart,
    ) {
      Box(
          modifier =
              GlanceModifier.size(20.dp)
                  .background(
                      ImageProvider(
                          if (done) R.drawable.widget_checkbox_done else R.drawable.widget_checkbox_ring
                      )
                  ),
          contentAlignment = Alignment.Center,
      ) {
        if (done) {
          Image(
              provider = ImageProvider(R.drawable.ic_widget_check),
              contentDescription = null,
              modifier = GlanceModifier.size(14.dp),
              colorFilter = ColorFilter.tint(WidgetColors.of(R.color.widget_on_accent)),
          )
        }
      }
    }
    Text(
        task.title,
        style =
            WidgetText.row(
                if (done) R.color.widget_muted else R.color.widget_ink,
                decoration = if (done) TextDecoration.LineThrough else null,
            ),
        maxLines = 1,
        modifier = GlanceModifier.defaultWeight(),
    )
    if (due != null) {
      Spacer(GlanceModifier.width(8.dp))
      Text(
          due,
          style = WidgetText.meta(if (overdue) R.color.widget_danger else R.color.widget_muted),
          maxLines = 1,
      )
    }
  }
}

@Composable
private fun SignedOut(context: Context) {
  Column(
      modifier = GlanceModifier.fillMaxSize().clickable(startApp<MainActivity>(context)),
      verticalAlignment = Alignment.CenterVertically,
      horizontalAlignment = Alignment.CenterHorizontally,
  ) {
    Image(
        provider = ImageProvider(R.drawable.ic_widget_check),
        contentDescription = null,
        modifier = GlanceModifier.size(24.dp),
        colorFilter = ColorFilter.tint(WidgetColors.of(R.color.widget_accent)),
    )
    Spacer(GlanceModifier.height(8.dp))
    Text("Sign in to Daymark", style = WidgetText.section(R.color.widget_ink), maxLines = 1)
  }
}
