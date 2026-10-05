#pragma once

#include <QClipboard>
#include <QGuiApplication>
#include <QQmlEngine>
#include <qqmlintegration.h>

// Clipboard is the app's one way to put text on the system clipboard. The
// shell's surfaces shell out to wl-copy; a plain Qt app has the real thing,
// and using it keeps copy actions instant and dependency-free.
class Clipboard : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit Clipboard(QObject *parent = nullptr) : QObject(parent) {}
    static Clipboard *create(QQmlEngine *, QJSEngine *) { return new Clipboard; }

    Q_INVOKABLE void copy(const QString &text) {
        QGuiApplication::clipboard()->setText(text);
    }
};
