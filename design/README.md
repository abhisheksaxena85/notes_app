# Daymark — UI redesign spec (v2, "lighter")

The source of truth for the redesign. The visual mockups live on the design canvas:
https://claude.ai/artifact/5fNFpQwzriQRzZB2atnQut (only the project owner can open it). Everything needed to build it is written here, so the canvas is optional.

**Look:** soft off-white and soft charcoal (never pure `#FFFFFF` / `#000000`), the Inter typeface, cards with a 0.5 px soft border and a soft shadow (§3), and **one accent colour** used only for primary buttons, the active tab, checkboxes, links and key icons.

**Accent:** **blue is the default.** Dark orange is also defined, and switching between them is a one-line change (`DaymarkAccent.current`).

---

## 1. Colour tokens

| Token | Light | Dark | Used for |
|---|---|---|---|
| `background` | `#F3F3F1` | `#1C1D20` | Scaffold |
| `surface` | `#FBFBFA` | `#25262A` | Cards, sheets, nav bar (dark nav `#222327`) |
| `surfaceMuted` | `#EAEAE7` | `#2A2B2F` | Search field, segmented-control track, tag chips (`#EDEDEA` light) |
| `iconTile` | `#EFEFEC` | `#2E2F34` | 32 px neutral icon tiles in settings rows, close button |
| `ink` | `#2A2B2F` | `#E8E8E5` | Primary text and icons |
| `inkSecondary` | `#45474D` | `#C4C5C9` | Body previews, unselected chip text |
| `muted` | `#6A6C72` | `#A0A2A8` | Meta text, inactive nav, placeholders (passes 4.5:1) |
| `disabled` | `#B4B5B9` | `#5E6066` | Out-of-month days, disabled icons |
| `line` | `#E3E3DF` | `#34363C` | Input and button borders; dividers (`#ECECE8`) |
| `cardBorder` | `#E9E9E5` | `#33353A` | Card borders, 0.5 px (§3) |
| `chipBorder` | `#DCDCD8` | `#3A3B41` | Unselected filter and category chips |
| `accent` (blue) | `#2F6BDB` | `#6B9BF2` | Primary actions |
| `accent` (dark orange) | `#B9501A` | `#E0793A` | Alternative accent |
| `onAccent` | `#FBFBFA` | `#1C1D20` | Text and icons on an accent fill |
| `accentSoft` | accent mixed 12 % over `surface` | accent mixed 20 % over `surface` | Active nav pill, selected chip fill, reminder icon tile, info rows. Compute it with `Color.lerp(surface, accent, 0.12 / 0.20)`. |
| `success` | `#2F7A52` | `#5FB386` | Completed check, "Done" label |
| `successSoft` | `#E6F0EA` | `#22332A` | Completed icon tile |
| `danger` | `#B8433B` | `#E8897F` | Missed, destructive, high priority |
| `dangerSoft` | `#F6E6E4` | `#3A2826` | Missed pill and tile |
| `scrim` | `rgba(32,33,36,0.38)` | `rgba(0,0,0,0.5)` | Behind bottom sheets |
| `skeletonBase` / `skeletonHighlight` | `#E6E6E2` / `#F2F2EF` | `#2C2D31` / `#38393E` | Shimmer |

The previous sage-green palette (`#5E7668` and friends) is retired. Status colours keep their meaning: pending = accent, completed = success, missed/rejected = danger.

## 2. Typography (Inter, via `google_fonts`)

| Style | Size / weight / letter-spacing | Use |
|---|---|---|
| `display` | 26 / 600 / -0.5 | Note title in the editor |
| `title` | 24 / 600 / -0.4 | Screen titles, greeting |
| `sheetTitle` | 19 / 600 / -0.3 | Bottom-sheet titles |
| `section` | 15 / 600 | Section headers ("Tasks 3"), with the count in `muted` 500 |
| `bodyStrong` | 15 / 500 | Card titles |
| `body` | 15.5 / 400 / height 1.6 | Note body |
| `preview` | 13.5 / 400 / height 1.45 | Note preview (2 lines max) |
| `meta` | 12.5 / 400 | Times, categories, captions |
| `label` | 12.5 / 500 | Form field labels |
| `overline` | 12 / 600 / +0.3, uppercase | Group labels ("PREFERENCES", "TAGS") |
| `chip` | 13 / 500 (600 when selected) | Chips, segmented controls |
| `button` | 15 / 600 | Primary buttons |
| `nav` | 11.5 / 500 (600 active) | Bottom-nav labels |

## 3. Shape, spacing, elevation

- **Cards** (`DaymarkCard`, `lib/views/widgets/daymark_card.dart`) are used for every card: task, reminder and note cards, stat cards, the calendar month card and day list, the profile card and the settings groups. Each card is a `surface` fill with:
  - **Border:** 0.5 px in `cardBorder` (`#E9E9E5` light, `#33353A` dark).
  - **Shadow, light:** two soft layers, `ink` at 5 % (blur 14, y 4) plus `ink` at 3 % (blur 3, y 1).
  - **Shadow, dark:** one layer, black at 28 % (blur 16, y 6). The hairline border stays.
  - **Performance:** a single `DecoratedBox` with a const `BoxDecoration` per theme and radius, so long lists stay smooth. Cards add no clip layer. Only grouped cards whose rows are tappable edge to edge (the settings groups and the calendar day list) clip their content to the corners.
- **No shadow** on chips, inputs, buttons, or the rows and tiles inside a card.
- **Radius:**
  - card 18 · large card (month card, profile card) 22
  - input 14 · primary button 16 · FAB 18
  - filter chip pill (height 34) 17 · category chip pill (height 32) 16 · tag chip 7–9
  - icon tile 10–11 · sheet top corners 26 · avatar = circle
- **Spacing:**
  - Screen horizontal padding 20 (note editor 22). Content starts 8 below the safe area (about 52 from the top on a notched phone).
  - Section gap 22. **Gap between cards 10**, stacked or side by side (stat cards).
  - **Card padding 16.** Stat cards use 14 × 12. The month card uses 14 at the sides with 10 above the grid.
  - **Title to meta line 6** inside item cards.
  - Bottom-nav height 74.
- **Elevation:** apart from cards, shadows are used in only three places:
  - the FAB (`accent` at 30 % opacity, blur 20, y 8);
  - the add-menu pills (`black` 35 % in dark mode);
  - the selected Month / Week segment (a tiny shadow).

  Bottom sheets and dialogs sit on the scrim with no shadow.
- **Loading skeletons** use the real card (same border, shadow, radius and padding). Only the contents shimmer.
- **Touch targets:** at least 44×44 for every tappable icon.
- **Don't use** coloured left-edge strips on cards (the old status strip is removed), gradients, or emoji.

## 4. Icons

40 icons in `Frontend/assets/icons/ic_*.svg`: 24 px grid, 1.6 stroke, round caps and joins, drawn in `currentColor` so `AppIcons.icon(path, color: …)` tints them. `ic_more.svg` is filled dots. `logo_mark.svg` is the app icon tile, used on the splash and login screens.

Sizes: 20 in the nav and top bars, 18 in cards and fields, 14 inline with meta text, 22–24 in the FAB.

| Old asset | New asset |
|---|---|
| `nav_notes.svg` | `ic_workspace.svg` (Workspace tab) |
| `nav_calendar.svg` | `ic_calendar.svg` |
| `nav_profile.svg` | `ic_profile.svg` |
| `notes.svg` | `ic_note.svg` |
| `search.svg` | `ic_search.svg` |
| `pin.svg` | `ic_pin.svg` |
| `clock.svg` | `ic_clock.svg` |
| `arrow_up_right.svg` | `ic_open.svg` |
| `more_dots.svg` | `ic_more.svg` |
| `moon.svg` | `ic_dark_mode.svg` |
| `sliders.svg` | `ic_preferences.svg` |
| `bell.svg` | `ic_reminder.svg` |
| `shield.svg` | `ic_privacy.svg` |
| `cloud.svg` | `ic_backup.svg` |
| `help.svg` | `ic_help.svg` |
| `info.svg` | `ic_info.svg` |
| `check_circle.svg` | `ic_done.svg` |
| `splash_emblem.svg` | `logo_mark.svg` |

New icons with no old equivalent: `task, plus, close, check, snooze, repeat, priority, tag, category, edit, delete, filter, light_mode, sync, export, import, sign_out, email, password, show, back, forward, expand`. Replace Material `Icons.*` usages with these wherever one matches.

## 5. App icon — direction A, "Marked day" (final)

A soft-charcoal tile (`#2A2B2F`) with an off-white calendar page (`#F3F3F1`) and a blue check (`#2F6BDB`).

| File | What it is |
|---|---|
| `design/app_icon/app_icon.svg` → `Frontend/assets/app_icon/app_icon.png` | 1024 px, full-bleed square, no transparency (iOS and legacy Android; the OS rounds the corners) |
| `design/app_icon/app_icon_foreground.svg` → `…/app_icon_foreground.png` | Android adaptive foreground. Transparent, with the glyph inside the 66 dp safe zone. Background colour `#2A2B2F`. |
| `design/app_icon/app_icon_monochrome.svg` → `…/app_icon_monochrome.png` | Android 13+ themed-icon layer (single colour, check cut out) |
| `design/app_icon/notification_icon.svg` (+ `notification_icon_96.png` preview) | White silhouette for the Android status-bar small icon. It replaces the current `ic_stat_daymark` drawable as a vector drawable. |

The icon keeps the blue check even if the accent is switched to orange.

## 6. Components

**Bottom nav:** 3 items (Workspace, Calendar, Profile) on `surface` with a top hairline. The active item has its icon inside a 60×30 `accentSoft` pill, with icon and label in `accent` at weight 600. Inactive items use `muted`.

**Header (Workspace):** date line (`meta`, `muted`, e.g. "Friday, 27 November"), then the greeting "Good morning, {firstName}" (`title`). On the right, a 44 px avatar circle (`accentSoft` fill, initials in `accent`) that opens Profile. The greeting changes with the time of day: morning / afternoon / evening.

**Stats row:** three equal cards (the shared card, padding 14 × 12, 10 apart): a number (16/600) over a label (12, `muted`). Labels: "tasks today", "reminders", "notes".

**Search:** height 44, radius 14, `surfaceMuted` fill, no border, search icon in `muted`, placeholder "Search notes, tasks, reminders".

**Filter chips (All / Notes / Tasks / Reminders):** height 34. Selected = `ink` fill with `background`-coloured text (dark mode: `#E8E8E5` fill, `#1C1D20` text). Unselected = transparent with a `chipBorder` outline and `inkSecondary` text.

**Section header:** "Tasks" plus the count in `muted`, with "See all" in `accent` on the right.

**Task card:** the shared card (§3: padding 16, radius 18, 10 between cards). Leading 24 px round checkbox:
- pending: 1.6 px `accent` ring.
- completed: `success` fill with a white check. The title switches to `muted` with strikethrough, and the meta line shows "Done" in `success`.
- missed / rejected: 1.6 px `danger` ring plus a "Missed" / "Rejected" pill (`dangerSoft` fill, `danger` text, 12/600, radius 8).

The title is `bodyStrong`. The meta line has a clock icon and time · category · priority (High shows a `danger` flag icon and label).

**Reminder card:** leading 36 px tile (radius 11) with the bell icon: `accentSoft` with `accent` when pending, `dangerSoft` with `danger` when missed, `successSoft` with `success` when completed. Then the title, then a meta line with the time and, for repeating reminders, the repeat icon plus "Daily / Weekly / Monthly". On the right, a "Today" label in `accent`, or the Missed pill.

**Note card:** a category overline (12/500, `muted`) with a pin icon in `accent` on the right when pinned. Then the title (15/600) and the preview (`preview`, max 2 lines). Footer: tag chips (`#EDEDEA` fill, 12, radius 7) and the relative time on the right in `muted`.

**FAB and add menu:** 56×56, radius 18, `accent` fill, plus icon in `onAccent`, 20 from the right edge and 18 above the nav. Tapping it opens the add menu: three rows stacked above the FAB, each a label pill (`#34353A` dark / `surface` light, 14/500, radius 12) plus a 48 px icon tile (radius 15) with an `accent` icon, for New note, New task and New reminder. The FAB icon turns into a close icon. Animate with a 200 ms scale and fade, staggered by 30 ms.

**Calendar:** the "Calendar" title with a Month / Week segmented control on the right (`surfaceMuted` track, selected segment `surface` with a tiny shadow). The month card (the shared card, radius 22) has chevrons, the month name (15/600), weekday initials (11.5/500, `muted`) and a 7-column grid of 42 px cells:
- the day number sits in a 30 px circle; the selected day has an `accent` fill with `onAccent` text;
- out-of-month days use `disabled`;
- below the number, a count badge (height 13, min-width 16, 9.5/600, `accentSoft` with `accent` text; inverted on the selected day) shows notes + tasks + reminders.

Below the card: "Friday, 27 November" plus "4 items", then one grouped card with dividers. Each row has a 34 px type tile (task = `accentSoft`/`accent`, completed = `successSoft`/`success`, reminder = `accentSoft`/`accent`, note = `#EDEDEA`/`inkSecondary`), the title (14.5/500) and the meta "Task · 10:30 AM".

**Note editor:** top bar with back (44), "Edit note" (15/600) and pin (`accent`, filled at 15 % when pinned) and more. The title is a borderless `display` text field. Meta: "Created 24 Nov · Edited 2h ago". Category chips are horizontally scrollable (General, Work, Personal, Planning, Ideas, Study); selected = `accent` border + `accentSoft` fill + `accent` text at 600. Then a hairline, the body as a borderless `body` text field, and the TAGS overline with tag chips (remove ×) plus a dashed "+ Add tag" chip in `accent`. Bottom bar on `background` with a top hairline: a 52 px delete button (`surface`, `danger` icon, border `#E3D3D1`) and a "Save note" primary button that fills the rest of the row.

**Bottom sheets (new/edit task, new/edit reminder):** `surface`, radius 26 at the top, a 40×4 handle, the title (`sheetTitle`) and a 40 px close button (`iconTile`).
- Every field has a `label` above a 48 px input (radius 14; focused border 1.5 px `accent`; idle `background` fill with a `line` border).
- Date and Time sit side by side, each with an `accent` icon.
- Repeat is a 4-way segmented control (None, Daily, Weekly, Monthly).
- Category chips work the same as in the note editor.
- Reminders get an info row (`accentSoft`, radius 14, bell icon): "You'll get a notification at 6:00 PM. Mark it Done, Not done or Snooze right from it."
- Primary button at the bottom: "Create reminder" / "Save changes".

**Profile:** the "Profile" title, then the profile card (56 px avatar, name 17/600, email 13 `muted`, 40 px outlined edit button) and three stat cards (Notes, Tasks done, Reminders). Grouped lists follow, PREFERENCES (Appearance → System/Light/Dark, Notifications → On/Off in `accent`) and DATA & SUPPORT (Data & backup → Synced, Privacy & security, Help & FAQ, About Daymark → v1.0.0). Each row is 52 px with a 32 px `iconTile` and an `inkSecondary` icon, the label (14.5/500), the value in `muted`, and a chevron. At the bottom, a "Sign out" outlined button (`danger` text, border `#E8D5D3`).

**Primary button:** height 52, radius 16, `accent` fill, `onAccent` 15/600 text. Disabled: `#E3E3DF` fill with `#8A8C91` text (dark mode `#2E2F34` / `#5E6066`).

**Reminder notification (OS):** title = reminder title, body "Due 6:00 PM · Repeats daily", actions **Done**, **Not done**, **Snooze 10 min**. Android: small icon = `notification_icon`, colour = `accent`. Tapping it opens the in-app sheet: a 48 px `accentSoft` bell tile, then "Did you {title}?" (19/600), the meta line, a full-width Done primary button with a check icon, and two outlined half-width buttons: Not done, and Snooze 10 min (with `ic_snooze`).

**Login and register:** same tokens. `logo_mark` at 56 px, "Daymark" (24/600), a subtitle in `muted`, labelled 48 px inputs (`email`, `password` with the `show` toggle) and the primary button. Keep the existing fields and validation.

## 7. Loading states (shimmer)

Use a skeleton instead of a spinner on every screen that loads data: Workspace, Calendar, Note editor and Profile, in both themes. Bottom sheets that open empty don't need one.

- **Shimmer:** a linear gradient `skeletonBase → skeletonHighlight → skeletonBase` (stops 0.25 / 0.37 / 0.63) sweeping left to right, 1.4 s, ease, looping. All skeleton blocks on screen share one animation controller so they sweep together. When `MediaQuery.disableAnimations` is true, show static `skeletonBase` blocks. Wrap the screen in `Semantics(label: 'Loading…', liveRegion: true)`.
- **Bars:** text bars are 10–14 px tall with a radius of half their height, and widths vary (35–75 %) so it doesn't look like a grid. Circles and tiles keep their real sizes and radii.
- **Workspace:** shimmer the date and greeting, the avatar, the three stats, the search bar, 4 chips, section headers, and 2 task, 2 reminder and 1 note card shapes. Cards keep their real `surface` and border; only their contents shimmer. The FAB is shown at 45 % opacity and disabled. The nav is fully real.
- **Calendar:** the title, the segmented control, the month name and the whole date grid are real (they don't need data). Only the count badges (16×8 bars) and the day list (4 rows: 34 px tile + 2 bars) shimmer. The "4 items" count is a bar.
- **Note editor:** the top bar title and back button are real; pin and more are 28 px blocks. Shimmer the title (72 % × 26), the meta, 4 category chips, about 10 body lines in paragraph groups, and 2 tag chips. Save is disabled and delete is greyed out.
- **Profile:** the title, group labels and setting labels are real. Shimmer the avatar, name, email, edit button, stat numbers and labels, and the setting values. "Sign out" is shown faded.

Build one reusable widget set in `lib/views/widgets/skeleton/`: `Shimmer` (the controller and gradient shader), `SkeletonBox(width, height, radius)`, `SkeletonLine(widthFactor, height)` and `SkeletonCircle(size)`. Each screen gets its own `*_loading_widget.dart` using them.
