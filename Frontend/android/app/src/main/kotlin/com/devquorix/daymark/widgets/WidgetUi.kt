package com.devquorix.daymark.widgets

import android.os.Build
import androidx.annotation.ColorRes
import androidx.annotation.DrawableRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ColumnScope
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextDecoration
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.devquorix.daymark.R

/**
 * Colours come from resources (values/ and values-night/colors.xml), so the widgets follow the
 * system light/dark setting without the app (design/README.md §1).
 */
object WidgetColors {
  fun of(@ColorRes color: Int): ColorProvider = ColorProvider(color)
}

/** The design's type scale in the system sans-serif (Glance can't load Inter). */
object WidgetText {
  private fun style(
      @ColorRes color: Int,
      size: TextUnit,
      weight: FontWeight,
      decoration: TextDecoration? = null,
  ) = TextStyle(color = WidgetColors.of(color), fontSize = size, fontWeight = weight, textDecoration = decoration)

  /** 15 / 600: "Today", the reminder title. */
  fun section(@ColorRes color: Int, medium: Boolean = false) =
      style(color, 15.sp, if (medium) FontWeight.Medium else FontWeight.Bold)

  /** 14 / 500: a task row. */
  fun row(@ColorRes color: Int, decoration: TextDecoration? = null) =
      style(color, 14.sp, FontWeight.Medium, decoration)

  /** 12.5 / 400: times and captions. */
  fun meta(@ColorRes color: Int) = style(color, 12.5.sp, FontWeight.Normal)

  /** 12 / 400: "Next reminder". */
  fun caption(@ColorRes color: Int) = style(color, 12.sp, FontWeight.Normal)

  /** 13 / 600: buttons. */
  fun button(@ColorRes color: Int) = style(color, 13.sp, FontWeight.Bold)
}

/** OS-standard corners (Android 12+), the surface colour and 16 dp padding. */
@Composable
internal fun WidgetFrame(content: @Composable ColumnScope.() -> Unit) {
  var modifier =
      GlanceModifier.fillMaxSize()
          .appWidgetBackground()
          .background(ImageProvider(R.drawable.widget_background))
  if (Build.VERSION.SDK_INT >= 31) {
    modifier = modifier.cornerRadius(android.R.dimen.system_app_widget_background_radius)
  }
  Column(modifier = modifier.padding(16.dp), content = content)
}

/** A 32 dp accent circle with an [icon] (the quick-add plus). */
@Composable
internal fun AccentCircleButton(@DrawableRes icon: Int, description: String, onClick: Action) {
  Box(
      modifier =
          GlanceModifier.size(32.dp)
              .background(ImageProvider(R.drawable.widget_circle_accent))
              .semantics { contentDescription = description }
              .clickable(onClick),
      contentAlignment = Alignment.Center,
  ) {
    Image(
        provider = ImageProvider(icon),
        contentDescription = null,
        modifier = GlanceModifier.size(18.dp),
        colorFilter = ColorFilter.tint(WidgetColors.of(R.color.widget_on_accent)),
    )
  }
}

/** An accent pill button. */
@Composable
internal fun AccentButton(label: String, onClick: Action, modifier: GlanceModifier = GlanceModifier) {
  Box(
      modifier =
          modifier
              .background(ImageProvider(R.drawable.widget_button_accent))
              .padding(horizontal = 14.dp, vertical = 8.dp)
              .clickable(onClick),
      contentAlignment = Alignment.Center,
  ) {
    Text(label, style = WidgetText.button(R.color.widget_on_accent), maxLines = 1)
  }
}

/** A centred message with one button (empty states). */
@Composable
internal fun ColumnScope.EmptyState(message: String, button: String, onClick: Action) {
  Column(
      modifier = GlanceModifier.defaultWeight().fillMaxSize(),
      verticalAlignment = Alignment.CenterVertically,
      horizontalAlignment = Alignment.CenterHorizontally,
  ) {
    Text(message, style = WidgetText.row(R.color.widget_muted), maxLines = 2)
    Spacer(GlanceModifier.height(10.dp))
    AccentButton(button, onClick)
  }
}
