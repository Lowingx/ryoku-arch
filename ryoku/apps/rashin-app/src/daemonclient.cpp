#include "daemonclient.hpp"

#include <QFile>
#include <QDir>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QStandardPaths>
#include <QUrl>

// daemonclient.cpp speaks the daemon's HTTP API only. The chat stream never
// rides here (that is ChatBridge's job through the follow process); this file
// is the request/response plane: vault, agents, skills, models, doctor,
// vitals, history, and the enable/disable actuator.

DaemonClient *DaemonClient::instance() {
    static DaemonClient *self = new DaemonClient;
    return self;
}

DaemonClient::DaemonClient(QObject *parent) : QObject(parent), m_nam(new QNetworkAccessManager(this)) {
    refreshPort();
    probe();
}

void DaemonClient::refreshPort() {
    const auto dir = QStandardPaths::standardLocations(QStandardPaths::AppConfigLocation);
    QString cfg;
    const auto env = qEnvironmentVariable("XDG_CONFIG_HOME");
    if (!env.isEmpty())
        cfg = env + QStringLiteral("/ryoku/rashin.json");
    else if (!dir.isEmpty())
        cfg = dir.first() + QStringLiteral("/../ryoku/rashin.json");
    if (cfg.isEmpty())
        return;
    QFile f(QDir::cleanPath(cfg));
    if (!f.open(QIODevice::ReadOnly))
        return;
    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return;
    const int p = doc.object().value(QStringLiteral("port")).toInt(3600);
    if (p > 0 && p != m_port) {
        m_port = p;
        emit portChanged();
    }
}

void DaemonClient::probe() {
    auto *reply = m_nam->get(QNetworkRequest{QUrl(QStringLiteral("http://127.0.0.1:%1/api/ping").arg(m_port))});
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        setOnline(reply->error() == QNetworkReply::NoError);
        reply->deleteLater();
    });
}

void DaemonClient::setOnline(bool on) {
    if (m_online == on)
        return;
    m_online = on;
    emit onlineChanged();
}

void DaemonClient::get(const QString &path) {
    auto *reply = m_nam->get(QNetworkRequest{QUrl(QStringLiteral("http://127.0.0.1:%1%2").arg(m_port).arg(path))});
    connect(reply, &QNetworkReply::finished, this, [this, path, reply] { handleReply(path, reply); });
}

void DaemonClient::post(const QString &path, const QVariantMap &body) {
    QNetworkRequest req{QUrl(QStringLiteral("http://127.0.0.1:%1%2").arg(m_port).arg(path))};
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    auto *reply = m_nam->post(req, QJsonDocument(QJsonObject::fromVariantMap(body)).toJson(QJsonDocument::Compact));
    connect(reply, &QNetworkReply::finished, this, [this, path, reply] { handleReply(path, reply); });
}

void DaemonClient::handleReply(const QString &path, QNetworkReply *reply) {
    const auto bytes = reply->readAll();
    const bool ok = reply->error() == QNetworkReply::NoError;
    QVariantMap value;
    const auto doc = QJsonDocument::fromJson(bytes);
    if (doc.isObject())
        value = doc.object().toVariantMap();
    else if (doc.isArray())
        value.insert(QStringLiteral("value"), doc.array().toVariantList());
    else if (ok)
        value.insert(QStringLiteral("text"), QString::fromUtf8(bytes));
    reply->deleteLater();
    if (ok)
        setOnline(true);
    emit DaemonClient::reply(path, ok, value);
}
