#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantMap>
#include <qqmlintegration.h>

class QQmlEngine;
class QJSEngine;

// Preferences is the app's own tiny state: window geometry, the last page you
// visited, sidebar collapse, and per-thread drafts. It is UI-owned on purpose
// -- the daemon never reads this file, and nothing in it is a system fact.
// It lives at $XDG_STATE_HOME/ryoku/rashin-app.json and saves debounced.
class Preferences : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QString page READ page WRITE setPage NOTIFY changed)
    Q_PROPERTY(bool sidebarCollapsed READ sidebarCollapsed WRITE setSidebarCollapsed NOTIFY changed)
    Q_PROPERTY(int winWidth READ winWidth WRITE setWinWidth NOTIFY changed)
    Q_PROPERTY(int winHeight READ winHeight WRITE setWinHeight NOTIFY changed)

public:
    explicit Preferences(QObject *parent = nullptr);
    static Preferences *create(QQmlEngine * /*engine*/, QJSEngine * /*js*/) { return instance(); }
    static Preferences *instance();

    QString page() const { return m_page; }
    void setPage(const QString &v);
    bool sidebarCollapsed() const { return m_sidebarCollapsed; }
    void setSidebarCollapsed(bool v);
    int winWidth() const { return m_winWidth; }
    void setWinWidth(int v);
    int winHeight() const { return m_winHeight; }
    void setWinHeight(int v);

    // Drafts ride the map: draft("<sessionId or new>") reads, setDraft saves.
    Q_INVOKABLE QString draft(const QString &key) const;
    Q_INVOKABLE void setDraft(const QString &key, const QString &text);

signals:
    void changed();

private:
    void load();
    void scheduleSave();
    void save();

    QString m_page;
    bool m_sidebarCollapsed = false;
    int m_winWidth = 0;
    int m_winHeight = 0;
    QVariantMap m_drafts;
    bool m_dirty = false;
    QTimer m_saveTimer;
};
