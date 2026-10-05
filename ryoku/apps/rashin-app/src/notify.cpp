#include "notify.hpp"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QVariantList>

// notify.cpp: one org.freedesktop.Notifications.Notify call, built by hand so
// the app needs no code generation. The replaces-id stays 0 (each event is its
// own notification) and the timeout is the server default.

void Notify::say(const QString &title, const QString &body) {
    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.freedesktop.Notifications"),
        QStringLiteral("/org/freedesktop/Notifications"),
        QStringLiteral("org.freedesktop.Notifications"),
        QStringLiteral("Notify"));
    msg.setArguments({
        QStringLiteral("Rashin"),               // app_name
        uint(0),                                // replaces_id
        QStringLiteral("ryoku-rashin"),         // app_icon
        title,
        body,
        QVariantList(),                         // actions
        QVariantMap(),                          // hints
        int(6000)                               // expire_timeout ms
    });
    QDBusConnection::sessionBus().call(msg, QDBus::NoBlock);
}
