#pragma once

#include <QJsonArray>
#include <qqmlintegration.h>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QObject>
#include <QVariantMap>

class QNetworkReply;
class QQmlEngine;
class QJSEngine;
// DaemonClient is the app's read/write window onto the rashin daemon's HTTP
// surface (127.0.0.1:<port> from rashin.json). Everything that is a contract
// or a system fact -- vault files, agents, skills, providers, doctor, vitals,
// the ask history -- comes from here, never from UI state. Calls are
// fire-and-forget with a single reply signal; the QML page that asked maps
// the JSON to its own view model. When the daemon is off the client reports
// `online: false` and every page degrades to the honest offline state.
class DaemonClient : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(bool online READ online NOTIFY onlineChanged)
    Q_PROPERTY(int port READ port NOTIFY portChanged)

public:
    explicit DaemonClient(QObject *parent = nullptr);
    static DaemonClient *create(QQmlEngine * /*engine*/, QJSEngine * /*js*/) { return instance(); }
    static DaemonClient *instance();

    bool online() const { return m_online; }
    int port() const { return m_port; }

    // GET <path> -> reply(path, ok, value)
    Q_INVOKABLE void get(const QString &path);
    // POST <path> with an optional JSON body -> same reply signal
    Q_INVOKABLE void post(const QString &path, const QVariantMap &body = {});

    // Read the gate and port from ~/.config/ryoku/rashin.json so the offline
    // screen can name them and a re-enable can point the client at the daemon.
    Q_INVOKABLE void refreshPort();
    // Poll /api/ping; drives `online`.
    Q_INVOKABLE void probe();

signals:
    // ok is false on transport failure; value carries the parsed JSON object
    // (a non-object body arrives wrapped under the "value" key).
    void reply(const QString &path, bool ok, const QVariantMap &value);
    void onlineChanged();
    void portChanged();

private:
    void handleReply(const QString &path, QNetworkReply *reply);
    void setOnline(bool on);

    QNetworkAccessManager *m_nam;
    bool m_online = false;
    int m_port = 3600;
};
