# Daymark Notes App — Figma Design Kit & Canvas Replicator

> **Superseded.** This kit documents the previous sage-green design. The current UI follows the v2 redesign spec in [`design/README.md`](../../design/README.md) (blue accent, Inter, hairline cards, new icon set and app icon). Keep this folder only for history.

This directory contains the complete design replication of the **Daymark Notes App** Flutter codebase into Figma, including both **Light and Dark themes**, animated **Splash screens**, **Figma Variable Collections**, and **Prototyping flows**.

- **Figma File URL**: [Daymark Notes App on Figma](https://www.figma.com/design/eifg2slPB4t1LBaEezrSWr/Daymark-Notes-App)
- **Figma File Key**: `eifg2slPB4t1LBaEezrSWr`

---

## 🎨 Dual Theme Design Tokens (`AppTheme` & Figma Variables)

Both **Light** and **Dark** themes have been populated as **Figma Variable Collections** in the file (`Daymark Theme - Light` and `Daymark Theme - Dark`):

| Token Name | Light Mode Hex | Dark Mode Hex | Scopes & Usage |
| :--- | :--- | :--- | :--- |
| `background` | `#F6F7F5` | `#151816` | Scaffold, canvas background, status bar area |
| `surface` | `#FFFFFF` | `#202522` | Cards, search bar, text inputs, navbar, dialogs |
| `ink` | `#252A27` | `#F0F3F1` | Primary text headings, body text, high-contrast labels |
| `muted` | `#858D87` | `#8A948C` | Secondary captions, timestamps, inactive tab icons |
| `accent` | `#5E7668` | `#739280` | Primary brand sage green: active tabs, tags, borders |
| `accentSoft` | `#EAF0EB` | `#26342B` | Tinted pill backgrounds, active chip surfaces |
| `line` | `#E8ECE8` | `#2D352F` | Structural card borders, dividers, subtle outlines |
| `danger` | `#B95E58` | `#D9726C` | Destructive actions, delete buttons, error alerts |

### Typography & Geometry Standards
- **Font Family**: `Inter` / `Roboto` / `-apple-system`
- **Mobile Viewport Geometry**: `390 x 844 pt` (iPhone 14 / standard modern mobile)
- **Corner Radii**:
  - Cards & Containers: `20px` - `22px`
  - Input Fields & Text Areas: `16px`
  - Filter & Category Tag Chips: `12px` - `14px`
  - Floating Action Button (FAB): `18px`
  - Bottom Sheet Modal: `26px` (top corners)
  - Toggle Switch: `11px` radius (40x22px capsule)

---

## 📱 Canvas Layout (All 10 Artboards in Figma)

The canvas is organized into two horizontal rows representing the **Light** and **Dark** experiences side-by-side:

### Row 1: Light Theme (Y = 0)
1. **`0. Splash Screen (Light)`** (X: 0, Y: 0) — Animated startup screen with soft sage glowing logo, branded wordmark, pulsing loading dots, and version footer.
2. **`1. Notes Screen (Home)`** (X: 440, Y: 0) — Main dashboard with greeting, search bar, active tag filter chips, masonry note cards, pinned badge, FAB, and bottom navigation.
3. **`2. Note Editor Bottom Sheet`** (X: 880, Y: 0) — Modal sheet with drag handle, pin toggle, title field, multiline note body, tag creation input, active tag chips, and full-width save action button.
4. **`3. Calendar & Activity Screen`** (X: 1320, Y: 0) — Interactive month calendar grid with date activity indicators, horizontal weekly scrolling strip, and selected day note cards.
5. **`4. Profile Screen (Light)`** (X: 1760, Y: 0) — User avatar card, note stats summary, Preferences group with **Dark Theme Toggle Switch (OFF state)**, and Data/Support options.

### Row 2: Dark Theme (Y = 940)
6. **`0. Splash Screen (Dark)`** (X: 0, Y: 940) — Dark OLED-friendly startup screen with high-contrast sage insignia and animated entry.
7. **`1. Notes Screen (Home - Dark)`** (X: 440, Y: 940) — Night mode dashboard with rich charcoal surfaces (`#202522`) and mint sage accents (`#739280`).
8. **`2. Note Editor Bottom Sheet (Dark)`** (X: 880, Y: 940) — Dark modal editor sheet with dim backdrop (`#000000`, 65% opacity) and high-readability text fields.
9. **`3. Calendar & Activity Screen (Dark)`** (X: 1320, Y: 940) — Dark calendar view highlighting note activity dots and selected day badge.
10. **`4. Profile Screen (Dark)`** (X: 1760, Y: 940) — Dark profile view featuring an **active green Dark Theme Toggle Switch (ON state)**.

---

## ⚡ Splash Screen Animation & Prototyping Interactions

### 1. Startup Entry Animation
The Splash Screen includes timed staggered entry choreography:
- **Logo (`SplashLogo`)**: Fades from `opacity: 0` to `1`, scales from `0.85` to `1.0`, and translates vertically by `+18px` to resting position with `EASE_OUT` easing (0.0s – 0.7s).
- **Brand Title & Tagline (`SplashText`)**: Fades in with subtle vertical translation from 0.25s – 0.85s.
- **Pulsing Indicator (`SplashIndicator`)**: Fades in from 0.5s – 1.1s.
- **Footer (`SplashFooter`)**: Gentle appearance at 0.7s – 1.3s.

### 2. Prototyping Flows
- **Splash to Home Auto-Transition**:
  - `0. Splash Screen (Light)` ➔ `AFTER_TIMEOUT` (2000ms) ➔ `SMART_ANIMATE` (400ms, Ease Out) ➔ `1. Notes Screen (Home)`.
  - `0. Splash Screen (Dark)` ➔ `AFTER_TIMEOUT` (2000ms) ➔ `SMART_ANIMATE` (400ms, Ease Out) ➔ `1. Notes Screen (Home - Dark)`.
- **Interactive Dark Mode Toggle**:
  - In `4. Profile Screen (Light)`, tapping the **Dark Theme switch** ➔ `ON_CLICK` ➔ `SMART_ANIMATE` (300ms) ➔ `4. Profile Screen (Dark)`.
  - In `4. Profile Screen (Dark)`, tapping the **active green switch** ➔ `ON_CLICK` ➔ `SMART_ANIMATE` (300ms) ➔ `4. Profile Screen (Light)`.

---

## 📁 Vector SVG Assets

All 10 vector screens are saved in [`figma_design/screens/`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens):

| Screen Name | Light Mode SVG | Dark Mode SVG |
| :--- | :--- | :--- |
| **0. Splash Screen** | [`splash_screen.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/splash_screen.svg) | [`splash_screen_dark.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/splash_screen_dark.svg) |
| **1. Notes Screen (Home)** | [`notes_screen.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/notes_screen.svg) | [`notes_screen_dark.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/notes_screen_dark.svg) |
| **2. Note Editor Bottom Sheet** | [`note_editor_sheet.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/note_editor_sheet.svg) | [`note_editor_sheet_dark.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/note_editor_sheet_dark.svg) |
| **3. Calendar & Activity** | [`calendar_screen.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/calendar_screen.svg) | [`calendar_screen_dark.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/calendar_screen_dark.svg) |
| **4. Profile & Settings** | [`profile_screen.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/profile_screen.svg) | [`profile_screen_dark.svg`](file:///Volumes/Crucial_X6/Documents/Projects/Full%20Stack%20Projects/Notes%20App/Frontend/figma_design/screens/profile_screen_dark.svg) |

---
*Created for Daymark Notes App.*
