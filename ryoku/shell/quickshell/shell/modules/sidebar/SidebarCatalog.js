.pragma library

const catalog = [
    { id: "notifications", side: "right", tab: "notices", label: "Notifications", glyph: "notifications", source: "cards/NotificationsCard.qml" },
    { id: "weather", side: "right", tab: "weather", label: "Weather", glyph: "cloud", source: "cards/WeatherCard.qml" },
    { id: "media", side: "right", tab: "media", label: "Media", glyph: "play_circle", source: "cards/MediaCard.qml" },
    { id: "capture", side: "left", tab: "capture", label: "Capture", glyph: "photo_camera", source: "cards/CaptureCard.qml" },
    { id: "usage", side: "right", tab: "overview", label: "Activity", glyph: "monitor_heart", source: "cards/UsageCard.qml" },
    { id: "tools", side: "right", tab: "tools", label: "Tools", glyph: "download", source: "cards/ToolsCard.qml" },
    { id: "chat", side: "right", tab: "chat", label: "Chat", glyph: "chat", source: "cards/ChatCard.qml" }
];


function byId(id) {
    for (var i = 0; i < catalog.length; ++i) {
        if (catalog[i].id === id)
            return catalog[i];
    }
    return null;
}
