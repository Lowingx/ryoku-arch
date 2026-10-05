#include "preferences.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

// preferences.cpp: one small JSON file under the state dir, read once at
// startup, written debounced. A failed write is silent by design: a lost
// draft is not worth a dialog, and nothing here is authoritative.

namespace {

QString statePath() {
    // GenericStateLocation respects XDG_STATE_HOME and defaults to
    // ~/.local/state, the same home the daemon's ask history lives under.
    const auto dirs = QStandardPaths::standardLocations(QStandardPaths::GenericStateLocation);
    const auto base = dirs.isEmpty() ? QDir::homePath() + QStringLiteral("/.local/state") : dirs.first();
    return base + QStringLiteral("/ryoku/rashin-app.json");
}

} // namespace

Preferences *Preferences::instance() {
    static Preferences *self = new Preferences;
    return self;
}

Preferences::Preferences(QObject *parent) : QObject(parent) {
    m_saveTimer.setSingleShot(true);
    m_saveTimer.setInterval(500);
    connect(&m_saveTimer, &QTimer::timeout, this, &Preferences::save);
    load();
}

void Preferences::load() {
    QFile f(statePath());
    if (!f.open(QIODevice::ReadOnly))
        return;
    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return;
    const auto o = doc.object();
    m_page = o.value(QStringLiteral("page")).toString();
    m_sidebarCollapsed = o.value(QStringLiteral("sidebarCollapsed")).toBool();
    m_winWidth = o.value(QStringLiteral("winWidth")).toInt();
    m_winHeight = o.value(QStringLiteral("winHeight")).toInt();
    m_drafts = o.value(QStringLiteral("drafts")).toObject().toVariantMap();
}

void Preferences::scheduleSave() {
    m_dirty = true;
    m_saveTimer.start();
}

void Preferences::save() {
    if (!m_dirty)
        return;
    m_dirty = false;
    QJsonObject o;
    o.insert(QStringLiteral("page"), m_page);
    o.insert(QStringLiteral("sidebarCollapsed"), m_sidebarCollapsed);
    o.insert(QStringLiteral("winWidth"), m_winWidth);
    o.insert(QStringLiteral("winHeight"), m_winHeight);
    o.insert(QStringLiteral("drafts"), QJsonObject::fromVariantMap(m_drafts));
    const auto path = statePath();
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile f(path);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return;
    f.write(QJsonDocument(o).toJson(QJsonDocument::Indented));
}

void Preferences::setPage(const QString &v) {
    if (m_page == v)
        return;
    m_page = v;
    emit changed();
    scheduleSave();
}

void Preferences::setSidebarCollapsed(bool v) {
    if (m_sidebarCollapsed == v)
        return;
    m_sidebarCollapsed = v;
    emit changed();
    scheduleSave();
}

void Preferences::setWinWidth(int v) {
    if (m_winWidth == v)
        return;
    m_winWidth = v;
    emit changed();
    scheduleSave();
}

void Preferences::setWinHeight(int v) {
    if (m_winHeight == v)
        return;
    m_winHeight = v;
    emit changed();
    scheduleSave();
}

QString Preferences::draft(const QString &key) const {
    return m_drafts.value(key).toString();
}

void Preferences::setDraft(const QString &key, const QString &text) {
    if (text.isEmpty()) {
        if (!m_drafts.contains(key))
            return;
        m_drafts.remove(key);
    } else {
        if (m_drafts.value(key).toString() == text)
            return;
        m_drafts.insert(key, text);
    }
    scheduleSave();
}
