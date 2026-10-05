#pragma once

#include <QObject>
#include <QProcess>
#include <QQmlEngine>
#include <QStringList>
#include <qqmlintegration.h>

// Runner fires the desktop's own commands: `ryoku-rashin enable`, a fix
// harness, the terminal. Detached and fire-and-forget on purpose -- the
// daemon and the harnesses own their lifetimes, and the app never babysits a
// process it launched.
class Runner : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit Runner(QObject *parent = nullptr) : QObject(parent) {}
    static Runner *create(QQmlEngine *, QJSEngine *) { return new Runner; }

    Q_INVOKABLE void run(const QString &program, const QStringList &args = {}) {
        QProcess::startDetached(program, args);
    }
};
