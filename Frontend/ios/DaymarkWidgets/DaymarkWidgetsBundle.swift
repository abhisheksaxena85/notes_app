//
//  DaymarkWidgetsBundle.swift
//  DaymarkWidgets (W-06): the home-screen and lock-screen widgets.
//

import SwiftUI
import WidgetKit

@main
struct DaymarkWidgetsBundle: WidgetBundle {
  var body: some Widget {
    TasksWidget()
    NextReminderWidget()
  }
}
