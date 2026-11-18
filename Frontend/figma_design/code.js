// Daymark Notes App - Figma Canvas Generator
// Replicates the entire Flutter codebase's design, tokens, and screens directly onto the Figma canvas.

async function main() {
  figma.notify("Generating Daymark Notes App UI...");

  // 1. Load Required Fonts
  await figma.loadFontAsync({ family: "Inter", style: "Regular" });
  await figma.loadFontAsync({ family: "Inter", style: "Medium" });
  await figma.loadFontAsync({ family: "Inter", style: "Semi Bold" });
  await figma.loadFontAsync({ family: "Inter", style: "Bold" });

  // 2. Color Tokens Definition (RGB 0..1)
  const colors = {
    background: { r: 246 / 255, g: 247 / 255, b: 245 / 255 }, // #F6F7F5
    surface: { r: 1, g: 1, b: 1 },                             // #FFFFFF
    ink: { r: 37 / 255, g: 42 / 255, b: 39 / 255 },           // #252A27
    muted: { r: 133 / 255, g: 141 / 255, b: 135 / 255 },      // #858D87
    accent: { r: 94 / 255, g: 118 / 255, b: 104 / 255 },      // #5E7668
    accentSoft: { r: 234 / 255, g: 240 / 255, b: 235 / 255 },  // #EAF0EB
    line: { r: 232 / 255, g: 236 / 255, b: 232 / 255 },        // #E8ECE8
    danger: { r: 185 / 255, g: 94 / 255, b: 88 / 255 },       // #B95E58
  };

  // Helper: Create solid paint
  function solid(color, opacity = 1) {
    return [{ type: 'SOLID', color: color, opacity: opacity }];
  }

  // 3. Create Paint Styles in Document
  const paintStyles = {};
  const styleDefs = [
    { name: "Daymark/Background", color: colors.background },
    { name: "Daymark/Surface", color: colors.surface },
    { name: "Daymark/Ink", color: colors.ink },
    { name: "Daymark/Muted", color: colors.muted },
    { name: "Daymark/Accent", color: colors.accent },
    { name: "Daymark/AccentSoft", color: colors.accentSoft },
    { name: "Daymark/Line", color: colors.line },
    { name: "Daymark/Danger", color: colors.danger },
  ];

  for (const def of styleDefs) {
    let existing = figma.getLocalPaintStyles().find(s => s.name === def.name);
    if (!existing) {
      existing = figma.createPaintStyle();
      existing.name = def.name;
      existing.paints = solid(def.color);
    }
    paintStyles[def.name] = existing;
  }

  // Helper: Create Text Node
  function createText(characters, fontSize, fontWeight = "Regular", color = colors.ink, options = {}) {
    const text = figma.createText();
    text.fontName = { family: "Inter", style: fontWeight };
    text.characters = characters;
    text.fontSize = fontSize;
    text.fills = solid(color);
    if (options.letterSpacing) text.letterSpacing = { value: options.letterSpacing, unit: "PIXELS" };
    if (options.lineHeight) text.lineHeight = { value: options.lineHeight, unit: "PIXELS" };
    return text;
  }

  // Helper: Create Chip/Pill
  function createPill(text, bgColor, textColor, paddingH = 10, paddingV = 5) {
    const frame = figma.createFrame();
    frame.name = "Pill / " + text;
    frame.layoutMode = "HORIZONTAL";
    frame.primaryAxisSizingMode = "AUTO";
    frame.counterAxisSizingMode = "AUTO";
    frame.paddingLeft = paddingH;
    frame.paddingRight = paddingH;
    frame.paddingTop = paddingV;
    frame.paddingBottom = paddingV;
    frame.cornerRadius = 30;
    frame.fills = solid(bgColor);

    const label = createText(text, 10, "Semi Bold", textColor);
    frame.appendChild(label);
    return frame;
  }

  // Helper: Create Note Card
  function createNoteCard(title, content, tags, date, isPinned = false) {
    const card = figma.createFrame();
    card.name = "NoteCard / " + title;
    card.layoutMode = "VERTICAL";
    card.primaryAxisSizingMode = "AUTO";
    card.counterAxisSizingMode = "FIXED";
    card.resize(350, 150);
    card.paddingLeft = 17;
    card.paddingRight = 15;
    card.paddingTop = 15;
    card.paddingBottom = 15;
    card.itemSpacing = 9;
    card.cornerRadius = 20;
    card.fills = solid(colors.surface);
    card.strokes = solid(colors.line);
    card.strokeWeight = 1;

    // Header row (Title + Pin + Options)
    const headerRow = figma.createFrame();
    headerRow.layoutMode = "HORIZONTAL";
    headerRow.primaryAxisSizingMode = "FIXED";
    headerRow.counterAxisSizingMode = "AUTO";
    headerRow.resize(318, 22);
    headerRow.primaryAxisAlignItems = "SPACE_BETWEEN";
    headerRow.counterAxisAlignItems = "CENTER";
    headerRow.fills = [];

    const titleText = createText(title, 16, "Bold", colors.ink);
    titleText.layoutGrow = 1;
    headerRow.appendChild(titleText);

    if (isPinned) {
      const pinText = createText("📌", 12, "Regular", colors.accent);
      headerRow.appendChild(pinText);
    }

    const moreText = createText("•••", 11, "Bold", colors.muted);
    headerRow.appendChild(moreText);
    card.appendChild(headerRow);

    // Body content
    const bodyText = createText(content, 13, "Regular", colors.muted, { lineHeight: 18 });
    bodyText.resize(318, 36);
    card.appendChild(bodyText);

    // Tags Row
    if (tags && tags.length > 0) {
      const tagsRow = figma.createFrame();
      tagsRow.layoutMode = "HORIZONTAL";
      tagsRow.itemSpacing = 6;
      tagsRow.primaryAxisSizingMode = "AUTO";
      tagsRow.counterAxisSizingMode = "AUTO";
      tagsRow.fills = [];
      for (const t of tags) {
        tagsRow.appendChild(createPill(t, colors.accentSoft, colors.accent, 8, 4));
      }
      card.appendChild(tagsRow);
    }

    // Footer (Date + Arrow)
    const footer = figma.createFrame();
    footer.layoutMode = "HORIZONTAL";
    footer.primaryAxisSizingMode = "FIXED";
    footer.counterAxisSizingMode = "AUTO";
    footer.resize(318, 16);
    footer.primaryAxisAlignItems = "SPACE_BETWEEN";
    footer.fills = [];

    const dateText = createText("🕒 " + date, 11, "Regular", colors.muted);
    footer.appendChild(dateText);

    const arrowText = createText("↗", 12, "Medium", colors.muted);
    footer.appendChild(arrowText);

    card.appendChild(footer);
    return card;
  }

  // Helper: Create Bottom Nav Bar
  function createBottomNav(activeTab = "Notes") {
    const nav = figma.createFrame();
    nav.name = "BottomNavigationBar";
    nav.layoutMode = "HORIZONTAL";
    nav.resize(390, 68);
    nav.primaryAxisAlignItems = "SPACE_BETWEEN";
    nav.counterAxisAlignItems = "CENTER";
    nav.paddingLeft = 32;
    nav.paddingRight = 32;
    nav.fills = solid(colors.surface);
    nav.strokes = solid(colors.line);
    nav.strokeWeight = 1;

    const tabs = [
      { name: "Notes", icon: "📝" },
      { name: "Calendar", icon: "📅" },
      { name: "Profile", icon: "👤" },
    ];

    for (const tab of tabs) {
      const isSelected = tab.name === activeTab;
      const tabFrame = figma.createFrame();
      tabFrame.layoutMode = "VERTICAL";
      tabFrame.primaryAxisAlignItems = "CENTER";
      tabFrame.counterAxisAlignItems = "CENTER";
      tabFrame.itemSpacing = 4;
      tabFrame.paddingLeft = 14;
      tabFrame.paddingRight = 14;
      tabFrame.paddingTop = 6;
      tabFrame.paddingBottom = 6;
      tabFrame.cornerRadius = 14;
      tabFrame.fills = isSelected ? solid(colors.accentSoft) : [];

      const icon = createText(tab.icon, 16, "Regular", isSelected ? colors.ink : colors.muted);
      const label = createText(tab.name, 11, isSelected ? "Bold" : "Medium", isSelected ? colors.ink : colors.muted);
      tabFrame.appendChild(icon);
      tabFrame.appendChild(label);
      nav.appendChild(tabFrame);
    }
    return nav;
  }

  // ==========================================
  // SCREEN 1: NOTES SCREEN (HOME)
  // ==========================================
  const screen1 = figma.createFrame();
  screen1.name = "1. Notes Screen (Home)";
  screen1.resize(390, 844);
  screen1.x = 0;
  screen1.y = 0;
  screen1.fills = solid(colors.background);
  screen1.clipsContent = true;

  // Header
  const s1Header = figma.createFrame();
  s1Header.name = "Header";
  s1Header.layoutMode = "VERTICAL";
  s1Header.x = 20;
  s1Header.y = 54;
  s1Header.resize(350, 85);
  s1Header.itemSpacing = 5;
  s1Header.fills = [];

  const topRow = figma.createFrame();
  topRow.layoutMode = "HORIZONTAL";
  topRow.resize(350, 24);
  topRow.primaryAxisAlignItems = "SPACE_BETWEEN";
  topRow.fills = [];
  topRow.appendChild(createText("GOOD DAY, EMIAI", 10, "Bold", colors.muted, { letterSpacing: 1.2 }));
  topRow.appendChild(createPill("3 NOTES", colors.accentSoft, colors.accent, 10, 4));
  s1Header.appendChild(topRow);

  s1Header.appendChild(createText("Your notes", 31, "Bold", colors.ink, { letterSpacing: -1 }));
  s1Header.appendChild(createText("TUE  ·  NOVEMBER 17", 11, "Medium", colors.muted, { letterSpacing: 0.8 }));
  screen1.appendChild(s1Header);

  // Search Bar
  const searchBar = figma.createFrame();
  searchBar.name = "SearchBar";
  searchBar.x = 20;
  searchBar.y = 150;
  searchBar.resize(350, 48);
  searchBar.layoutMode = "HORIZONTAL";
  searchBar.counterAxisAlignItems = "CENTER";
  searchBar.paddingLeft = 16;
  searchBar.itemSpacing = 10;
  searchBar.cornerRadius = 16;
  searchBar.fills = solid(colors.surface);
  searchBar.strokes = solid(colors.line);
  searchBar.strokeWeight = 1;
  searchBar.appendChild(createText("🔍", 14, "Regular", colors.muted));
  searchBar.appendChild(createText("Search your notes", 14, "Regular", colors.muted));
  screen1.appendChild(searchBar);

  // Filter Chips Row
  const filterRow = figma.createFrame();
  filterRow.x = 20;
  filterRow.y = 210;
  filterRow.resize(350, 32);
  filterRow.layoutMode = "HORIZONTAL";
  filterRow.itemSpacing = 8;
  filterRow.fills = [];
  filterRow.appendChild(createPill("All", colors.ink, colors.surface, 14, 6));
  filterRow.appendChild(createPill("Recent", colors.surface, colors.muted, 14, 6));
  filterRow.appendChild(createPill("Pinned", colors.surface, colors.muted, 14, 6));
  screen1.appendChild(filterRow);

  // Cards List Container
  const cardsContainer = figma.createFrame();
  cardsContainer.name = "NotesList";
  cardsContainer.x = 20;
  cardsContainer.y = 254;
  cardsContainer.resize(350, 480);
  cardsContainer.layoutMode = "VERTICAL";
  cardsContainer.itemSpacing = 12;
  cardsContainer.fills = [];

  cardsContainer.appendChild(createNoteCard(
    "Weekly Product Roadmap",
    "Review Q4 milestones with engineering leads and finalize release checklist for mobile...",
    ["Work", "Planning"],
    "Nov 17 · 10:30 AM",
    true
  ));

  cardsContainer.appendChild(createNoteCard(
    "Morning Reflection & Ideas",
    "Exploring calm interface design with muted olive tones, subtle borders, and generous whitespace...",
    ["Ideas", "Design"],
    "Nov 16 · 8:15 AM",
    false
  ));

  cardsContainer.appendChild(createNoteCard(
    "Book recommendations",
    "1. The Design of Everyday Things — Don Norman\n2. Shape Up: Stop Running in Circles",
    ["Personal"],
    "Nov 14 · 6:40 PM",
    false
  ));
  screen1.appendChild(cardsContainer);

  // FAB
  const fab = figma.createFrame();
  fab.name = "FAB / New Note";
  fab.x = 230;
  fab.y = 708;
  fab.resize(140, 48);
  fab.cornerRadius = 18;
  fab.layoutMode = "HORIZONTAL";
  fab.primaryAxisAlignItems = "CENTER";
  fab.counterAxisAlignItems = "CENTER";
  fab.itemSpacing = 8;
  fab.fills = solid(colors.ink);
  fab.appendChild(createText("+", 18, "Bold", colors.surface));
  fab.appendChild(createText("New note", 14, "Semi Bold", colors.surface));
  screen1.appendChild(fab);

  // Bottom Nav
  const s1Nav = createBottomNav("Notes");
  s1Nav.y = 776;
  screen1.appendChild(s1Nav);

  // ==========================================
  // SCREEN 2: NOTE EDITOR SHEET
  // ==========================================
  const screen2 = figma.createFrame();
  screen2.name = "2. Note Editor Bottom Sheet";
  screen2.resize(390, 844);
  screen2.x = 440;
  screen2.y = 0;
  screen2.fills = solid({ r: 0, g: 0, b: 0 }, 0.4);
  screen2.clipsContent = true;

  // Sheet Frame
  const sheet = figma.createFrame();
  sheet.name = "EditorSheet";
  sheet.x = 0;
  sheet.y = 120;
  sheet.resize(390, 724);
  sheet.cornerRadius = 26;
  sheet.fills = solid(colors.background);
  sheet.layoutMode = "VERTICAL";
  sheet.paddingLeft = 20;
  sheet.paddingRight = 20;
  sheet.paddingTop = 14;
  sheet.itemSpacing = 16;

  // Drag handle
  const handle = figma.createRectangle();
  handle.resize(38, 4);
  handle.cornerRadius = 2;
  handle.fills = solid(colors.line);
  handle.layoutAlign = "CENTER";
  sheet.appendChild(handle);

  // Top Action Row
  const sheetHeader = figma.createFrame();
  sheetHeader.layoutMode = "HORIZONTAL";
  sheetHeader.resize(350, 32);
  sheetHeader.primaryAxisAlignItems = "SPACE_BETWEEN";
  sheetHeader.counterAxisAlignItems = "CENTER";
  sheetHeader.fills = [];
  sheetHeader.appendChild(createText("New note", 23, "Bold", colors.ink));
  sheetHeader.appendChild(createText("📌", 18, "Regular", colors.muted));
  sheet.appendChild(sheetHeader);

  // Title Input
  const titleField = figma.createFrame();
  titleField.resize(350, 50);
  titleField.cornerRadius = 16;
  titleField.paddingLeft = 16;
  titleField.counterAxisAlignItems = "CENTER";
  titleField.fills = solid(colors.surface);
  titleField.strokes = solid(colors.line);
  titleField.appendChild(createText("Sprint Planning Notes", 16, "Bold", colors.ink));
  sheet.appendChild(titleField);

  // Content Input
  const contentField = figma.createFrame();
  contentField.resize(350, 210);
  contentField.cornerRadius = 16;
  contentField.paddingLeft = 16;
  contentField.paddingTop = 16;
  contentField.paddingRight = 16;
  contentField.fills = solid(colors.surface);
  contentField.strokes = solid(colors.line);
  contentField.appendChild(createText(
    "Review architecture proposal for the offline cache sync.\n\nKey priorities discussed:\n• Implement atomic queue for local changes\n• Add re-entrant lock on sync service\n• Design verification tests in memory DB",
    14, "Regular", colors.ink, { lineHeight: 20 }
  ));
  sheet.appendChild(contentField);

  // Tags Section
  const tagsSection = figma.createFrame();
  tagsSection.layoutMode = "VERTICAL";
  tagsSection.itemSpacing = 8;
  tagsSection.resize(350, 80);
  tagsSection.fills = [];
  tagsSection.appendChild(createText("TAGS", 10, "Bold", colors.muted, { letterSpacing: 1.2 }));

  const tagsInputRow = figma.createFrame();
  tagsInputRow.layoutMode = "HORIZONTAL";
  tagsInputRow.itemSpacing = 8;
  tagsInputRow.resize(350, 42);
  tagsInputRow.fills = [];

  const tagInput = figma.createFrame();
  tagInput.resize(298, 42);
  tagInput.cornerRadius = 14;
  tagInput.paddingLeft = 14;
  tagInput.counterAxisAlignItems = "CENTER";
  tagInput.fills = solid(colors.surface);
  tagInput.strokes = solid(colors.line);
  tagInput.appendChild(createText("Add a tag...", 13, "Regular", colors.muted));
  tagsInputRow.appendChild(tagInput);

  const tagBtn = figma.createFrame();
  tagBtn.resize(44, 42);
  tagBtn.cornerRadius = 14;
  tagBtn.primaryAxisAlignItems = "CENTER";
  tagBtn.counterAxisAlignItems = "CENTER";
  tagBtn.fills = solid(colors.accentSoft);
  tagBtn.appendChild(createText("+", 18, "Bold", colors.accent));
  tagsInputRow.appendChild(tagBtn);

  tagsSection.appendChild(tagsInputRow);
  sheet.appendChild(tagsSection);

  // Active tags
  const activeTagsRow = figma.createFrame();
  activeTagsRow.layoutMode = "HORIZONTAL";
  activeTagsRow.itemSpacing = 8;
  activeTagsRow.resize(350, 30);
  activeTagsRow.fills = [];
  activeTagsRow.appendChild(createPill("Work ✕", colors.accentSoft, colors.accent, 10, 6));
  activeTagsRow.appendChild(createPill("Planning ✕", colors.accentSoft, colors.accent, 10, 6));
  activeTagsRow.appendChild(createPill("Sprint ✕", colors.accentSoft, colors.accent, 10, 6));
  sheet.appendChild(activeTagsRow);

  // Save Button
  const saveBtn = figma.createFrame();
  saveBtn.resize(350, 52);
  saveBtn.cornerRadius = 18;
  saveBtn.primaryAxisAlignItems = "CENTER";
  saveBtn.counterAxisAlignItems = "CENTER";
  saveBtn.fills = solid(colors.ink);
  saveBtn.appendChild(createText("Save note", 16, "Bold", colors.surface));
  sheet.appendChild(saveBtn);

  screen2.appendChild(sheet);

  // ==========================================
  // SCREEN 3: CALENDAR SCREEN
  // ==========================================
  const screen3 = figma.createFrame();
  screen3.name = "3. Calendar & Activity Screen";
  screen3.resize(390, 844);
  screen3.x = 880;
  screen3.y = 0;
  screen3.fills = solid(colors.background);
  screen3.clipsContent = true;

  // Header
  const s3Header = figma.createFrame();
  s3Header.name = "Header";
  s3Header.x = 20;
  s3Header.y = 54;
  s3Header.resize(350, 68);
  s3Header.layoutMode = "VERTICAL";
  s3Header.itemSpacing = 4;
  s3Header.fills = [];
  s3Header.appendChild(createText("YOUR ACTIVITY", 10, "Bold", colors.muted, { letterSpacing: 1.3 }));

  const calTitleRow = figma.createFrame();
  calTitleRow.layoutMode = "HORIZONTAL";
  calTitleRow.resize(350, 36);
  calTitleRow.primaryAxisAlignItems = "SPACE_BETWEEN";
  calTitleRow.counterAxisAlignItems = "FLEX_END";
  calTitleRow.fills = [];
  calTitleRow.appendChild(createText("Calendar", 31, "Bold", colors.ink, { letterSpacing: -1 }));
  calTitleRow.appendChild(createText("3 notes total", 12, "Medium", colors.muted));
  s3Header.appendChild(calTitleRow);
  screen3.appendChild(s3Header);

  // Month Card
  const monthCard = figma.createFrame();
  monthCard.name = "MonthCard";
  monthCard.x = 17;
  monthCard.y = 132;
  monthCard.resize(356, 280);
  monthCard.cornerRadius = 20;
  monthCard.paddingLeft = 16;
  monthCard.paddingRight = 16;
  monthCard.paddingTop = 16;
  monthCard.layoutMode = "VERTICAL";
  monthCard.itemSpacing = 14;
  monthCard.fills = solid(colors.surface);
  monthCard.strokes = solid(colors.line);

  // Month navigation row
  const monthNav = figma.createFrame();
  monthNav.layoutMode = "HORIZONTAL";
  monthNav.resize(324, 32);
  monthNav.primaryAxisAlignItems = "SPACE_BETWEEN";
  monthNav.counterAxisAlignItems = "CENTER";
  monthNav.fills = [];
  monthNav.appendChild(createText("November 2026", 16, "Bold", colors.ink));
  monthNav.appendChild(createText("◀   ▶", 13, "Bold", colors.ink));
  monthCard.appendChild(monthNav);

  // Weekdays
  const weekdayRow = figma.createFrame();
  weekdayRow.layoutMode = "HORIZONTAL";
  weekdayRow.resize(324, 20);
  weekdayRow.primaryAxisAlignItems = "SPACE_AROUND";
  weekdayRow.fills = [];
  for (const d of ["M", "T", "W", "T", "F", "S", "S"]) {
    weekdayRow.appendChild(createText(d, 11, "Bold", colors.muted));
  }
  monthCard.appendChild(weekdayRow);

  // Grid illustration text
  const gridFrame = figma.createFrame();
  gridFrame.resize(324, 130);
  gridFrame.layoutMode = "VERTICAL";
  gridFrame.itemSpacing = 10;
  gridFrame.fills = [];

  const row1 = figma.createFrame(); row1.layoutMode = "HORIZONTAL"; row1.resize(324, 20); row1.primaryAxisAlignItems = "SPACE_AROUND"; row1.fills = [];
  for (const n of ["26", "27", "28", "29", "30", "1", "2"]) row1.appendChild(createText(n, 12, "Medium", n > "5" ? colors.muted : colors.ink));
  gridFrame.appendChild(row1);

  const row2 = figma.createFrame(); row2.layoutMode = "HORIZONTAL"; row2.resize(324, 20); row2.primaryAxisAlignItems = "SPACE_AROUND"; row2.fills = [];
  for (const n of ["3", "4", "5", "6", "7", "8", "9"]) row2.appendChild(createText(n, 12, "Medium", colors.ink));
  gridFrame.appendChild(row2);

  const row3 = figma.createFrame(); row3.layoutMode = "HORIZONTAL"; row3.resize(324, 20); row3.primaryAxisAlignItems = "SPACE_AROUND"; row3.fills = [];
  for (const n of ["10", "11", "12", "13", "14•", "15", "16•"]) row3.appendChild(createText(n, 12, "Medium", colors.ink));
  gridFrame.appendChild(row3);

  const row4 = figma.createFrame(); row4.layoutMode = "HORIZONTAL"; row4.resize(324, 24); row4.primaryAxisAlignItems = "SPACE_AROUND"; row4.fills = [];
  row4.appendChild(createPill("17", colors.ink, colors.surface, 8, 4));
  for (const n of ["18", "19", "20", "21", "22", "23"]) row4.appendChild(createText(n, 12, "Medium", colors.ink));
  gridFrame.appendChild(row4);

  monthCard.appendChild(gridFrame);

  // Footnote
  monthCard.appendChild(createText("● Numbers show notes added on each date", 10, "Regular", colors.muted));
  screen3.appendChild(monthCard);

  // Weekly view heading
  const weekHead = figma.createFrame();
  weekHead.x = 20;
  weekHead.y = 432;
  weekHead.resize(350, 20);
  weekHead.layoutMode = "HORIZONTAL";
  weekHead.primaryAxisAlignItems = "SPACE_BETWEEN";
  weekHead.fills = [];
  weekHead.appendChild(createText("Weekly view", 17, "Bold", colors.ink));
  weekHead.appendChild(createText("Nov 2026", 11, "Medium", colors.muted));
  screen3.appendChild(weekHead);

  // Week strip
  const weekStrip = figma.createFrame();
  weekStrip.x = 20;
  weekStrip.y = 460;
  weekStrip.resize(350, 74);
  weekStrip.layoutMode = "HORIZONTAL";
  weekStrip.itemSpacing = 8;
  weekStrip.fills = [];

  function createDayPill(dayName, dayNum, isSelected) {
    const p = figma.createFrame();
    p.resize(54, 72);
    p.cornerRadius = 17;
    p.layoutMode = "VERTICAL";
    p.primaryAxisAlignItems = "CENTER";
    p.counterAxisAlignItems = "CENTER";
    p.itemSpacing = 4;
    p.fills = isSelected ? solid(colors.accentSoft) : solid(colors.surface);
    p.strokes = isSelected ? solid(colors.accent) : solid(colors.line);
    p.strokeWeight = 1;
    p.appendChild(createText(dayName, 10, "Bold", isSelected ? colors.accent : colors.muted));
    p.appendChild(createText(dayNum, 16, "Bold", colors.ink));
    return p;
  }

  weekStrip.appendChild(createDayPill("SUN", "15", false));
  weekStrip.appendChild(createDayPill("MON", "16", false));
  weekStrip.appendChild(createDayPill("TUE", "17", true));
  weekStrip.appendChild(createDayPill("WED", "18", false));
  weekStrip.appendChild(createDayPill("THU", "19", false));
  screen3.appendChild(weekStrip);

  // Day notes
  const dayCard = createNoteCard(
    "Weekly Product Roadmap",
    "Review Q4 milestones with engineering leads and...",
    ["Work"],
    "Nov 17 · 10:30 AM",
    true
  );
  dayCard.x = 20;
  dayCard.y = 560;
  screen3.appendChild(dayCard);

  // Bottom Nav
  const s3Nav = createBottomNav("Calendar");
  s3Nav.y = 776;
  screen3.appendChild(s3Nav);

  // ==========================================
  // SCREEN 4: PROFILE SCREEN
  // ==========================================
  const screen4 = figma.createFrame();
  screen4.name = "4. Profile Screen";
  screen4.resize(390, 844);
  screen4.x = 1320;
  screen4.y = 0;
  screen4.fills = solid(colors.background);
  screen4.clipsContent = true;

  // Header
  const s4Header = figma.createFrame();
  s4Header.x = 20;
  s4Header.y = 54;
  s4Header.resize(350, 65);
  s4Header.layoutMode = "VERTICAL";
  s4Header.itemSpacing = 4;
  s4Header.fills = [];
  s4Header.appendChild(createText("YOUR SPACE", 10, "Bold", colors.muted, { letterSpacing: 1.3 }));
  s4Header.appendChild(createText("Profile", 31, "Bold", colors.ink, { letterSpacing: -1 }));
  screen4.appendChild(s4Header);

  // Profile Card
  const profileCard = figma.createFrame();
  profileCard.x = 20;
  profileCard.y = 126;
  profileCard.resize(350, 136);
  profileCard.cornerRadius = 22;
  profileCard.paddingLeft = 18;
  profileCard.paddingRight = 18;
  profileCard.paddingTop = 16;
  profileCard.paddingBottom = 16;
  profileCard.layoutMode = "VERTICAL";
  profileCard.itemSpacing = 12;
  profileCard.fills = solid(colors.surface);
  profileCard.strokes = solid(colors.line);

  // User row
  const userRow = figma.createFrame();
  userRow.layoutMode = "HORIZONTAL";
  userRow.resize(314, 52);
  userRow.counterAxisAlignItems = "CENTER";
  userRow.itemSpacing = 12;
  userRow.fills = [];

  const avatar = figma.createFrame();
  avatar.resize(50, 50);
  avatar.cornerRadius = 25;
  avatar.primaryAxisAlignItems = "CENTER";
  avatar.counterAxisAlignItems = "CENTER";
  avatar.fills = solid(colors.accentSoft);
  avatar.appendChild(createText("E", 20, "Bold", colors.accent));
  userRow.appendChild(avatar);

  const userInfo = figma.createFrame();
  userInfo.layoutMode = "VERTICAL";
  userInfo.itemSpacing = 3;
  userInfo.fills = [];
  userInfo.appendChild(createText("Emiai", 18, "Bold", colors.ink));
  userInfo.appendChild(createText("emiai@example.com", 12, "Regular", colors.muted));
  userRow.appendChild(userInfo);
  profileCard.appendChild(userRow);

  // Card Divider
  const divLine = figma.createRectangle();
  divLine.resize(314, 1);
  divLine.fills = solid(colors.line);
  profileCard.appendChild(divLine);

  // Bottom stats row
  const statsRow = figma.createFrame();
  statsRow.layoutMode = "HORIZONTAL";
  statsRow.resize(314, 22);
  statsRow.primaryAxisAlignItems = "SPACE_BETWEEN";
  statsRow.counterAxisAlignItems = "CENTER";
  statsRow.fills = [];
  statsRow.appendChild(createText("📝 3 notes saved on this device", 11, "Medium", colors.muted));
  statsRow.appendChild(createPill("DEMO ACCOUNT", colors.background, colors.muted, 8, 3));
  profileCard.appendChild(statsRow);
  screen4.appendChild(profileCard);

  // Settings Section: Preferences
  const prefLabel = createText("PREFERENCES", 10, "Bold", colors.muted, { letterSpacing: 1.2 });
  prefLabel.x = 20;
  prefLabel.y = 280;
  screen4.appendChild(prefLabel);

  function createSettingsGroup(items) {
    const g = figma.createFrame();
    g.resize(350, items.length * 52);
    g.cornerRadius = 19;
    g.fills = solid(colors.surface);
    g.strokes = solid(colors.line);
    g.layoutMode = "VERTICAL";

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const row = figma.createFrame();
      row.resize(350, 52);
      row.layoutMode = "HORIZONTAL";
      row.primaryAxisAlignItems = "SPACE_BETWEEN";
      row.counterAxisAlignItems = "CENTER";
      row.paddingLeft = 16;
      row.paddingRight = 16;
      row.fills = [];

      const left = figma.createFrame();
      left.layoutMode = "HORIZONTAL";
      left.itemSpacing = 12;
      left.counterAxisAlignItems = "CENTER";
      left.fills = [];
      left.appendChild(createText(item.icon, 16, "Regular", colors.ink));

      const texts = figma.createFrame();
      texts.layoutMode = "VERTICAL";
      texts.itemSpacing = 2;
      texts.fills = [];
      texts.appendChild(createText(item.title, 14, "Bold", colors.ink));
      texts.appendChild(createText(item.subtitle, 11, "Regular", colors.muted));
      left.appendChild(texts);

      row.appendChild(left);
      row.appendChild(createText("›", 18, "Regular", colors.muted));
      g.appendChild(row);

      if (i < items.length - 1) {
        const d = figma.createRectangle();
        d.resize(318, 1);
        d.x = 16;
        d.fills = solid(colors.line);
        g.appendChild(d);
      }
    }
    return g;
  }

  const prefGroup = createSettingsGroup([
    { icon: "👤", title: "Account details", subtitle: "Your name and email address" },
    { icon: "⚙️", title: "App preferences", subtitle: "Appearance and reading options" },
    { icon: "🔔", title: "Notifications", subtitle: "Manage reminders and summaries" },
  ]);
  prefGroup.x = 20;
  prefGroup.y = 298;
  screen4.appendChild(prefGroup);

  // Settings Section: Data & Support
  const dataLabel = createText("DATA & SUPPORT", 10, "Bold", colors.muted, { letterSpacing: 1.2 });
  dataLabel.x = 20;
  dataLabel.y = 472;
  screen4.appendChild(dataLabel);

  const dataGroup = createSettingsGroup([
    { icon: "🛡️", title: "Privacy & security", subtitle: "Understand how notes are stored" },
    { icon: "☁️", title: "Data & backup", subtitle: "Export a JSON copy of notes" },
    { icon: "❓", title: "Help & support", subtitle: "FAQs and app documentation" },
    { icon: "ℹ️", title: "About Daymark", subtitle: "Version and design system" },
  ]);
  dataGroup.x = 20;
  dataGroup.y = 490;
  screen4.appendChild(dataGroup);

  // Version
  const versionText = createText("DAYMARK  ·  VERSION 1.0.0", 9, "Bold", colors.muted, { letterSpacing: 1.1 });
  versionText.x = 120;
  versionText.y = 718;
  screen4.appendChild(versionText);

  // Bottom Nav
  const s4Nav = createBottomNav("Profile");
  s4Nav.y = 776;
  screen4.appendChild(s4Nav);

  // ==========================================
  // ZOOM & FIT VIEWPORT
  // ==========================================
  figma.viewport.scrollAndZoomIntoView([screen1, screen2, screen3, screen4]);
  figma.closePlugin("🎉 Daymark Notes App design successfully generated in Figma!");
}

main().catch((err) => {
  figma.notify("Error: " + err.message, { error: true });
  console.error(err);
});
