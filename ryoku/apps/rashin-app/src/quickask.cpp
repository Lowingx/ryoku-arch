#include "quickask.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

// quickask.cpp: one turn of the launcher's fast lane, in-process. The wire is
// the CLI's marker protocol; the daemon owns the answer.

QuickAsk::QuickAsk(QObject *parent) : QObject(parent) {
    m_proc.setProgram(QStringLiteral("ryoku-rashin"));
    m_proc.setProcessChannelMode(QProcess::ForwardedErrorChannel);
    connect(&m_proc, &QProcess::readyReadStandardOutput, this, [this] {
        m_lineBuf += m_proc.readAllStandardOutput();
        int nl;
        while ((nl = m_lineBuf.indexOf('\n')) >= 0) {
            const auto line = m_lineBuf.left(nl);
            m_lineBuf.remove(0, nl + 1);
            if (!line.trimmed().isEmpty())
                handleLine(line);
        }
    });
    connect(&m_proc, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this, [this](int code) {
        if (m_phase == Phase::Working && !m_permPending) {
            m_error = code == 0 ? QStringLiteral("No answer") : QStringLiteral("Ask failed");
            setPhase(Phase::Failed);
            emit answered();
        }
    });
}

void QuickAsk::setPhase(Phase p) {
    if (m_phase == p)
        return;
    m_phase = p;
    emit busyChanged();
}

void QuickAsk::handleLine(const QByteArray &line) {
    const auto text = QString::fromUtf8(line);
    if (text.startsWith(QLatin1String("@working "))) {
        m_working = text.mid(9).trimmed();
        emit workingChanged();
    } else if (text.startsWith(QLatin1String("@perm "))) {
        m_permPending = true;
        m_working = QStringLiteral("Waiting for approval: ") + text.mid(6);
        emit workingChanged();
    } else if (text.startsWith(QLatin1String("@answer "))) {
        const auto doc = QJsonDocument::fromJson(text.mid(8).toUtf8());
        if (doc.isObject()) {
            const auto o = doc.object();
            m_answer = o.value(QStringLiteral("text")).toString();
            m_images = o.value(QStringLiteral("images")).toArray().toVariantList();
            m_actions = o.value(QStringLiteral("actions")).toArray().toVariantList();
            m_permPending = false;
            setPhase(Phase::Done);
            emit answered();
            return;
        }
        m_error = QStringLiteral("Unreadable answer");
        setPhase(Phase::Failed);
        emit answered();
    } else if (text.startsWith(QLatin1String("@error "))) {
        m_error = text.mid(7);
        m_permPending = false;
        setPhase(Phase::Failed);
        emit answered();
    }
}

void QuickAsk::ask(const QString &question) {
    const auto trimmed = question.trimmed();
    if (trimmed.isEmpty() || m_phase == Phase::Working)
        return;
    if (m_proc.state() != QProcess::NotRunning)
        m_proc.kill();
    m_question = trimmed;
    emit questionChanged();
    m_answer.clear();
    m_error.clear();
    m_actions.clear();
    m_images.clear();
    m_permPending = false;
    m_working = QStringLiteral("waking the needle");
    m_lineBuf.clear();
    setPhase(Phase::Working);
    emit workingChanged();
    m_proc.setArguments({QStringLiteral("ask"), trimmed});
    m_proc.start();
}

void QuickAsk::cancel() {
    if (m_phase != Phase::Working)
        return;
    setPhase(Phase::Idle);
    m_working.clear();
    m_permPending = false;
    if (m_proc.state() != QProcess::NotRunning)
        m_proc.terminate();
    QProcess::startDetached(QStringLiteral("ryoku-rashin"), {QStringLiteral("ask"), QStringLiteral("--cancel")});
}

void QuickAsk::loadRecent() {
    auto *proc = new QProcess(this);
    proc->setProgram(QStringLiteral("ryoku-rashin"));
    proc->setArguments({QStringLiteral("ask"), QStringLiteral("--recent")});
    connect(proc, &QProcess::readyReadStandardOutput, this, [this, proc] {
        const auto doc = QJsonDocument::fromJson(proc->readAllStandardOutput());
        if (doc.isArray())
            emit recentReady(doc.array().toVariantList());
    });
    connect(proc, &QProcess::finished, proc, &QObject::deleteLater);
    proc->start();
}

void QuickAsk::recall(const QVariantMap &entry) {
    if (entry.isEmpty())
        return;
    m_question = entry.value(QStringLiteral("q")).toString();
    m_answer = entry.value(QStringLiteral("a")).toString();
    m_images = entry.value(QStringLiteral("images")).toList();
    m_actions = entry.value(QStringLiteral("actions")).toList();
    m_error.clear();
    m_permPending = false;
    m_working.clear();
    emit questionChanged();
    setPhase(Phase::Done);
    emit workingChanged();
    emit answered();
}