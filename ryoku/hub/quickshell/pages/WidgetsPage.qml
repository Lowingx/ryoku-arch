pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Ryoku.Ui
import Ryoku.Ui.Singletons
import "../schema/WidgetsPage.js" as Schema

// Desktop Widgets (DESIGN.md section 8, DESKTOP). The wallpaper clock is edited
// here and mirrored in a pinned live specimen so its face, size, opacity and
// placement read without leaning over to the desktop. This is a full-bleed page:
// the shell hides its side panel and action bar, so the page draws its own head,
// preview and Save/Revert bar. It owns widgets.json directly; nothing lands on
// the desktop until Save.
Item {
    id: pg

    property var hub
    readonly property bool fullBleed: true

    readonly property string query: (pg.hub && pg.hub.query) ? pg.hub.query : ""

    // ── the file's clock key set, mirrored by the JsonAdapter below ─────────
    readonly property var keys: [
        "clockEnabled", "clockDesign", "clock24h", "clockSeconds", "clockScale",
        "clockOpacity", "clockRadius", "clockAccent", "clockBg", "clockAnchor",
        "clockX", "clockY", "clockLocked", "dateShow", "dateDesign", "widgetFont",
        "calendarEnabled", "calendarStyle", "calendarWeeks", "calendarWeekNumbers",
        "calendarHolidayRegion", "calendarScale", "calendarOpacity", "calendarAnchor",
        "calendarX", "calendarY", "calendarLocked",
        "musicEnabled", "musicStyle", "musicLyrics", "musicViz", "musicScale", "musicOpacity",
        "musicAnchor", "musicX", "musicY", "musicLocked", "musicApp",
        "aioEnabled", "aioStyle", "aioScale", "aioOpacity", "aioAnchor", "aioX", "aioY", "aioLocked",
        "statsEnabled", "statsScale", "statsOpacity", "statsAnchor", "statsX", "statsY", "statsLocked",
        "weatherEnabled", "weatherDesign", "weatherScale", "weatherOpacity", "weatherAnchor", "weatherX", "weatherY", "weatherLocked",
        "notesEnabled", "notesScale", "notesOpacity", "notesWidth", "notesHeight", "notesAnchor", "notesX", "notesY", "notesLocked",
        "dayprogressEnabled", "dayprogressStyle", "dayprogressShowDate", "dayprogressScale", "dayprogressOpacity",
        "dayprogressAnchor", "dayprogressX", "dayprogressY", "dayprogressLocked",
        "shapeEnabled", "shapeKind", "shapeOutline", "shapeScale", "shapeOpacity",
        "shapeAnchor", "shapeX", "shapeY", "shapeLocked",
        // iRiS faces
        "irisClockEnabled", "irisClockScale", "irisClockAnchor", "irisClockX", "irisClockY", "irisClockLocked", "irisClockOpacity", "irisClockBg",
        "irisClockColor", "irisClockColor2", "irisClockGradient", "irisClockSize", "irisClockOpts", "irisClockStyle", "irisClockRadius", "irisClockPad",
        "irisClockBorder", "irisClockBorderOpacity", "irisClockBackingOpacity", "irisWeatherEnabled", "irisWeatherScale", "irisWeatherAnchor", "irisWeatherX", "irisWeatherY",
        "irisWeatherLocked", "irisWeatherOpacity", "irisWeatherBg", "irisWeatherColor", "irisWeatherColor2", "irisWeatherGradient", "irisWeatherSize", "irisWeatherOpts",
        "irisWeatherStyle", "irisWeatherRadius", "irisWeatherPad", "irisWeatherBorder", "irisWeatherBorderOpacity", "irisWeatherBackingOpacity", "irisMediaEnabled", "irisMediaScale",
        "irisMediaAnchor", "irisMediaX", "irisMediaY", "irisMediaLocked", "irisMediaOpacity", "irisMediaBg", "irisMediaColor", "irisMediaColor2",
        "irisMediaGradient", "irisMediaSize", "irisMediaOpts", "irisMediaStyle", "irisMediaRadius", "irisMediaPad", "irisMediaBorder", "irisMediaBorderOpacity",
        "irisMediaBackingOpacity", "irisControlsEnabled", "irisControlsScale", "irisControlsAnchor", "irisControlsX", "irisControlsY", "irisControlsLocked", "irisControlsOpacity",
        "irisControlsBg", "irisControlsColor", "irisControlsColor2", "irisControlsGradient", "irisControlsSize", "irisControlsOpts", "irisControlsStyle", "irisControlsRadius",
        "irisControlsPad", "irisControlsBorder", "irisControlsBorderOpacity", "irisControlsBackingOpacity", "irisMonthEnabled", "irisMonthScale", "irisMonthAnchor", "irisMonthX",
        "irisMonthY", "irisMonthLocked", "irisMonthOpacity", "irisMonthBg", "irisMonthColor", "irisMonthColor2", "irisMonthGradient", "irisMonthSize",
        "irisMonthOpts", "irisMonthStyle", "irisMonthRadius", "irisMonthPad", "irisMonthBorder", "irisMonthBorderOpacity", "irisMonthBackingOpacity", "irisAgendaEnabled",
        "irisAgendaScale", "irisAgendaAnchor", "irisAgendaX", "irisAgendaY", "irisAgendaLocked", "irisAgendaOpacity", "irisAgendaBg", "irisAgendaColor",
        "irisAgendaColor2", "irisAgendaGradient", "irisAgendaSize", "irisAgendaOpts", "irisAgendaStyle", "irisAgendaRadius", "irisAgendaPad", "irisAgendaBorder",
        "irisAgendaBorderOpacity", "irisAgendaBackingOpacity", "irisTodoEnabled", "irisTodoScale", "irisTodoAnchor", "irisTodoX", "irisTodoY", "irisTodoLocked",
        "irisTodoOpacity", "irisTodoBg", "irisTodoColor", "irisTodoColor2", "irisTodoGradient", "irisTodoSize", "irisTodoOpts", "irisTodoStyle",
        "irisTodoRadius", "irisTodoPad", "irisTodoBorder", "irisTodoBorderOpacity", "irisTodoBackingOpacity", "irisNotesEnabled", "irisNotesScale", "irisNotesAnchor",
        "irisNotesX", "irisNotesY", "irisNotesLocked", "irisNotesOpacity", "irisNotesBg", "irisNotesColor", "irisNotesColor2", "irisNotesGradient",
        "irisNotesSize", "irisNotesOpts", "irisNotesStyle", "irisNotesRadius", "irisNotesPad", "irisNotesBorder", "irisNotesBorderOpacity", "irisNotesBackingOpacity",
        "irisTimersEnabled", "irisTimersScale", "irisTimersAnchor", "irisTimersX", "irisTimersY", "irisTimersLocked", "irisTimersOpacity", "irisTimersBg",
        "irisTimersColor", "irisTimersColor2", "irisTimersGradient", "irisTimersSize", "irisTimersOpts", "irisTimersStyle", "irisTimersRadius", "irisTimersPad",
        "irisTimersBorder", "irisTimersBorderOpacity", "irisTimersBackingOpacity", "irisScreenEnabled", "irisScreenScale", "irisScreenAnchor", "irisScreenX", "irisScreenY",
        "irisScreenLocked", "irisScreenOpacity", "irisScreenBg", "irisScreenColor", "irisScreenColor2", "irisScreenGradient", "irisScreenSize", "irisScreenOpts",
        "irisScreenStyle", "irisScreenRadius", "irisScreenPad", "irisScreenBorder", "irisScreenBorderOpacity", "irisScreenBackingOpacity", "irisVitalsEnabled", "irisVitalsScale",
        "irisVitalsAnchor", "irisVitalsX", "irisVitalsY", "irisVitalsLocked", "irisVitalsOpacity", "irisVitalsBg", "irisVitalsColor", "irisVitalsColor2",
        "irisVitalsGradient", "irisVitalsSize", "irisVitalsOpts", "irisVitalsStyle", "irisVitalsRadius", "irisVitalsPad", "irisVitalsBorder", "irisVitalsBorderOpacity",
        "irisVitalsBackingOpacity", "irisBatteryEnabled", "irisBatteryScale", "irisBatteryAnchor", "irisBatteryX", "irisBatteryY", "irisBatteryLocked", "irisBatteryOpacity",
        "irisBatteryBg", "irisBatteryColor", "irisBatteryColor2", "irisBatteryGradient", "irisBatterySize", "irisBatteryOpts", "irisBatteryStyle", "irisBatteryRadius",
        "irisBatteryPad", "irisBatteryBorder", "irisBatteryBorderOpacity", "irisBatteryBackingOpacity", "irisWorldEnabled", "irisWorldScale", "irisWorldAnchor", "irisWorldX",
        "irisWorldY", "irisWorldLocked", "irisWorldOpacity", "irisWorldBg", "irisWorldColor", "irisWorldColor2", "irisWorldGradient", "irisWorldSize",
        "irisWorldOpts", "irisWorldStyle", "irisWorldRadius", "irisWorldPad", "irisWorldBorder", "irisWorldBorderOpacity", "irisWorldBackingOpacity", "irisDateEnabled",
        "irisDateScale", "irisDateAnchor", "irisDateX", "irisDateY", "irisDateLocked", "irisDateOpacity", "irisDateBg", "irisDateColor",
        "irisDateColor2", "irisDateGradient", "irisDateSize", "irisDateOpts", "irisDateStyle", "irisDateRadius", "irisDatePad", "irisDateBorder",
        "irisDateBorderOpacity", "irisDateBackingOpacity", "irisProfileEnabled", "irisProfileScale", "irisProfileAnchor", "irisProfileX", "irisProfileY", "irisProfileLocked",
        "irisProfileOpacity", "irisProfileBg", "irisProfileColor", "irisProfileColor2", "irisProfileGradient", "irisProfileSize", "irisProfileOpts", "irisProfileStyle",
        "irisProfileRadius", "irisProfilePad", "irisProfileBorder", "irisProfileBorderOpacity", "irisProfileBackingOpacity", "irisUptimeEnabled", "irisUptimeScale", "irisUptimeAnchor",
        "irisUptimeX", "irisUptimeY", "irisUptimeLocked", "irisUptimeOpacity", "irisUptimeBg", "irisUptimeColor", "irisUptimeColor2", "irisUptimeGradient",
        "irisUptimeSize", "irisUptimeOpts", "irisUptimeStyle", "irisUptimeRadius", "irisUptimePad", "irisUptimeBorder", "irisUptimeBorderOpacity", "irisUptimeBackingOpacity",
        "irisNewsEnabled", "irisNewsScale", "irisNewsAnchor", "irisNewsX", "irisNewsY", "irisNewsLocked", "irisNewsOpacity", "irisNewsBg",
        "irisNewsColor", "irisNewsColor2", "irisNewsGradient", "irisNewsSize", "irisNewsOpts", "irisNewsStyle", "irisNewsRadius", "irisNewsPad",
        "irisNewsBorder", "irisNewsBorderOpacity", "irisNewsBackingOpacity",
        // iRiS canvas widgets
        "irisCustomImageEnabled", "irisCustomImageScale", "irisCustomImageAnchor", "irisCustomImageX", "irisCustomImageY", "irisCustomImageLocked", "irisCustomImageOpacity", "irisCustomImageBg",
        "irisCustomImageColor", "irisCustomImageColor2", "irisCustomImageGradient", "irisCustomImageSize", "irisCustomImageOpts", "irisCustomImageStyle", "irisCustomImageRadius", "irisCustomImagePad",
        "irisCustomImageBorder", "irisCustomImageBorderOpacity", "irisCustomImageBackingOpacity", "irisEditorialEnabled", "irisEditorialScale", "irisEditorialAnchor", "irisEditorialX", "irisEditorialY",
        "irisEditorialLocked", "irisEditorialOpacity", "irisEditorialBg", "irisEditorialColor", "irisEditorialColor2", "irisEditorialGradient", "irisEditorialSize", "irisEditorialOpts",
        "irisEditorialStyle", "irisEditorialRadius", "irisEditorialPad", "irisEditorialBorder", "irisEditorialBorderOpacity", "irisEditorialBackingOpacity", "irisConverterEnabled", "irisConverterScale",
        "irisConverterAnchor", "irisConverterX", "irisConverterY", "irisConverterLocked", "irisConverterOpacity", "irisConverterBg", "irisConverterColor", "irisConverterColor2",
        "irisConverterGradient", "irisConverterSize", "irisConverterOpts", "irisConverterStyle", "irisConverterRadius", "irisConverterPad", "irisConverterBorder", "irisConverterBorderOpacity",
        "irisConverterBackingOpacity",

 "irisJpEnabled", "irisJpScale", "irisJpAnchor", "irisJpX",
        "irisJpY", "irisJpLocked", "irisJpOpacity", "irisJpBg", "irisJpColor", "irisJpColor2", "irisJpGradient", "irisJpSize",
        "irisJpOpts", "irisJpStyle", "irisJpRadius", "irisJpPad", "irisJpBorder", "irisJpBorderOpacity", "irisJpBackingOpacity", "irisVisualizerEnabled",
        "irisVisualizerScale", "irisVisualizerAnchor", "irisVisualizerX", "irisVisualizerY", "irisVisualizerLocked", "irisVisualizerOpacity", "irisVisualizerBg", "irisVisualizerColor",
        "irisVisualizerColor2", "irisVisualizerGradient", "irisVisualizerSize", "irisVisualizerOpts", "irisVisualizerStyle", "irisVisualizerRadius", "irisVisualizerPad", "irisVisualizerBorder",
        "irisVisualizerBorderOpacity", "irisVisualizerBackingOpacity"
    ]

    // Factory values mirror the wallpaper clock's canonical Config defaults.
    readonly property var factory: ({
        "clockEnabled": true, "clockDesign": "digital", "clock24h": true, "clockSeconds": false,
        "clockScale": 1.0, "clockOpacity": 1.0, "clockRadius": 26, "clockAccent": "palette",
        "clockBg": "none", "clockAnchor": "top-left", "clockX": 72, "clockY": 64, "clockLocked": false,
        "dateShow": true, "dateDesign": "inline", "widgetFont": "",
        "calendarEnabled": true, "calendarStyle": "glass", "calendarWeeks": 6,
        "calendarWeekNumbers": true, "calendarHolidayRegion": "", "calendarScale": 1.0,
        "calendarOpacity": 1.0, "calendarAnchor": "bottom-right", "calendarX": 80,
        "calendarY": 80, "calendarLocked": false,
        "musicEnabled": false, "musicStyle": "cover", "musicLyrics": true, "musicViz": "bars",
        "musicScale": 1.0, "musicOpacity": 1.0, "musicAnchor": "bottom-left",
        "musicX": 80, "musicY": 80, "musicLocked": false, "musicApp": "",
        "aioEnabled": false, "aioStyle": "wide", "aioScale": 1.0, "aioOpacity": 1.0,
        "aioAnchor": "top-right", "aioX": 80, "aioY": 80, "aioLocked": false,
        "statsEnabled": false, "statsScale": 1.0, "statsOpacity": 1.0,
        "statsAnchor": "bottom-right", "statsX": 80, "statsY": 80, "statsLocked": false,
        "weatherEnabled": false, "weatherDesign": "compact", "weatherScale": 1.0, "weatherOpacity": 1.0,
        "weatherAnchor": "top-right", "weatherX": 80, "weatherY": 80, "weatherLocked": false,
        "notesEnabled": false, "notesScale": 1.0, "notesOpacity": 1.0, "notesWidth": 260, "notesHeight": 180,
        "notesAnchor": "right", "notesX": 80, "notesY": 80, "notesLocked": false,
        "dayprogressEnabled": false, "dayprogressStyle": "ring", "dayprogressShowDate": true,
        "dayprogressScale": 1.0, "dayprogressOpacity": 1.0, "dayprogressAnchor": "left",
        "dayprogressX": 80, "dayprogressY": 260, "dayprogressLocked": false,
        "shapeEnabled": false, "shapeKind": "dot", "shapeOutline": false,
        "shapeScale": 1.0, "shapeOpacity": 1.0, "shapeAnchor": "bottom-left",
        "shapeX": 80, "shapeY": 240, "shapeLocked": false,
        // iRiS faces (defaults mirror the desktop Config)
        "irisClockEnabled": false, "irisClockScale": 1.0, "irisClockAnchor": "free", "irisClockX": 120, "irisClockY": 120, "irisClockLocked": false,
        "irisClockOpacity": 1.0, "irisClockBg": "card", "irisClockColor": "", "irisClockColor2": "", "irisClockGradient": false, "irisClockSize": "small",
        "irisClockOpts": "", "irisClockStyle": "inir", "irisClockRadius": -1, "irisClockPad": -1, "irisClockBorder": -1, "irisClockBorderOpacity": -1,
        "irisClockBackingOpacity": -1, "irisWeatherEnabled": false, "irisWeatherScale": 1.0, "irisWeatherAnchor": "free", "irisWeatherX": 168, "irisWeatherY": 160,
        "irisWeatherLocked": false, "irisWeatherOpacity": 1.0, "irisWeatherBg": "card", "irisWeatherColor": "", "irisWeatherColor2": "", "irisWeatherGradient": false,
        "irisWeatherSize": "small", "irisWeatherOpts": "", "irisWeatherStyle": "inir", "irisWeatherRadius": -1, "irisWeatherPad": -1, "irisWeatherBorder": -1,
        "irisWeatherBorderOpacity": -1, "irisWeatherBackingOpacity": -1, "irisMediaEnabled": false, "irisMediaScale": 1.0, "irisMediaAnchor": "free", "irisMediaX": 216,
        "irisMediaY": 200, "irisMediaLocked": false, "irisMediaOpacity": 1.0, "irisMediaBg": "card", "irisMediaColor": "", "irisMediaColor2": "",
        "irisMediaGradient": false, "irisMediaSize": "medium", "irisMediaOpts": "", "irisMediaStyle": "inir", "irisMediaRadius": -1, "irisMediaPad": -1,
        "irisMediaBorder": -1, "irisMediaBorderOpacity": -1, "irisMediaBackingOpacity": -1, "irisControlsEnabled": false, "irisControlsScale": 1.0, "irisControlsAnchor": "free",
        "irisControlsX": 120, "irisControlsY": 240, "irisControlsLocked": false, "irisControlsOpacity": 1.0, "irisControlsBg": "card", "irisControlsColor": "",
        "irisControlsColor2": "", "irisControlsGradient": false, "irisControlsSize": "medium", "irisControlsOpts": "", "irisControlsStyle": "inir", "irisControlsRadius": -1,
        "irisControlsPad": -1, "irisControlsBorder": -1, "irisControlsBorderOpacity": -1, "irisControlsBackingOpacity": -1, "irisMonthEnabled": false, "irisMonthScale": 1.0,
        "irisMonthAnchor": "free", "irisMonthX": 168, "irisMonthY": 280, "irisMonthLocked": false, "irisMonthOpacity": 1.0, "irisMonthBg": "card",
        "irisMonthColor": "", "irisMonthColor2": "", "irisMonthGradient": false, "irisMonthSize": "medium", "irisMonthOpts": "", "irisMonthStyle": "inir",
        "irisMonthRadius": -1, "irisMonthPad": -1, "irisMonthBorder": -1, "irisMonthBorderOpacity": -1, "irisMonthBackingOpacity": -1, "irisAgendaEnabled": false,
        "irisAgendaScale": 1.0, "irisAgendaAnchor": "free", "irisAgendaX": 216, "irisAgendaY": 320, "irisAgendaLocked": false, "irisAgendaOpacity": 1.0,
        "irisAgendaBg": "card", "irisAgendaColor": "", "irisAgendaColor2": "", "irisAgendaGradient": false, "irisAgendaSize": "medium", "irisAgendaOpts": "",
        "irisAgendaStyle": "inir", "irisAgendaRadius": -1, "irisAgendaPad": -1, "irisAgendaBorder": -1, "irisAgendaBorderOpacity": -1, "irisAgendaBackingOpacity": -1,
        "irisTodoEnabled": false, "irisTodoScale": 1.0, "irisTodoAnchor": "free", "irisTodoX": 120, "irisTodoY": 360, "irisTodoLocked": false,
        "irisTodoOpacity": 1.0, "irisTodoBg": "card", "irisTodoColor": "", "irisTodoColor2": "", "irisTodoGradient": false, "irisTodoSize": "medium",
        "irisTodoOpts": "", "irisTodoStyle": "inir", "irisTodoRadius": -1, "irisTodoPad": -1, "irisTodoBorder": -1, "irisTodoBorderOpacity": -1,
        "irisTodoBackingOpacity": -1, "irisNotesEnabled": false, "irisNotesScale": 1.0, "irisNotesAnchor": "free", "irisNotesX": 168, "irisNotesY": 400,
        "irisNotesLocked": false, "irisNotesOpacity": 1.0, "irisNotesBg": "card", "irisNotesColor": "", "irisNotesColor2": "", "irisNotesGradient": false,
        "irisNotesSize": "medium", "irisNotesOpts": "", "irisNotesStyle": "inir", "irisNotesRadius": -1, "irisNotesPad": -1, "irisNotesBorder": -1,
        "irisNotesBorderOpacity": -1, "irisNotesBackingOpacity": -1, "irisTimersEnabled": false, "irisTimersScale": 1.0, "irisTimersAnchor": "free", "irisTimersX": 216,
        "irisTimersY": 440, "irisTimersLocked": false, "irisTimersOpacity": 1.0, "irisTimersBg": "card", "irisTimersColor": "", "irisTimersColor2": "",
        "irisTimersGradient": false, "irisTimersSize": "medium", "irisTimersOpts": "", "irisTimersStyle": "inir", "irisTimersRadius": -1, "irisTimersPad": -1,
        "irisTimersBorder": -1, "irisTimersBorderOpacity": -1, "irisTimersBackingOpacity": -1, "irisScreenEnabled": false, "irisScreenScale": 1.0, "irisScreenAnchor": "free",
        "irisScreenX": 120, "irisScreenY": 480, "irisScreenLocked": false, "irisScreenOpacity": 1.0, "irisScreenBg": "card", "irisScreenColor": "",
        "irisScreenColor2": "", "irisScreenGradient": false, "irisScreenSize": "medium", "irisScreenOpts": "", "irisScreenStyle": "inir", "irisScreenRadius": -1,
        "irisScreenPad": -1, "irisScreenBorder": -1, "irisScreenBorderOpacity": -1, "irisScreenBackingOpacity": -1, "irisVitalsEnabled": false, "irisVitalsScale": 1.0,
        "irisVitalsAnchor": "free", "irisVitalsX": 168, "irisVitalsY": 520, "irisVitalsLocked": false, "irisVitalsOpacity": 1.0, "irisVitalsBg": "card",
        "irisVitalsColor": "", "irisVitalsColor2": "", "irisVitalsGradient": false, "irisVitalsSize": "medium", "irisVitalsOpts": "", "irisVitalsStyle": "inir",
        "irisVitalsRadius": -1, "irisVitalsPad": -1, "irisVitalsBorder": -1, "irisVitalsBorderOpacity": -1, "irisVitalsBackingOpacity": -1, "irisBatteryEnabled": false,
        "irisBatteryScale": 1.0, "irisBatteryAnchor": "free", "irisBatteryX": 216, "irisBatteryY": 560, "irisBatteryLocked": false, "irisBatteryOpacity": 1.0,
        "irisBatteryBg": "card", "irisBatteryColor": "", "irisBatteryColor2": "", "irisBatteryGradient": false, "irisBatterySize": "small", "irisBatteryOpts": "",
        "irisBatteryStyle": "inir", "irisBatteryRadius": -1, "irisBatteryPad": -1, "irisBatteryBorder": -1, "irisBatteryBorderOpacity": -1, "irisBatteryBackingOpacity": -1,
        "irisWorldEnabled": false, "irisWorldScale": 1.0, "irisWorldAnchor": "free", "irisWorldX": 120, "irisWorldY": 600, "irisWorldLocked": false,
        "irisWorldOpacity": 1.0, "irisWorldBg": "card", "irisWorldColor": "", "irisWorldColor2": "", "irisWorldGradient": false, "irisWorldSize": "medium",
        "irisWorldOpts": "", "irisWorldStyle": "inir", "irisWorldRadius": -1, "irisWorldPad": -1, "irisWorldBorder": -1, "irisWorldBorderOpacity": -1,
        "irisWorldBackingOpacity": -1, "irisDateEnabled": false, "irisDateScale": 1.0, "irisDateAnchor": "free", "irisDateX": 168, "irisDateY": 640,
        "irisDateLocked": false, "irisDateOpacity": 1.0, "irisDateBg": "card", "irisDateColor": "", "irisDateColor2": "", "irisDateGradient": false,
        "irisDateSize": "small", "irisDateOpts": "", "irisDateStyle": "inir", "irisDateRadius": -1, "irisDatePad": -1, "irisDateBorder": -1,
        "irisDateBorderOpacity": -1, "irisDateBackingOpacity": -1, "irisProfileEnabled": false, "irisProfileScale": 1.0, "irisProfileAnchor": "free", "irisProfileX": 216,
        "irisProfileY": 680, "irisProfileLocked": false, "irisProfileOpacity": 1.0, "irisProfileBg": "card", "irisProfileColor": "", "irisProfileColor2": "",
        "irisProfileGradient": false, "irisProfileSize": "medium", "irisProfileOpts": "", "irisProfileStyle": "inir", "irisProfileRadius": -1, "irisProfilePad": -1,
        "irisProfileBorder": -1, "irisProfileBorderOpacity": -1, "irisProfileBackingOpacity": -1, "irisUptimeEnabled": false, "irisUptimeScale": 1.0, "irisUptimeAnchor": "free",
        "irisUptimeX": 120, "irisUptimeY": 720, "irisUptimeLocked": false, "irisUptimeOpacity": 1.0, "irisUptimeBg": "card", "irisUptimeColor": "",
        "irisUptimeColor2": "", "irisUptimeGradient": false, "irisUptimeSize": "small", "irisUptimeOpts": "", "irisUptimeStyle": "inir", "irisUptimeRadius": -1,
        "irisUptimePad": -1, "irisUptimeBorder": -1, "irisUptimeBorderOpacity": -1, "irisUptimeBackingOpacity": -1, "irisNewsEnabled": false, "irisNewsScale": 1.0,
        "irisNewsAnchor": "free", "irisNewsX": 168, "irisNewsY": 760, "irisNewsLocked": false, "irisNewsOpacity": 1.0, "irisNewsBg": "card",
        "irisNewsColor": "", "irisNewsColor2": "", "irisNewsGradient": false, "irisNewsSize": "medium", "irisNewsOpts": "", "irisNewsStyle": "inir",
        "irisNewsRadius": -1, "irisNewsPad": -1, "irisNewsBorder": -1, "irisNewsBorderOpacity": -1, "irisNewsBackingOpacity": -1,
        // iRiS canvas widgets
        "irisCustomImageEnabled": false, "irisCustomImageScale": 1.0, "irisCustomImageAnchor": "free", "irisCustomImageX": 216, "irisCustomImageY": 800, "irisCustomImageLocked": false,
        "irisCustomImageOpacity": 1.0, "irisCustomImageBg": "card", "irisCustomImageColor": "", "irisCustomImageColor2": "", "irisCustomImageGradient": false, "irisCustomImageSize": "small",
        "irisCustomImageOpts": "", "irisCustomImageStyle": "inir", "irisCustomImageRadius": -1, "irisCustomImagePad": -1, "irisCustomImageBorder": -1, "irisCustomImageBorderOpacity": -1,
        "irisCustomImageBackingOpacity": -1, "irisEditorialEnabled": false, "irisEditorialScale": 1.0, "irisEditorialAnchor": "free", "irisEditorialX": 120, "irisEditorialY": 840,
        "irisEditorialLocked": false, "irisEditorialOpacity": 1.0, "irisEditorialBg": "card", "irisEditorialColor": "", "irisEditorialColor2": "", "irisEditorialGradient": false,
        "irisEditorialSize": "small", "irisEditorialOpts": "", "irisEditorialStyle": "inir", "irisEditorialRadius": -1, "irisEditorialPad": -1, "irisEditorialBorder": -1,
        "irisEditorialBorderOpacity": -1, "irisEditorialBackingOpacity": -1, "irisConverterEnabled": false, "irisConverterScale": 1.0, "irisConverterAnchor": "free", "irisConverterX": 168,
        "irisConverterY": 880, "irisConverterLocked": false, "irisConverterOpacity": 1.0, "irisConverterBg": "card", "irisConverterColor": "", "irisConverterColor2": "",
        "irisConverterGradient": false, "irisConverterSize": "small", "irisConverterOpts": "", "irisConverterStyle": "inir", "irisConverterRadius": -1, "irisConverterPad": -1,
        "irisConverterBorder": -1, "irisConverterBorderOpacity": -1, "irisConverterBackingOpacity": -1,.0,
.0,

 "irisJpEnabled": false, "irisJpScale": 1.0,
        "irisJpAnchor": "free", "irisJpX": 120, "irisJpY": 960, "irisJpLocked": false, "irisJpOpacity": 1.0, "irisJpBg": "card",
        "irisJpColor": "", "irisJpColor2": "", "irisJpGradient": false, "irisJpSize": "small", "irisJpOpts": "", "irisJpStyle": "inir",
        "irisJpRadius": -1, "irisJpPad": -1, "irisJpBorder": -1, "irisJpBorderOpacity": -1, "irisJpBackingOpacity": -1, "irisVisualizerEnabled": false,
        "irisVisualizerScale": 1.0, "irisVisualizerAnchor": "free", "irisVisualizerX": 168, "irisVisualizerY": 1000, "irisVisualizerLocked": false, "irisVisualizerOpacity": 1.0,
        "irisVisualizerBg": "card", "irisVisualizerColor": "", "irisVisualizerColor2": "", "irisVisualizerGradient": false, "irisVisualizerSize": "small", "irisVisualizerOpts": "",
        "irisVisualizerStyle": "inir", "irisVisualizerRadius": -1, "irisVisualizerPad": -1, "irisVisualizerBorder": -1, "irisVisualizerBorderOpacity": -1, "irisVisualizerBackingOpacity": -1
    })

    // Scale and opacity persist as ratios; the sheet edits integer percents.
    readonly property var pctKeys: ({
        "clockOpacity": true, "calendarOpacity": true, "musicOpacity": true,
        "aioOpacity": true, "statsOpacity": true, "weatherOpacity": true, "notesOpacity": true,
        "dayprogressOpacity": true, "shapeOpacity": true, "irisClockOpacity": true, "irisWeatherOpacity": true, "irisMediaOpacity": true, "irisControlsOpacity": true, "irisMonthOpacity": true, "irisAgendaOpacity": true, "irisTodoOpacity": true, "irisNotesOpacity": true, "irisTimersOpacity": true, "irisScreenOpacity": true, "irisVitalsOpacity": true, "irisBatteryOpacity": true, "irisWorldOpacity": true, "irisDateOpacity": true, "irisProfileOpacity": true, "irisUptimeOpacity": true, "irisNewsOpacity": true, "irisCustomImageOpacity": true, "irisEditorialOpacity": true, "irisConverterOpacity": true, "irisJpOpacity": true, "irisVisualizerOpacity": true
    })
    readonly property var scaleKeys: ({
        "clockScale": true, "calendarScale": true, "musicScale": true,
        "aioScale": true, "statsScale": true, "weatherScale": true, "notesScale": true,
        "dayprogressScale": true, "shapeScale": true, "irisClockScale": true, "irisWeatherScale": true, "irisMediaScale": true, "irisControlsScale": true, "irisMonthScale": true, "irisAgendaScale": true, "irisTodoScale": true, "irisNotesScale": true, "irisTimersScale": true, "irisScreenScale": true, "irisVitalsScale": true, "irisBatteryScale": true, "irisWorldScale": true, "irisDateScale": true, "irisProfileScale": true, "irisUptimeScale": true, "irisNewsScale": true, "irisCustomImageScale": true, "irisEditorialScale": true, "irisConverterScale": true, "irisJpScale": true, "irisVisualizerScale": true
    })

    property var draft: ({})
    property var committed: ({})
    property bool loaded: false

    // Widget-font picker source. The bundled NibrasShell display faces (mirrors
    // the shell's Fonts singleton -- these live in the shell process, not
    // fontconfig, so they are named here as literals) come first, then every
    // installed family, read live like the Global page's system-font picker.
    // Injected into the widgetFont row's options so all fonts are reachable.
    readonly property var bundledFonts: [
        "Reckoner", "Reckoner Bold", "JF Flat", "Abberancy", "Daydream",
        "sabana", "Unrealised", "VIP Rawy Regular", "Xenophobia",
        "VEXA light R", "Overhead BRK"
    ]
    property var fontList: []
    readonly property var fontOptions: pg.bundledFonts.concat(pg.fontList)

    Process {
        id: fonts
        running: true
        command: ["bash", "-c", "fc-list : family | cut -d, -f1 | sort -u"]
        stdout: StdioCollector {
            id: fontsOut
            onStreamFinished: {
                var t = ("" + fontsOut.text).trim();
                pg.fontList = t.length > 0 ? t.split("\n").filter(function (x) { return x.length > 0; }) : [];
            }
        }
    }

    function readAdapter() {
        var m = {};
        for (var i = 0; i < pg.keys.length; i++) {
            var k = pg.keys[i];
            m[k] = cfgA[k];
        }
        return m;
    }
    function edit(k, v) {
        var d = Object.assign({}, pg.draft);
        d[k] = v;
        pg.draft = d;
    }
    function save() {
        for (var i = 0; i < pg.keys.length; i++) {
            var k = pg.keys[i];
            cfgA[k] = pg.draft[k];
        }
        cfg.writeAdapter();
        pg.committed = Object.assign({}, pg.draft);
    }
    function revert() { pg.draft = Object.assign({}, pg.committed); }
    function reset() { pg.draft = Object.assign({}, pg.factory); }

    // first load adopts disk as both baseline and draft. a later external write
    // (someone edits the file, or drags a widget on the desktop) rebases only
    // the keys the user has not locally edited, so unsaved edits survive.
    function onCfgLoaded() {
        if (!pg.loaded) {
            pg.committed = pg.readAdapter();
            pg.draft = pg.readAdapter();
            pg.loaded = true;
            return;
        }
        var disk = pg.readAdapter();
        var nc = {};
        var nd = Object.assign({}, pg.draft);
        for (var i = 0; i < pg.keys.length; i++) {
            var k = pg.keys[i];
            if (String(pg.draft[k]) === String(pg.committed[k])) {
                nd[k] = disk[k];
                nc[k] = disk[k];
            } else {
                nc[k] = pg.committed[k];
            }
        }
        pg.committed = nc;
        pg.draft = nd;
    }

    readonly property int dirtyCount: {
        if (!pg.loaded)
            return 0;
        var n = 0;
        for (var i = 0; i < pg.keys.length; i++) {
            var k = pg.keys[i];
            if (String(pg.draft[k]) !== String(pg.committed[k]))
                n++;
        }
        return n;
    }
    readonly property bool dirty: pg.dirtyCount > 0

    // Each widget keeps its own tab and its natural groups (WIDGET, FORMAT, DATE,
    // SIZE & SHAPE, PLACEMENT); the open subpage sets the sheet's tab so only that
    // widget's cards show. Ratio rows (scale, opacity) become integer-percent
    // sliders at the sheet boundary.
    readonly property var schemaRows: {
        var out = [];
        for (var i = 0; i < Schema.rows.length; i++) {
            var r = Schema.rows[i];
            var c = {};
            for (var p in r)
                c[p] = r[p];
            if (pg.pctKeys[r.key]) {
                c.ctl = "slid"; c.lo = 20; c.hi = 100; c.unit = "%"; c.pct = false;
            } else if (pg.scaleKeys[r.key]) {
                c.ctl = "slid"; c.lo = 50; c.hi = 250; c.unit = "%"; c.pct = false;
            }
            if (r.key === "widgetFont")
                c.opts = pg.fontOptions;
            out.push(c);
        }
        return out;
    }

    // the flat maps handed to the sheet: ratios shown as whole percents.
    readonly property var sheetDraft: {
        var m = {};
        for (var i = 0; i < pg.keys.length; i++) {
            var k = pg.keys[i];
            var v = pg.draft[k];
            if (pg.pctKeys[k] || pg.scaleKeys[k])
                m[k] = Math.round((Number(v) || 0) * 100);
            else
                m[k] = v;
        }
        return m;
    }
    readonly property var sheetDefaults: {
        var m = {};
        for (var i = 0; i < pg.keys.length; i++) {
            var k = pg.keys[i];
            var v = pg.committed[k];
            if (v === undefined) { m[k] = undefined; continue; }
            if (pg.pctKeys[k] || pg.scaleKeys[k])
                m[k] = Math.round((Number(v) || 0) * 100);
            else
                m[k] = v;
        }
        return m;
    }

    function onSheetEdited(k, v) {
        if (pg.pctKeys[k] || pg.scaleKeys[k])
            pg.edit(k, v / 100);
        else
            pg.edit(k, v);
    }
    function onSheetPick(r) { pg.pickRow = r; }

    // anchor -> 0/0.5/1 on each axis, for the card's corner mini-map.
    function afx(a) { return a.indexOf("left") >= 0 ? 0 : (a.indexOf("right") >= 0 ? 1 : 0.5); }
    function afy(a) { return a.indexOf("top") >= 0 ? 0 : (a.indexOf("bottom") >= 0 ? 1 : 0.5); }

    // one live specimen: a framed card that renders the real desktop widget,
    // scaled to fit and centred, dimmed with a struck header when the widget is
    // off, and a 3x3 corner map marking where it sits on the wallpaper.
    component SpecimenCard: Rectangle {
        id: card
        property string title: ""
        property bool on: true
        property string anchor: "center"
        property real natW: 200
        property real natH: 140
        property real userScale: 1
        property real userOpacity: 1
        property Component preview: null

        color: Tokens.paperLift
        radius: Tokens.radius
        border.width: Tokens.border
        border.color: card.on ? Tokens.line : Tokens.lineSoft
        clip: true
        opacity: card.on ? 1 : 0.5
        Behavior on opacity { NumberAnimation { duration: Tokens.snap } }

        Item {
            id: hdr
            anchors { left: parent.left; right: parent.right; top: parent.top }
            anchors.leftMargin: Tokens.s3; anchors.rightMargin: Tokens.s3; anchors.topMargin: Tokens.s2
            height: 14
            Text {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: card.title
                color: card.on ? Tokens.inkMuted : Tokens.inkFaint
                font.family: Tokens.ui; font.pixelSize: 9; font.weight: Font.Medium
                font.letterSpacing: Tokens.trackLabel; font.strikeout: !card.on
            }
            Grid {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                columns: 3; rowSpacing: 2; columnSpacing: 2
                Repeater {
                    model: 9
                    Rectangle {
                        required property int index
                        width: 3; height: 3
                        readonly property bool lit: card.on
                            && (index % 3) === Math.round(pg.afx(card.anchor) * 2)
                            && Math.floor(index / 3) === Math.round(pg.afy(card.anchor) * 2)
                        color: lit ? Tokens.ink : Tokens.lineStrong
                    }
                }
            }
        }

        Item {
            id: bodyHolder
            anchors { left: parent.left; right: parent.right; top: hdr.bottom; bottom: parent.bottom }
            anchors.margins: Tokens.s2
            clip: true
            Item {
                width: card.natW; height: card.natH
                anchors.centerIn: parent
                opacity: card.userOpacity
                scale: Math.min(bodyHolder.width / card.natW, bodyHolder.height / card.natH, 1.15) * card.userScale
                Loader { anchors.fill: parent; sourceComponent: card.preview }
            }
        }
    }

    // ── persistence: the page owns widgets.json ──────────────────────────────
    FileView {
        id: cfg
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ryoku/widgets.json"
        blockLoading: true
        watchChanges: true
        printErrors: false
        atomicWrites: true
        onFileChanged: reload()
        onLoaded: pg.onCfgLoaded()
        onLoadFailed: {
            if (!pg.loaded) {
                pg.committed = pg.readAdapter();
                pg.draft = pg.readAdapter();
                pg.loaded = true;
            }
        }

        JsonAdapter {
            id: cfgA
            property bool clockEnabled: true
            property string clockDesign: "digital"
            property bool clock24h: true
            property bool clockSeconds: false
            property real clockScale: 1.0
            property real clockOpacity: 1.0
            property int clockRadius: 26
            property string clockAccent: "palette"
            property string clockBg: "none"
            property string clockAnchor: "top-left"
            property int clockX: 72
            property int clockY: 64
            property bool clockLocked: false
            property bool dateShow: true
            property string dateDesign: "inline"
            property string widgetFont: ""
            property bool calendarEnabled: true
            property string calendarStyle: "glass"
            property int calendarWeeks: 6
            property bool calendarWeekNumbers: true
            property string calendarHolidayRegion: ""
            property real calendarScale: 1.0
            property real calendarOpacity: 1.0
            property string calendarAnchor: "bottom-right"
            property int calendarX: 80
            property int calendarY: 80
            property bool calendarLocked: false
            property bool musicEnabled: false
            property string musicStyle: "cover"
            property bool musicLyrics: true
            property string musicViz: "bars"
            property real musicScale: 1.0
            property real musicOpacity: 1.0
            property string musicAnchor: "bottom-left"
            property int musicX: 80
            property int musicY: 80
            property bool musicLocked: false
            property string musicApp: ""
            property bool aioEnabled: false
            property string aioStyle: "wide"
            property real aioScale: 1.0
            property real aioOpacity: 1.0
            property string aioAnchor: "top-right"
            property int aioX: 80
            property int aioY: 80
            property bool aioLocked: false
            property bool statsEnabled: false
            property real statsScale: 1.0
            property real statsOpacity: 1.0
            property string statsAnchor: "bottom-right"
            property int statsX: 80
            property int statsY: 80
            property bool statsLocked: false
            property bool weatherEnabled: false
            property string weatherDesign: "compact"
            property real weatherScale: 1.0
            property real weatherOpacity: 1.0
            property string weatherAnchor: "top-right"
            property int weatherX: 80
            property int weatherY: 80
            property bool weatherLocked: false
            property bool notesEnabled: false
            property real notesScale: 1.0
            property real notesOpacity: 1.0
            property int notesWidth: 260
            property int notesHeight: 180
            property string notesAnchor: "right"
            property int notesX: 80
            property int notesY: 80
            property bool notesLocked: false
            property bool dayprogressEnabled: false
            property string dayprogressStyle: "ring"
            property bool dayprogressShowDate: true
            property real dayprogressScale: 1.0
            property real dayprogressOpacity: 1.0
            property string dayprogressAnchor: "left"
            property int dayprogressX: 80
            property int dayprogressY: 260
            property bool dayprogressLocked: false
            property bool shapeEnabled: false
            property string shapeKind: "dot"
            property bool shapeOutline: false
            property real shapeScale: 1.0
            property real shapeOpacity: 1.0
            property string shapeAnchor: "bottom-left"
            property int shapeX: 80
            property int shapeY: 240
            property bool shapeLocked: false
            // iRiS faces — declared so a Hub Save preserves every per-widget key
            property bool irisClockEnabled: false
            property real irisClockScale: 1.0
            property string irisClockAnchor: "free"
            property int irisClockX: 120
            property int irisClockY: 120
            property bool irisClockLocked: false
            property real irisClockOpacity: 1.0
            property string irisClockBg: "card"
            property string irisClockColor: ""
            property string irisClockColor2: ""
            property bool irisClockGradient: false
            property string irisClockSize: "small"
            property string irisClockOpts: ""
            property string irisClockStyle: "inir"
            property int irisClockRadius: -1
            property real irisClockPad: -1
            property real irisClockBorder: -1
            property real irisClockBorderOpacity: -1
            property real irisClockBackingOpacity: -1
            property bool irisWeatherEnabled: false
            property real irisWeatherScale: 1.0
            property string irisWeatherAnchor: "free"
            property int irisWeatherX: 168
            property int irisWeatherY: 160
            property bool irisWeatherLocked: false
            property real irisWeatherOpacity: 1.0
            property string irisWeatherBg: "card"
            property string irisWeatherColor: ""
            property string irisWeatherColor2: ""
            property bool irisWeatherGradient: false
            property string irisWeatherSize: "small"
            property string irisWeatherOpts: ""
            property string irisWeatherStyle: "inir"
            property int irisWeatherRadius: -1
            property real irisWeatherPad: -1
            property real irisWeatherBorder: -1
            property real irisWeatherBorderOpacity: -1
            property real irisWeatherBackingOpacity: -1
            property bool irisMediaEnabled: false
            property real irisMediaScale: 1.0
            property string irisMediaAnchor: "free"
            property int irisMediaX: 216
            property int irisMediaY: 200
            property bool irisMediaLocked: false
            property real irisMediaOpacity: 1.0
            property string irisMediaBg: "card"
            property string irisMediaColor: ""
            property string irisMediaColor2: ""
            property bool irisMediaGradient: false
            property string irisMediaSize: "medium"
            property string irisMediaOpts: ""
            property string irisMediaStyle: "inir"
            property int irisMediaRadius: -1
            property real irisMediaPad: -1
            property real irisMediaBorder: -1
            property real irisMediaBorderOpacity: -1
            property real irisMediaBackingOpacity: -1
            property bool irisControlsEnabled: false
            property real irisControlsScale: 1.0
            property string irisControlsAnchor: "free"
            property int irisControlsX: 120
            property int irisControlsY: 240
            property bool irisControlsLocked: false
            property real irisControlsOpacity: 1.0
            property string irisControlsBg: "card"
            property string irisControlsColor: ""
            property string irisControlsColor2: ""
            property bool irisControlsGradient: false
            property string irisControlsSize: "medium"
            property string irisControlsOpts: ""
            property string irisControlsStyle: "inir"
            property int irisControlsRadius: -1
            property real irisControlsPad: -1
            property real irisControlsBorder: -1
            property real irisControlsBorderOpacity: -1
            property real irisControlsBackingOpacity: -1
            property bool irisMonthEnabled: false
            property real irisMonthScale: 1.0
            property string irisMonthAnchor: "free"
            property int irisMonthX: 168
            property int irisMonthY: 280
            property bool irisMonthLocked: false
            property real irisMonthOpacity: 1.0
            property string irisMonthBg: "card"
            property string irisMonthColor: ""
            property string irisMonthColor2: ""
            property bool irisMonthGradient: false
            property string irisMonthSize: "medium"
            property string irisMonthOpts: ""
            property string irisMonthStyle: "inir"
            property int irisMonthRadius: -1
            property real irisMonthPad: -1
            property real irisMonthBorder: -1
            property real irisMonthBorderOpacity: -1
            property real irisMonthBackingOpacity: -1
            property bool irisAgendaEnabled: false
            property real irisAgendaScale: 1.0
            property string irisAgendaAnchor: "free"
            property int irisAgendaX: 216
            property int irisAgendaY: 320
            property bool irisAgendaLocked: false
            property real irisAgendaOpacity: 1.0
            property string irisAgendaBg: "card"
            property string irisAgendaColor: ""
            property string irisAgendaColor2: ""
            property bool irisAgendaGradient: false
            property string irisAgendaSize: "medium"
            property string irisAgendaOpts: ""
            property string irisAgendaStyle: "inir"
            property int irisAgendaRadius: -1
            property real irisAgendaPad: -1
            property real irisAgendaBorder: -1
            property real irisAgendaBorderOpacity: -1
            property real irisAgendaBackingOpacity: -1
            property bool irisTodoEnabled: false
            property real irisTodoScale: 1.0
            property string irisTodoAnchor: "free"
            property int irisTodoX: 120
            property int irisTodoY: 360
            property bool irisTodoLocked: false
            property real irisTodoOpacity: 1.0
            property string irisTodoBg: "card"
            property string irisTodoColor: ""
            property string irisTodoColor2: ""
            property bool irisTodoGradient: false
            property string irisTodoSize: "medium"
            property string irisTodoOpts: ""
            property string irisTodoStyle: "inir"
            property int irisTodoRadius: -1
            property real irisTodoPad: -1
            property real irisTodoBorder: -1
            property real irisTodoBorderOpacity: -1
            property real irisTodoBackingOpacity: -1
            property bool irisNotesEnabled: false
            property real irisNotesScale: 1.0
            property string irisNotesAnchor: "free"
            property int irisNotesX: 168
            property int irisNotesY: 400
            property bool irisNotesLocked: false
            property real irisNotesOpacity: 1.0
            property string irisNotesBg: "card"
            property string irisNotesColor: ""
            property string irisNotesColor2: ""
            property bool irisNotesGradient: false
            property string irisNotesSize: "medium"
            property string irisNotesOpts: ""
            property string irisNotesStyle: "inir"
            property int irisNotesRadius: -1
            property real irisNotesPad: -1
            property real irisNotesBorder: -1
            property real irisNotesBorderOpacity: -1
            property real irisNotesBackingOpacity: -1
            property bool irisTimersEnabled: false
            property real irisTimersScale: 1.0
            property string irisTimersAnchor: "free"
            property int irisTimersX: 216
            property int irisTimersY: 440
            property bool irisTimersLocked: false
            property real irisTimersOpacity: 1.0
            property string irisTimersBg: "card"
            property string irisTimersColor: ""
            property string irisTimersColor2: ""
            property bool irisTimersGradient: false
            property string irisTimersSize: "medium"
            property string irisTimersOpts: ""
            property string irisTimersStyle: "inir"
            property int irisTimersRadius: -1
            property real irisTimersPad: -1
            property real irisTimersBorder: -1
            property real irisTimersBorderOpacity: -1
            property real irisTimersBackingOpacity: -1
            property bool irisScreenEnabled: false
            property real irisScreenScale: 1.0
            property string irisScreenAnchor: "free"
            property int irisScreenX: 120
            property int irisScreenY: 480
            property bool irisScreenLocked: false
            property real irisScreenOpacity: 1.0
            property string irisScreenBg: "card"
            property string irisScreenColor: ""
            property string irisScreenColor2: ""
            property bool irisScreenGradient: false
            property string irisScreenSize: "medium"
            property string irisScreenOpts: ""
            property string irisScreenStyle: "inir"
            property int irisScreenRadius: -1
            property real irisScreenPad: -1
            property real irisScreenBorder: -1
            property real irisScreenBorderOpacity: -1
            property real irisScreenBackingOpacity: -1
            property bool irisVitalsEnabled: false
            property real irisVitalsScale: 1.0
            property string irisVitalsAnchor: "free"
            property int irisVitalsX: 168
            property int irisVitalsY: 520
            property bool irisVitalsLocked: false
            property real irisVitalsOpacity: 1.0
            property string irisVitalsBg: "card"
            property string irisVitalsColor: ""
            property string irisVitalsColor2: ""
            property bool irisVitalsGradient: false
            property string irisVitalsSize: "medium"
            property string irisVitalsOpts: ""
            property string irisVitalsStyle: "inir"
            property int irisVitalsRadius: -1
            property real irisVitalsPad: -1
            property real irisVitalsBorder: -1
            property real irisVitalsBorderOpacity: -1
            property real irisVitalsBackingOpacity: -1
            property bool irisBatteryEnabled: false
            property real irisBatteryScale: 1.0
            property string irisBatteryAnchor: "free"
            property int irisBatteryX: 216
            property int irisBatteryY: 560
            property bool irisBatteryLocked: false
            property real irisBatteryOpacity: 1.0
            property string irisBatteryBg: "card"
            property string irisBatteryColor: ""
            property string irisBatteryColor2: ""
            property bool irisBatteryGradient: false
            property string irisBatterySize: "small"
            property string irisBatteryOpts: ""
            property string irisBatteryStyle: "inir"
            property int irisBatteryRadius: -1
            property real irisBatteryPad: -1
            property real irisBatteryBorder: -1
            property real irisBatteryBorderOpacity: -1
            property real irisBatteryBackingOpacity: -1
            property bool irisWorldEnabled: false
            property real irisWorldScale: 1.0
            property string irisWorldAnchor: "free"
            property int irisWorldX: 120
            property int irisWorldY: 600
            property bool irisWorldLocked: false
            property real irisWorldOpacity: 1.0
            property string irisWorldBg: "card"
            property string irisWorldColor: ""
            property string irisWorldColor2: ""
            property bool irisWorldGradient: false
            property string irisWorldSize: "medium"
            property string irisWorldOpts: ""
            property string irisWorldStyle: "inir"
            property int irisWorldRadius: -1
            property real irisWorldPad: -1
            property real irisWorldBorder: -1
            property real irisWorldBorderOpacity: -1
            property real irisWorldBackingOpacity: -1
            property bool irisDateEnabled: false
            property real irisDateScale: 1.0
            property string irisDateAnchor: "free"
            property int irisDateX: 168
            property int irisDateY: 640
            property bool irisDateLocked: false
            property real irisDateOpacity: 1.0
            property string irisDateBg: "card"
            property string irisDateColor: ""
            property string irisDateColor2: ""
            property bool irisDateGradient: false
            property string irisDateSize: "small"
            property string irisDateOpts: ""
            property string irisDateStyle: "inir"
            property int irisDateRadius: -1
            property real irisDatePad: -1
            property real irisDateBorder: -1
            property real irisDateBorderOpacity: -1
            property real irisDateBackingOpacity: -1
            property bool irisProfileEnabled: false
            property real irisProfileScale: 1.0
            property string irisProfileAnchor: "free"
            property int irisProfileX: 216
            property int irisProfileY: 680
            property bool irisProfileLocked: false
            property real irisProfileOpacity: 1.0
            property string irisProfileBg: "card"
            property string irisProfileColor: ""
            property string irisProfileColor2: ""
            property bool irisProfileGradient: false
            property string irisProfileSize: "medium"
            property string irisProfileOpts: ""
            property string irisProfileStyle: "inir"
            property int irisProfileRadius: -1
            property real irisProfilePad: -1
            property real irisProfileBorder: -1
            property real irisProfileBorderOpacity: -1
            property real irisProfileBackingOpacity: -1
            property bool irisUptimeEnabled: false
            property real irisUptimeScale: 1.0
            property string irisUptimeAnchor: "free"
            property int irisUptimeX: 120
            property int irisUptimeY: 720
            property bool irisUptimeLocked: false
            property real irisUptimeOpacity: 1.0
            property string irisUptimeBg: "card"
            property string irisUptimeColor: ""
            property string irisUptimeColor2: ""
            property bool irisUptimeGradient: false
            property string irisUptimeSize: "small"
            property string irisUptimeOpts: ""
            property string irisUptimeStyle: "inir"
            property int irisUptimeRadius: -1
            property real irisUptimePad: -1
            property real irisUptimeBorder: -1
            property real irisUptimeBorderOpacity: -1
            property real irisUptimeBackingOpacity: -1
            property bool irisNewsEnabled: false
            property real irisNewsScale: 1.0
            property string irisNewsAnchor: "free"
            property int irisNewsX: 168
            property int irisNewsY: 760
            property bool irisNewsLocked: false
            property real irisNewsOpacity: 1.0
            property string irisNewsBg: "card"
            property string irisNewsColor: ""
            property string irisNewsColor2: ""
            property bool irisNewsGradient: false
            property string irisNewsSize: "medium"
            property string irisNewsOpts: ""
            property string irisNewsStyle: "inir"
            property int irisNewsRadius: -1
            property real irisNewsPad: -1
            property real irisNewsBorder: -1
            property real irisNewsBorderOpacity: -1
            property real irisNewsBackingOpacity: -1
            // iRiS canvas widgets
            property bool irisCustomImageEnabled: false
            property real irisCustomImageScale: 1.0
            property string irisCustomImageAnchor: "free"
            property int irisCustomImageX: 216
            property int irisCustomImageY: 800
            property bool irisCustomImageLocked: false
            property real irisCustomImageOpacity: 1.0
            property string irisCustomImageBg: "card"
            property string irisCustomImageColor: ""
            property string irisCustomImageColor2: ""
            property bool irisCustomImageGradient: false
            property string irisCustomImageSize: "small"
            property string irisCustomImageOpts: ""
            property string irisCustomImageStyle: "inir"
            property int irisCustomImageRadius: -1
            property real irisCustomImagePad: -1
            property real irisCustomImageBorder: -1
            property real irisCustomImageBorderOpacity: -1
            property real irisCustomImageBackingOpacity: -1
            property bool irisEditorialEnabled: false
            property real irisEditorialScale: 1.0
            property string irisEditorialAnchor: "free"
            property int irisEditorialX: 120
            property int irisEditorialY: 840
            property bool irisEditorialLocked: false
            property real irisEditorialOpacity: 1.0
            property string irisEditorialBg: "card"
            property string irisEditorialColor: ""
            property string irisEditorialColor2: ""
            property bool irisEditorialGradient: false
            property string irisEditorialSize: "small"
            property string irisEditorialOpts: ""
            property string irisEditorialStyle: "inir"
            property int irisEditorialRadius: -1
            property real irisEditorialPad: -1
            property real irisEditorialBorder: -1
            property real irisEditorialBorderOpacity: -1
            property real irisEditorialBackingOpacity: -1
            property bool irisConverterEnabled: false
            property real irisConverterScale: 1.0
            property string irisConverterAnchor: "free"
            property int irisConverterX: 168
            property int irisConverterY: 880
            property bool irisConverterLocked: false
            property real irisConverterOpacity: 1.0
            property string irisConverterBg: "card"
            property string irisConverterColor: ""
            property string irisConverterColor2: ""
            property bool irisConverterGradient: false
            property string irisConverterSize: "small"
            property string irisConverterOpts: ""
            property string irisConverterStyle: "inir"
            property int irisConverterRadius: -1
            property real irisConverterPad: -1
            property real irisConverterBorder: -1
            property real irisConverterBorderOpacity: -1
            property real irisConverterBackingOpacity: -1
            property bool irisJpEnabled: false
            property real irisJpScale: 1.0
            property string irisJpAnchor: "free"
            property int irisJpX: 120
            property int irisJpY: 960
            property bool irisJpLocked: false
            property real irisJpOpacity: 1.0
            property string irisJpBg: "card"
            property string irisJpColor: ""
            property string irisJpColor2: ""
            property bool irisJpGradient: false
            property string irisJpSize: "small"
            property string irisJpOpts: ""
            property string irisJpStyle: "inir"
            property int irisJpRadius: -1
            property real irisJpPad: -1
            property real irisJpBorder: -1
            property real irisJpBorderOpacity: -1
            property real irisJpBackingOpacity: -1
            property bool irisVisualizerEnabled: false
            property real irisVisualizerScale: 1.0
            property string irisVisualizerAnchor: "free"
            property int irisVisualizerX: 168
            property int irisVisualizerY: 1000
            property bool irisVisualizerLocked: false
            property real irisVisualizerOpacity: 1.0
            property string irisVisualizerBg: "card"
            property string irisVisualizerColor: ""
            property string irisVisualizerColor2: ""
            property bool irisVisualizerGradient: false
            property string irisVisualizerSize: "small"
            property string irisVisualizerOpts: ""
            property string irisVisualizerStyle: "inir"
            property int irisVisualizerRadius: -1
            property real irisVisualizerPad: -1
            property real irisVisualizerBorder: -1
            property real irisVisualizerBorderOpacity: -1
            property real irisVisualizerBackingOpacity: -1
        }
    }

    // ── head: eyebrow, Fraunces title, blurb (matches every settings page) ──
    Column {
        id: head
        anchors.top: parent.top
        anchors.topMargin: Tokens.s6
        // the head sits on the body's grid, so the title starts over the first card
        x: Tokens.s6
        width: Math.max(320, pg.width - Tokens.s6 * 2 - Tokens.s3)
        // the register row sits off the title: a rule over a 32px
        // title needs more than the gap between two lines of body text
        spacing: Tokens.s3

        Row {
            // the register row holds a fixed box, so the rule and the seal keep
            // their distance from the title on every page
            height: Tokens.s5
            spacing: Tokens.s2
            Rectangle {
                width: 16; height: 1; color: Tokens.ink
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "力"; color: Tokens.ink; font.family: Tokens.jp
                font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: I18n.tr("DESKTOP"); color: Tokens.inkMuted; font.family: Tokens.ui
                font.pixelSize: 9; font.weight: Font.Medium; font.letterSpacing: Tokens.trackMark
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Text {
            text: I18n.tr("Desktop Widgets"); color: Tokens.ink
            font.family: Tokens.display; font.pixelSize: Tokens.fTitle
        }
        Text {
            width: Math.min(parent.width, 720)
            text: I18n.tr("The widgets on your wallpaper, previewed live.")
            color: Tokens.inkMuted; font.family: Tokens.ui
            font.pixelSize: Tokens.fBody; wrapMode: Text.WordWrap
        }
    }

    // ── the widget catalogue: a card per widget; a card opens its settings ────
    // Grid view lists every desktop widget as a live-preview card with an on/off
    // toggle; clicking a card slides in that widget's settings subpage. One draft,
    // one Save bar for all of them (unchanged below).
    property string selected: ""   // "" = grid; else the open widget's tab

    readonly property var widgets: [
        { "tab": "clock",    "title": I18n.tr("Clock"),        "jp": "時計", "enable": "clockEnabled",    "anchor": "clockAnchor",    "natW": 300, "natH": 150 },
        { "tab": "aio",      "title": I18n.tr("All-in-one"),   "jp": "一体", "enable": "aioEnabled",      "anchor": "aioAnchor",      "natW": 354, "natH": 227 },
        { "tab": "stats",    "title": I18n.tr("System Stats"), "jp": "統計", "enable": "statsEnabled",    "anchor": "statsAnchor",    "natW": 261, "natH": 458 },
        { "tab": "calendar", "title": I18n.tr("Calendar"),     "jp": "暦",   "enable": "calendarEnabled", "anchor": "calendarAnchor", "natW": 330, "natH": 210 },
        { "tab": "music",    "title": I18n.tr("Music"),        "jp": "音楽", "enable": "musicEnabled",    "anchor": "musicAnchor",    "natW": 400, "natH": 216 },
        { "tab": "weather",  "title": I18n.tr("Weather"),      "jp": "天気", "enable": "weatherEnabled",  "anchor": "weatherAnchor",  "natW": 220, "natH": 390 },
        { "tab": "notes",    "title": I18n.tr("Notes"),        "jp": "メモ", "enable": "notesEnabled",    "anchor": "notesAnchor",    "natW": 260, "natH": 180 },
        { "tab": "dayprogress", "title": I18n.tr("Day Progress"), "jp": "経過", "enable": "dayprogressEnabled", "anchor": "dayprogressAnchor", "natW": 200, "natH": 224 },
        { "tab": "shape",    "title": I18n.tr("Shape"),        "jp": "図形", "enable": "shapeEnabled",    "anchor": "shapeAnchor",    "natW": 140, "natH": 140 },
        // iRiS faces (hosted in Ryoku slots; previews are null — icon card only)
        { "tab": "irisClock", "title": I18n.tr("Clock"), "jp": "時計", "enable": "irisClockEnabled", "anchor": "irisClockAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisWeather", "title": I18n.tr("Weather"), "jp": "天気", "enable": "irisWeatherEnabled", "anchor": "irisWeatherAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisMedia", "title": I18n.tr("Now Playing"), "jp": "音楽", "enable": "irisMediaEnabled", "anchor": "irisMediaAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisControls", "title": I18n.tr("Controls"), "jp": "操作", "enable": "irisControlsEnabled", "anchor": "irisControlsAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisMonth", "title": I18n.tr("Calendar"), "jp": "暦", "enable": "irisMonthEnabled", "anchor": "irisMonthAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisAgenda", "title": I18n.tr("Up next"), "jp": "予定", "enable": "irisAgendaEnabled", "anchor": "irisAgendaAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisTodo", "title": I18n.tr("Tasks"), "jp": "課題", "enable": "irisTodoEnabled", "anchor": "irisTodoAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisNotes", "title": I18n.tr("Notes"), "jp": "筆記", "enable": "irisNotesEnabled", "anchor": "irisNotesAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisTimers", "title": I18n.tr("Timers"), "jp": "計時", "enable": "irisTimersEnabled", "anchor": "irisTimersAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisScreen", "title": I18n.tr("Screen Time"), "jp": "時間", "enable": "irisScreenEnabled", "anchor": "irisScreenAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisVitals", "title": I18n.tr("Vitals"), "jp": "計測", "enable": "irisVitalsEnabled", "anchor": "irisVitalsAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisBattery", "title": I18n.tr("Batteries"), "jp": "電池", "enable": "irisBatteryEnabled", "anchor": "irisBatteryAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisWorld", "title": I18n.tr("World clock"), "jp": "世界", "enable": "irisWorldEnabled", "anchor": "irisWorldAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisDate", "title": I18n.tr("Date"), "jp": "日付", "enable": "irisDateEnabled", "anchor": "irisDateAnchor", "natW": 200, "natH": 200 },
        { "tab": "irisProfile", "title": I18n.tr("Profile"), "jp": "人物", "enable": "irisProfileEnabled", "anchor": "irisProfileAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisUptime", "title": I18n.tr("Uptime"), "jp": "稼働", "enable": "irisUptimeEnabled", "anchor": "irisUptimeAnchor", "natW": 200, "natH": 200 },
        { "tab": "irisNews", "title": I18n.tr("News"), "jp": "報道", "enable": "irisNewsEnabled", "anchor": "irisNewsAnchor", "natW": 356, "natH": 200 },
        { "tab": "irisCustomImage", "title": I18n.tr("Custom Image"), "jp": "画像", "enable": "irisCustomImageEnabled", "anchor": "irisCustomImageAnchor", "natW": 320, "natH": 200 },
        { "tab": "irisEditorial", "title": I18n.tr("Editorial"), "jp": "社説", "enable": "irisEditorialEnabled", "anchor": "irisEditorialAnchor", "natW": 360, "natH": 200 },
        { "tab": "irisConverter", "title": I18n.tr("Image Converter"), "jp": "変換", "enable": "irisConverterEnabled", "anchor": "irisConverterAnchor", "natW": 300, "natH": 200 },
        { "tab": "irisJp", "title": I18n.tr("Japanese Type"), "jp": "縦書", "enable": "irisJpEnabled", "anchor": "irisJpAnchor", "natW": 200, "natH": 200 },
        { "tab": "irisVisualizer", "title": I18n.tr("iRiS Visualizer"), "jp": "音波", "enable": "irisVisualizerEnabled", "anchor": "irisVisualizerAnchor", "natW": 304, "natH": 200 }
    ]
    function widgetOf(tab) { for (var i = 0; i < pg.widgets.length; i++) if (pg.widgets[i].tab === tab) return pg.widgets[i]; return null; }
    readonly property var curWidget: pg.selected === "" ? null : pg.widgetOf(pg.selected)

    // one preview per widget, reused by the grid card and the subpage specimen.
    Component { id: clockPrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../ClockPreview.qml")
        onLoaded: { item.design = Qt.binding(() => pg.draft.clockDesign || "digital"); item.is24 = Qt.binding(() => pg.draft.clock24h === true); item.seconds = Qt.binding(() => pg.draft.clockSeconds === true); item.accentChoice = Qt.binding(() => pg.draft.clockAccent || "palette"); item.dateShow = Qt.binding(() => pg.draft.dateShow === true); item.dateDesign = Qt.binding(() => pg.draft.dateDesign || "inline"); } } }
    Component { id: aioPrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../AioPreview.qml")
        onLoaded: { item.style = Qt.binding(() => pg.draft.aioStyle || "wide"); } } }
    Component { id: statsPrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../StatsPreview.qml") } }
    Component { id: calPrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../CalendarPreview.qml")
        onLoaded: { item.style = Qt.binding(() => pg.draft.calendarStyle || "glass"); item.weeks = Qt.binding(() => pg.draft.calendarWeeks || 6); item.showWeekNumbers = Qt.binding(() => pg.draft.calendarWeekNumbers === true); } } }
    Component { id: musicPrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../MusicPreview.qml")
        onLoaded: { item.style = Qt.binding(() => pg.draft.musicStyle || "cover"); item.lyrics = Qt.binding(() => pg.draft.musicLyrics === true); item.viz = Qt.binding(() => pg.draft.musicViz || "bars"); } } }
    Component { id: weatherPrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../WeatherPreview.qml")
        onLoaded: { item.design = Qt.binding(() => pg.draft.weatherDesign || "compact"); } } }
    Component { id: notesPrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../NotesPreview.qml") } }
    Component { id: dayprogressPrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../DayProgressPreview.qml") } }
    Component { id: shapePrevC; Loader { anchors.fill: parent; source: Qt.resolvedUrl("../ShapePreview.qml") } }
    function previewFor(tab) {
        switch (tab) { case "clock": return clockPrevC; case "aio": return aioPrevC; case "stats": return statsPrevC; case "calendar": return calPrevC; case "music": return musicPrevC; case "weather": return weatherPrevC; case "notes": return notesPrevC; case "dayprogress": return dayprogressPrevC; case "shape": return shapePrevC; default: return null; }
    }

    // ── store-installed desktop widgets ──────────────────────────────────────
    // Plugins whose home is the wallpaper, discovered exactly as the Add-ons
    // page does (discover.sh --all, then keep only the desktopWidget host).
    // They live below the built-in grid, grouped by the set their manifest
    // names, and toggle live through ryoku-plugins-place -- outside this page's
    // draft/Save flow entirely.
    property var storeRows: []

    readonly property string shellDir: Quickshell.env("RYOKU_SHELL_DIR")
    readonly property string discoverScript: (pg.shellDir && pg.shellDir.length > 0)
        ? pg.shellDir + "/quickshell/plugins/discover.sh"
        : (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/quickshell/plugins/discover.sh"

    // group into sections in first-seen set order; plugins that name no set fall
    // to a final "Plugins" section, so any future set slots in with no change.
    readonly property var storeSections: {
        var order = [];
        var byKey = ({});
        var loose = [];
        for (var i = 0; i < pg.storeRows.length; i++) {
            var r = pg.storeRows[i];
            var s = r.set || "";
            if (s === "") { loose.push(r); continue; }
            if (byKey[s] === undefined) { byKey[s] = []; order.push(s); }
            byKey[s].push(r);
        }
        var out = [];
        for (var j = 0; j < order.length; j++)
            out.push({ "name": order[j], "rows": byKey[order[j]] });
        if (loose.length > 0)
            out.push({ "name": I18n.tr("Plugins"), "rows": loose });
        return out;
    }

    function refreshStore() { storeProc.running = false; storeProc.running = true; }
    function placePlugin(id, enabled) {
        if (!id)
            return;
        storePlaceProc.command = ["ryoku-plugins-place", id, "enabled", enabled ? "true" : "false"];
        storePlaceProc.running = true;
    }

    Process {
        id: storeProc
        command: ["bash", pg.discoverScript, "--all"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var list = [];
                try { list = JSON.parse(text || "[]"); } catch (e) { list = []; }
                var rows = [];
                for (var i = 0; i < list.length; i++) {
                    var e = list[i];
                    var man = e.manifest || ({});
                    var place = e.placement || ({});
                    var host = place.host
                        ? place.host
                        : ((man.defaults && man.defaults.host) ? man.defaults.host : "framePopout");
                    if (host !== "desktopWidget")
                        continue;
                    rows.push({
                        "id": e.id,
                        "title": man.name || e.id,
                        "set": man.set || "",
                        "enabled": place.enabled === true,
                        "icon": (man.defaults && man.defaults.icon) ? man.defaults.icon : "",
                        "dir": e.dir || "",
                        "settings": (place.settings && typeof place.settings === "object") ? place.settings : ({})
                    });
                }
                pg.storeRows = rows;
            }
        }
    }
    // a placement toggle re-reads the truth, so the ON/OFF line and the switch
    // settle on what actually landed on disk.
    Process { id: storePlaceProc; onExited: pg.refreshStore() }

    // installing a set from the store writes plugins.json; that write lights up
    // this shelf without reopening the Hub.
    FileView {
        id: placementWatch
        path: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/ryoku/plugins.json"
        watchChanges: true
        printErrors: false
        onFileChanged: pg.refreshStore()
    }

    Item {
        id: content
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: bar.top }
        anchors.leftMargin: Tokens.s6; anchors.rightMargin: Tokens.s6
        anchors.topMargin: Tokens.s5; anchors.bottomMargin: Tokens.s4

        // ── grid of widget cards ──────────────────────────────────────────────
        Flickable {
            id: gridFlick
            anchors.fill: parent
            contentHeight: (pg.storeSections.length > 0 ? storeStack.y + storeStack.height : grid.height) + Tokens.s5
            clip: true
            interactive: pg.selected === ""
            opacity: pg.selected === "" ? 1 : 0
            visible: opacity > 0.01
            enabled: pg.selected === ""
            Behavior on opacity { NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease } }
            ScrollBar.vertical: ScrollRail { policy: ScrollBar.AsNeeded }
            WheelScroll { }

            Flow {
                id: grid
                width: gridFlick.width
                spacing: Tokens.s4

                Repeater {
                    model: pg.widgets
                    delegate: Rectangle {
                        id: wcard
                        required property var modelData
                        readonly property bool on: pg.draft[wcard.modelData.enable] === true
                        width: Math.max(280, Math.min(360, (grid.width - Tokens.s4 * 2) / 3))
                        height: 236
                        radius: Tokens.radius
                        color: Tokens.paperLift
                        border.width: Tokens.border
                        border.color: wcHover.hovered ? Tokens.sun : (wcard.on ? Tokens.line : Tokens.lineSoft)
                        Behavior on border.color { ColorAnimation { duration: Tokens.snap } }

                        HoverHandler { id: wcHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: pg.selected = wcard.modelData.tab
                        }

                        Item {
                            id: pbody
                            anchors { left: parent.left; right: parent.right; top: parent.top }
                            anchors.margins: Tokens.s3
                            height: wcard.height - footer.height - Tokens.s3 * 3
                            clip: true
                            opacity: wcard.on ? 1 : 0.45
                            Behavior on opacity { NumberAnimation { duration: Tokens.snap } }
                            Item {
                                id: pwrap
                                width: wcard.modelData.natW
                                // the preview's own natural height when it reports one,
                                // so a face with a date line is scaled to fit whole
                                // rather than clipped at the card's edge.
                                readonly property real natH: (pv.item && pv.item.implicitHeight > 0)
                                    ? pv.item.implicitHeight : wcard.modelData.natH
                                height: natH
                                anchors.centerIn: parent
                                // never upscale past natural size: a preview blown
                                // up to fill clips flush against the footer and its
                                // glyphs read as overlapping the label row.
                                scale: Math.min(pbody.width / pwrap.width, pbody.height / pwrap.natH, 1.0)
                                Loader { id: pv; anchors.fill: parent; sourceComponent: pg.previewFor(wcard.modelData.tab) }
                            }
                        }

                        Item {
                            id: footer
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            anchors.leftMargin: Tokens.s4; anchors.rightMargin: Tokens.s3; anchors.bottomMargin: Tokens.s3
                            height: 34
                            Column {
                                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                spacing: 2
                                Text { text: I18n.tr(wcard.modelData.title); color: Tokens.ink; font.family: Tokens.ui; font.pixelSize: Tokens.fRow; font.weight: Font.Medium }
                                Text {
                                    text: (wcard.on ? I18n.tr("On") : I18n.tr("Off")).toUpperCase() + "  ·  " + String(pg.draft[wcard.modelData.anchor] || "").toUpperCase()
                                    color: wcard.on ? Tokens.inkMuted : Tokens.inkFaint
                                    font.family: Tokens.mono; font.pixelSize: Tokens.fTiny; font.letterSpacing: 0.6
                                }
                            }
                            Sw {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                on: wcard.on
                                onToggled: (v) => pg.edit(wcard.modelData.enable, v)
                            }
                        }
                    }
                }
            }

            // ── store-installed desktop widgets, grouped by set ───────────────
            // A second shelf under the built-in grid: a divider, then a section
            // per set. Nothing draws when none are installed, so a stock desktop
            // reads exactly as before. These toggle live through the placement
            // backend and stay clear of the Save bar's dirty state.
            Column {
                id: storeStack
                anchors.top: grid.bottom
                anchors.topMargin: Tokens.s5
                width: gridFlick.width
                spacing: Tokens.s5
                visible: pg.storeSections.length > 0

                Rectangle { width: parent.width; height: 1; color: Tokens.line }

                Repeater {
                    model: pg.storeSections
                    delegate: Column {
                        id: setSection
                        required property var modelData
                        width: storeStack.width
                        spacing: Tokens.s4

                        Text {
                            text: setSection.modelData.name
                            color: Tokens.inkMuted; font.family: Tokens.ui
                            font.pixelSize: Tokens.fMicro; font.weight: Font.Medium
                            font.letterSpacing: Tokens.trackMark
                            font.capitalization: Font.AllUppercase
                        }

                        Flow {
                            width: setSection.width
                            spacing: Tokens.s4
                            Repeater {
                                model: setSection.modelData.rows
                                // resolved by URL, not a bare sibling type: the
                                // Hub's pages/ dir has no qmldir, so a type
                                // declared beside this page does not register
                                // after an upgrade (same form ProfilePage uses
                                // for HeroEditor/ProfileToolbar). (#251)
                                delegate: Loader {
                                    id: widgetCardLoader
                                    required property var modelData
                                    width: Math.max(280, Math.min(360, (setSection.width - Tokens.s4 * 2) / 3))
                                    height: 236
                                    source: Qt.resolvedUrl("StoreWidgetCard.qml")
                                    onLoaded: {
                                        if (!item)
                                            return
                                        item.title = modelData.title
                                        item.on = modelData.enabled === true
                                        item.icon = modelData.icon
                                        item.dir = modelData.dir
                                        item.settings = modelData.settings
                                        item.toggled.connect(function (v) { pg.placePlugin(modelData.id, v) })
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── a widget's settings subpage ───────────────────────────────────────
        Item {
            id: sub
            anchors.fill: parent
            opacity: pg.selected !== "" ? 1 : 0
            visible: opacity > 0.01
            enabled: pg.selected !== ""
            Behavior on opacity { NumberAnimation { duration: Tokens.swap; easing.type: Tokens.ease } }

            Item {
                id: backRow
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 30
                Row {
                    id: crumb
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    spacing: Tokens.s2
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "‹  " + I18n.tr("All widgets")
                        color: backHover.hovered ? Tokens.ink : Tokens.inkMuted
                        font.family: Tokens.ui; font.pixelSize: Tokens.fSmall; font.weight: Font.Medium
                    }
                    HoverHandler { id: backHover }
                }
                MouseArea { anchors.fill: crumb; cursorShape: Qt.PointingHandCursor; onClicked: pg.selected = "" }
                Text {
                    anchors { left: crumb.right; leftMargin: Tokens.s4; verticalCenter: parent.verticalCenter }
                    text: pg.curWidget ? I18n.tr(pg.curWidget.title) : ""
                    color: Tokens.ink; font.family: Tokens.display; font.pixelSize: Tokens.fHero
                }
            }

            Loader {
                id: sheetLoader
                anchors {
                    left: parent.left; right: subPreview.left
                    top: backRow.bottom; bottom: parent.bottom
                    rightMargin: Tokens.s5; topMargin: Tokens.s4
                }
                source: Qt.resolvedUrl("../SettingsSheet.qml")
                onLoaded: {
                    item.schema = Qt.binding(() => pg.schemaRows);
                    item.draft = Qt.binding(() => pg.sheetDraft);
                    item.defaults = Qt.binding(() => pg.sheetDefaults);
                    item.tab = Qt.binding(() => pg.selected);
                    item.query = Qt.binding(() => pg.query);
                    // the rail's Advanced toggle reveals the per-widget desktop lock
                    item.advanced = Qt.binding(() => !!(pg.hub && pg.hub.advanced));
                    item.edited.connect(pg.onSheetEdited);
                    item.pickRequested.connect(pg.onSheetPick);
                    item.appPickRequested.connect(pg.onSheetAppPick);
                }
            }

            SpecimenCard {
                id: subPreview
                anchors { right: parent.right; top: backRow.bottom; bottom: parent.bottom }
                anchors.topMargin: Tokens.s4
                width: Math.round(Math.min(420, Math.max(300, pg.width * 0.34)))
                title: pg.curWidget ? I18n.tr("LIVE PREVIEW") : ""
                on: pg.curWidget ? (pg.draft[pg.curWidget.enable] === true) : false
                anchor: pg.curWidget ? (pg.draft[pg.curWidget.anchor] || "center") : "center"
                natW: pg.curWidget ? pg.curWidget.natW : 300
                natH: pg.curWidget ? pg.curWidget.natH : 200
                preview: pg.selected !== "" ? pg.previewFor(pg.selected) : null
            }
        }
    }

    // ── action bar: status + Reset / Revert / Save ──────────────────────────
    // full-bleed, so the shell's global bar is hidden and this is the only way
    // to persist. nothing writes until Save (DESIGN.md section 11).
    Rectangle {
        id: bar
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 60
        color: "transparent"

        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 1; color: Tokens.line
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Tokens.s6
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.s3

            Rectangle {
                id: dot
                anchors.verticalCenter: parent.verticalCenter
                width: 6; height: 6; radius: 3
                antialiasing: false
                color: pg.dirty ? Tokens.ink : "transparent"
                border.width: pg.dirty ? 0 : Tokens.border
                border.color: Tokens.inkFaint

                SequentialAnimation on opacity {
                    running: pg.dirty
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    onStopped: dot.opacity = 1
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pg.dirty
                    ? (pg.dirtyCount === 1
                       ? I18n.tr("%1 CHANGE · PREVIEWING · NOT SAVED").arg(pg.dirtyCount)
                       : I18n.tr("%1 CHANGES · PREVIEWING · NOT SAVED").arg(pg.dirtyCount))
                    : I18n.tr("SAVED · LIVE ON YOUR DESKTOP")
                color: pg.dirty ? Tokens.ink : Tokens.inkMuted
                font.family: Tokens.ui; font.pixelSize: Tokens.fMicro
                font.weight: Font.Medium; font.letterSpacing: Tokens.trackLabel
                font.capitalization: Font.AllUppercase
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Tokens.s6
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.s3

            Btn {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("RESET TO DEFAULTS")
                onAct: pg.reset()
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 20; color: Tokens.line
            }
            Btn {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("REVERT")
                armed: pg.dirty
                onAct: pg.revert()
            }
            Btn {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("SAVE")
                primary: true
                armed: pg.dirty
                onAct: pg.save()
            }
        }
    }

    // ── the anchor catalogue overlay (Picker), shared by the pick cells ──────
    property var pickRow: null
    property var appPickRow: null
    function onSheetAppPick(r) { pg.appPickRow = r; }

    MouseArea {
        id: scrim
        anchors.fill: parent
        visible: pg.pickRow !== null
        z: 100
        onClicked: pg.pickRow = null
        onVisibleChanged: if (visible) picker.open()

        Picker {
            id: picker
            anchors.centerIn: parent
            title: pg.pickRow ? I18n.tr(pg.pickRow.label) : ""
            options: pg.pickRow ? (pg.pickRow.opts || []) : []
            current: pg.pickRow ? String(pg.draft[pg.pickRow.key]) : ""
            // the only pick rows on this page are the anchor pickers; give the
            // new "auto" value a human label, the rest keep their raw key.
            labels: ({ "auto": I18n.tr("Auto (calm spot)") })
            onChose: (key) => {
                if (pg.pickRow)
                    pg.edit(pg.pickRow.key, key);
                pg.pickRow = null;
            }
            onDismissed: pg.pickRow = null

            MouseArea { anchors.fill: parent; z: -1 }
        }
    }

    // ── the music-app picker overlay (keybinds-style), for the "app" cell ────
    Loader {
        id: appPickerLoader
        anchors.fill: parent
        z: 101
        active: pg.appPickRow !== null
        source: active ? Qt.resolvedUrl("../AppPicker.qml") : ""
        onLoaded: {
            item.title = Qt.binding(() => pg.appPickRow ? I18n.tr(pg.appPickRow.label) : "");
            item.chosen.connect(function (cmd) {
                if (pg.appPickRow) pg.edit(pg.appPickRow.key, cmd);
                pg.appPickRow = null;
            });
            item.dismissed.connect(function () { pg.appPickRow = null; });
        }
    }
}
