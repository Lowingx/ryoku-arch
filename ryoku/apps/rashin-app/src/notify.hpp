#pragma once

#include <QObject>
#include <QQmlEngine>
#include <qqmlintegration.h>
// Notify posts freedesktop desktop notifications over DBus, so a turn that
// finishes while the window is hidden still reaches the user. It is a
// fire-and-forget singleton: no replies are tracked, and a session without a
// notification daemon degrades to nothing (the app stays correct, the
// message just does not appear).
class Notify : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit Notify(QObject *parent = nullptr) : QObject(parent) {}
    static Notify *create(QQmlEngine *, QJSEngine *) { return new Notify; }

    Q_INVOKABLE void say(const QString &title, const QString &body);
};
