#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlintegration.h>

// QuickAsk is the app's window onto the daemon's fast lane: one question, one
// streamed answer, the same marker protocol the launcher's Ask bar rides
// (`ryoku-rashin ask <question>` prints @working/@perm/@answer/@error lines).
// It is a separate object per call site and one turn at a time; the daemon
// stays the authority on the answer, and cancelling asks the daemon to stop
// the in-flight turn, not just the local pipe.
class QuickAsk : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString working READ working NOTIFY workingChanged)
    Q_PROPERTY(QString question READ question NOTIFY questionChanged)
    Q_PROPERTY(QString answerText READ answerText NOTIFY answered)
    Q_PROPERTY(QString errorText READ errorText NOTIFY answered)
    Q_PROPERTY(QVariantList actions READ actions NOTIFY answered)
    Q_PROPERTY(QVariantList images READ images NOTIFY answered)
    Q_PROPERTY(bool done READ done NOTIFY answered)
    Q_PROPERTY(bool permPending READ permPending NOTIFY workingChanged)

public:
    explicit QuickAsk(QObject *parent = nullptr);

    bool busy() const { return m_phase == Phase::Working; }
    QString working() const { return m_working; }
    QString question() const { return m_question; }
    QString answerText() const { return m_answer; }
    QString errorText() const { return m_error; }
    QVariantList actions() const { return m_actions; }
    QVariantList images() const { return m_images; }
    int phase() const { return static_cast<int>(m_phase); }
    bool done() const { return m_phase == Phase::Done; }
    bool permPending() const { return m_permPending; }

    Q_INVOKABLE void ask(const QString &question);
    Q_INVOKABLE void cancel();
    // The recent-asks list, newest first (ask --recent), as [{q, a, at}].
    Q_INVOKABLE void loadRecent();
    // Recall a stored answer instantly, no model call (the \resume path).
    Q_INVOKABLE void recall(const QVariantMap &entry);

signals:
    void busyChanged();
    void workingChanged();
    void questionChanged();
    void answered();
    void recentReady(const QVariantList &recent);

private:
    enum class Phase { Idle, Working, Done, Failed };
    void setPhase(Phase p);
    void handleLine(const QByteArray &line);

    QProcess m_proc;
    QByteArray m_lineBuf;
    Phase m_phase = Phase::Idle;
    QString m_question;
    QString m_working;
    QString m_answer;
    QString m_error;
    QVariantList m_actions;
    QVariantList m_images;
    bool m_permPending = false;
};
