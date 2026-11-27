//
//  WidgetStyle.swift
//  DaymarkWidgets (W-06): design tokens (design/README.md §1) that follow the
//  system light/dark setting, and shared pieces.
//

import SwiftUI
import UIKit
import WidgetKit

extension Color {
  fileprivate static func daymark(_ light: UInt32, _ dark: UInt32) -> Color {
    Color(
      UIColor { traits in
        let hex = traits.userInterfaceStyle == .dark ? dark : light
        return UIColor(
          red: CGFloat((hex >> 16) & 0xFF) / 255,
          green: CGFloat((hex >> 8) & 0xFF) / 255,
          blue: CGFloat(hex & 0xFF) / 255,
          alpha: 1)
      })
  }
}

enum Palette {
  static let surface = Color.daymark(0xFBFBFA, 0x25262A)
  static let ink = Color.daymark(0x2A2B2F, 0xE8E8E5)
  static let muted = Color.daymark(0x6A6C72, 0xA0A2A8)
  static let accent = Color.daymark(0x2F6BDB, 0x6B9BF2)
  /// accent mixed 12 % (light) / 20 % (dark) over surface.
  static let accentSoft = Color.daymark(0xE3EAF6, 0x333D52)
  static let onAccent = Color.daymark(0xFBFBFA, 0x1C1D20)
  static let success = Color.daymark(0x2F7A52, 0x5FB386)
  static let danger = Color.daymark(0xB8433B, 0xE8897F)
}

extension View {
  /// The widget's surface; iOS 17 adds the standard 16 pt margins itself.
  @ViewBuilder
  func daymarkBackground(_ color: Color = Palette.surface) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(color, for: .widget)
    } else {
      padding(16).background(color)
    }
  }
}

/// The 32 pt accentSoft tile with the bell (ic_reminder).
struct BellTile: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 10, style: .continuous)
      .fill(Palette.accentSoft)
      .frame(width: 32, height: 32)
      .overlay(
        Image("ic_reminder").renderingMode(.template).resizable()
          .frame(width: 18, height: 18)
          .foregroundStyle(Palette.accent)
      )
  }
}

/// An accent pill (Done, Add task, New reminder).
struct AccentPill: View {
  let label: String

  var body: some View {
    Text(label)
      .font(.system(size: 13, weight: .semibold))
      .foregroundStyle(Palette.onAccent)
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(Palette.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

/// A button that runs [url] as a widget action: in place on iOS 17, by
/// opening the app (which applies it) on iOS 15 and 16.
struct WidgetActionButton<Label: View>: View {
  let url: URL
  @ViewBuilder let label: () -> Label

  var body: some View {
    if #available(iOSApplicationExtension 17.0, *) {
      Button(intent: DaymarkWidgetIntent(url: url), label: label).buttonStyle(.plain)
    } else {
      Link(destination: url, label: label)
    }
  }
}
