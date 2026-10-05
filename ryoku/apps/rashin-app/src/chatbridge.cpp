#include "chatbridge.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>

// chatbridge.cpp ports the shell's Needle singleton and the pure v3 reducer
// (shell/services/lib/chatstate.js) to C++. The wire is identical: every
// transcript decision belongs to the daemon, and this file only folds frames
// into rows. Keeping the reducer here rather than in QML is what lets the
// timeline virtualise cleanly and survive a thousand-frame replay.

namespace {

QVariantList jsonArray(const QJsonValue &v) {
    QVariantList out;
    if (!v.isArray())
        return out;
    const auto arr = v.toArray();
    for (const auto &item : arr)
        out.append(item.toVariant());
    return out;
}

QString stringField(const QJsonObject &o, const char *key) {
    return o.value(QLatin1String(key)).toString();
}

} // namespace

ChatBridge *ChatBridge::instance() {
    static ChatBridge *self = new ChatBridge;
    return self;
}

ChatBridge::ChatBridge(QObject *parent) : QObject(parent) {
    m_follow.setProgram(QStringLiteral("ryoku-rashin"));
    m_follow.setArguments({QStringLiteral("chat"), QStringLiteral("--follow")});
    m_follow.setProcessChannelMode(QProcess::ForwardedErrorChannel);
    connect(&m_follow, &QProcess::readyReadStandardOutput, this, &ChatBridge::onReadyLine);
    connect(&m_follow, &QProcess::started, this, &ChatBridge::onFollowStarted);
    connect(&m_follow, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            &ChatBridge::onFollowExited);

    m_restartTimer = new QTimer(this);
    m_restartTimer->setSingleShot(true);
    m_restartTimer->setInterval(400);
    connect(m_restartTimer, &QTimer::timeout, this, [this] {
        if (m_follow.state() == QProcess::NotRunning)
            m_follow.start();
    });

    m_backendsTimer = new QTimer(this);
    m_backendsTimer->setSingleShot(true);
    m_backendsTimer->setInterval(300);
    connect(m_backendsTimer, &QTimer::timeout, this, &ChatBridge::refreshMeta);

    m_follow.start();
    refreshMeta();
}

// ---- model ----------------------------------------------------------------

int ChatBridge::ChatModel::rowCount(const QModelIndex &) const {
    return m_bridge->m_rows.size();
}

QVariant ChatBridge::ChatModel::data(const QModelIndex &index, int role) const {
    const int i = index.row();
    if (i < 0 || i >= m_bridge->m_rows.size())
        return {};
    const Row &r = m_bridge->m_rows.at(i);
    switch (role) {
    case KindRole: return r.kind;
    case IdRole: return r.id;
    case RoleRole: return r.role;
    case TextRole: return r.text;
    case ThoughtRole: return r.thought;
    case OpenRole: return r.open;
    case ContRole: return r.cont;
    case FailedRole: return r.failed;
    case ImagesRole: return r.images;
    case TitleRole: return r.title;
    case ToolKindRole: return r.toolKind;
    case StatusRole: return r.status;
    case InputRole: return r.input;
    case OutputRole: return r.output;
    case DiffsRole: return r.diffs;
    case AutoRole: return r.autoApproved;
    case PermRole: return r.perm;
    case LiveRole: return r.open && i == m_bridge->m_rows.size() - 1;
    }
    return {};
}

QHash<int, QByteArray> ChatBridge::ChatModel::roleNames() const {
    return {
        {KindRole, "kind"},         {IdRole, "rowId"},          {RoleRole, "role"},
        {TextRole, "body"},         {ThoughtRole, "thought"},   {OpenRole, "open"},
        {ContRole, "cont"},         {FailedRole, "failed"},     {ImagesRole, "images"},
        {TitleRole, "title"},       {ToolKindRole, "toolKind"}, {StatusRole, "status"},
        {InputRole, "toolInput"},   {OutputRole, "toolOutput"}, {DiffsRole, "diffs"},
        {AutoRole, "autoApproved"}, {PermRole, "perm"},         {LiveRole, "live"},
    };
}

void ChatBridge::touchRow(int i) {
    const auto idx = m_model.index(i);
    emit m_model.dataChanged(idx, idx);
}

// ---- outbound ---------------------------------------------------------------

void ChatBridge::writeFrame(const QJsonObject &frame) {
    const auto line = QString::fromUtf8(QJsonDocument(frame).toJson(QJsonDocument::Compact));
    if (m_started && m_follow.state() == QProcess::Running)
        m_follow.write(line.toUtf8() + '\n');
    else
        m_outbox.append(line);
}

void ChatBridge::send(const QString &text, const QVariantList &imagePaths) {
    const auto trimmed = text.trimmed();
    if ((trimmed.isEmpty() && imagePaths.isEmpty()) || m_busy)
        return;
    if (imagePaths.isEmpty()) {
        writeFrame({{QStringLiteral("type"), QStringLiteral("user")},
                    {QStringLiteral("text"), trimmed}});
        return;
    }
    // QML cannot base64 a file, so the daemon encodes the attachments and we
    // fold the result into the user message it hands back.
    encodeAndSend(trimmed, imagePaths);
}

void ChatBridge::encodeAndSend(const QString &text, const QVariantList &imagePaths) {
    auto *proc = new QProcess(this);
    QStringList args{QStringLiteral("chat")};
    for (const auto &p : imagePaths) {
        args << QStringLiteral("--encode-image") << p.toString();
    }
    proc->setProgram(QStringLiteral("ryoku-rashin"));
    proc->setArguments(args);
    connect(proc, &QProcess::readyReadStandardOutput, this, [this, proc, text] {
        const auto lines = QString::fromUtf8(proc->readAllStandardOutput()).split('\n', Qt::SkipEmptyParts);
        for (const auto &line : lines) {
            const auto doc = QJsonDocument::fromJson(line.toUtf8());
            if (!doc.isObject())
                continue;
            const auto obj = doc.object();
            if (obj.value(QStringLiteral("type")).toString() == QLatin1String("images")) {
                writeFrame({{QStringLiteral("type"), QStringLiteral("user")},
                            {QStringLiteral("text"), text},
                            {QStringLiteral("images"), obj.value(QStringLiteral("images"))}});
            }
        }
    });
    connect(proc, &QProcess::finished, proc, &QObject::deleteLater);
    proc->start();
}

void ChatBridge::cancel() {
    writeFrame({{QStringLiteral("type"), QStringLiteral("cancel")}});
}

void ChatBridge::newChat() {
    writeFrame({{QStringLiteral("type"), QStringLiteral("new")}});
}

void ChatBridge::loadSessions() {
    writeFrame({{QStringLiteral("type"), QStringLiteral("history")}});
}

void ChatBridge::switchSession(const QString &id) {
    if (id.isEmpty())
        return;
    writeFrame({{QStringLiteral("type"), QStringLiteral("load")},
                {QStringLiteral("sessionId"), id}});
}

void ChatBridge::setModel(const QString &id) {
    if (id.isEmpty() || id == m_currentModel)
        return;
    m_currentModel = id;
    writeFrame({{QStringLiteral("type"), QStringLiteral("set_model")},
                {QStringLiteral("modelId"), id}});
    emit touched();
}

void ChatBridge::setApprovals(const QString &mode) {
    if (mode != QLatin1String("read-only") && mode != QLatin1String("ask"))
        return;
    writeFrame({{QStringLiteral("type"), QStringLiteral("approvals")},
                {QStringLiteral("mode"), mode}});
}

void ChatBridge::answerPermission(const QString &requestId, const QString &optionId) {
    if (requestId.isEmpty())
        return;
    writeFrame({{QStringLiteral("type"), QStringLiteral("permission")},
                {QStringLiteral("requestId"), requestId},
                {QStringLiteral("optionId"), optionId}});
}

void ChatBridge::setBackend(const QString &id) {
    if (id.isEmpty())
        return;
    for (const auto &b : m_backends) {
        const auto map = b.toMap();
        if (map.value(QStringLiteral("id")).toString() == id) {
            m_currentAgent = map.value(QStringLiteral("name"), id).toString();
            break;
        }
    }
    m_currentModel.clear();
    m_models.clear();
    auto *proc = new QProcess(this);
    proc->setProgram(QStringLiteral("ryoku-rashin"));
    proc->setArguments({QStringLiteral("agent"), QStringLiteral("use"), id});
    connect(proc, &QProcess::finished, proc, &QObject::deleteLater);
    proc->start();
    m_backendsTimer->start();
    emit touched();
}

void ChatBridge::refreshMeta() {
    auto *status = new QProcess(this);
    status->setProgram(QStringLiteral("ryoku-rashin"));
    status->setArguments({QStringLiteral("status"), QStringLiteral("--json")});
    connect(status, &QProcess::readyReadStandardOutput, this, [this, status] {
        const auto doc = QJsonDocument::fromJson(status->readAllStandardOutput());
        if (doc.isObject()) {
            const auto obj = doc.object();
            if (obj.contains(QStringLiteral("ready"))) {
                const bool wasReady = m_ready;
                m_ready = obj.value(QStringLiteral("ready")).toBool();
                if (wasReady != m_ready)
                    emit readyChanged();
            }
        }
    });
    connect(status, &QProcess::finished, status, &QObject::deleteLater);
    status->start();

    auto *agents = new QProcess(this);
    agents->setProgram(QStringLiteral("ryoku-rashin"));
    agents->setArguments({QStringLiteral("agent"), QStringLiteral("--json")});
    connect(agents, &QProcess::readyReadStandardOutput, this, [this, agents] {
        const auto doc = QJsonDocument::fromJson(agents->readAllStandardOutput());
        if (doc.isArray()) {
            m_backends = doc.array().toVariantList();
            emit backendsChanged();
        }
    });
    connect(agents, &QProcess::finished, agents, &QObject::deleteLater);
    agents->start();
}

// ---- inbound --------------------------------------------------------------

void ChatBridge::onFollowStarted() {
    m_started = true;
    m_connected = true;
    for (const auto &line : std::as_const(m_outbox))
        m_follow.write(line.toUtf8() + '\n');
    m_outbox.clear();
    emit touched();
}

void ChatBridge::onFollowExited() {
    m_started = false;
    m_connected = false;
    m_bannerState = QStringLiteral("dead");
    m_bannerError = QStringLiteral("connection lost");
    emit touched();
    m_restartTimer->start();
}

void ChatBridge::onReadyLine() {
    m_lineBuf += m_follow.readAllStandardOutput();
    int nl;
    while ((nl = m_lineBuf.indexOf('\n')) >= 0) {
        const QByteArray line = m_lineBuf.left(nl).trimmed();
        m_lineBuf.remove(0, nl + 1);
        if (line.isEmpty())
            continue;
        const auto doc = QJsonDocument::fromJson(line);
        if (!doc.isObject())
            continue;
        applyFrame(doc.object());
    }
}

int ChatBridge::rowById(const QString &id) const {
    for (int i = 0; i < m_rows.size(); ++i)
        if (m_rows.at(i).kind == QLatin1String("tool") && m_rows.at(i).id == id)
            return i;
    return -1;
}

// The v3 stream only ever appends a row, mutates the open agent message, or
// mutates a tool by id, so the model stays stable while a chunk streams in.
void ChatBridge::applyFrame(const QJsonObject &f) {
    const auto type = stringField(f, "type");
    if (type.isEmpty())
        return;

    // Activity label, derived the same way the shell's reducer derives it.
    if (!m_replaying) {
        if (type == QLatin1String("tool")) {
            const auto status = stringField(f, "status");
            if (status == QLatin1String("pending") || status == QLatin1String("in_progress")) {
                const auto title = stringField(f, "title");
                m_activity = title.isEmpty() ? QStringLiteral("running a tool") : title;
            }
        } else if (type == QLatin1String("agent_thought")) {
            m_activity = QStringLiteral("thinking");
        } else if (type == QLatin1String("agent_text")) {
            m_activity = QStringLiteral("writing");
        } else if (type == QLatin1String("permission")) {
            m_activity = QStringLiteral("waiting for your approval");
        }
    }

    if (type == QLatin1String("user") || type == QLatin1String("user_text")) {
        Row r;
        r.kind = QStringLiteral("msg");
        r.role = QStringLiteral("user");
        r.id = QStringLiteral("u%1").arg(++m_seq);
        r.text = stringField(f, "text");
        r.images = jsonArray(f.value(QStringLiteral("images")));
        m_model.beginInsertRows({}, m_rows.size(), m_rows.size());
        m_rows.append(r);
        m_model.endInsertRows();
    } else if (type == QLatin1String("agent_text") || type == QLatin1String("agent_thought")) {
        const bool thought = type == QLatin1String("agent_thought");
        // Join the open tail when allowed: thinking only joins a segment that
        // has no answer text yet, so a thought after the answer opens fresh.
        const bool joins = !m_rows.isEmpty() && m_rows.last().kind == QLatin1String("msg")
            && m_rows.last().role == QLatin1String("agent") && m_rows.last().open
            && (!thought || m_rows.last().text.isEmpty());
        if (joins) {
            Row &tail = m_rows.last();
            if (thought)
                tail.thought += stringField(f, "text");
            else
                tail.text += stringField(f, "text");
            touchRow(m_rows.size() - 1);
        } else {
            Row r;
            r.kind = QStringLiteral("msg");
            r.role = QStringLiteral("agent");
            r.id = QStringLiteral("a%1").arg(++m_seq);
            r.open = true;
            if (!m_rows.isEmpty()) {
                const Row &prev = m_rows.last();
                r.cont = prev.kind == QLatin1String("tool")
                    || (prev.kind == QLatin1String("msg") && prev.role == QLatin1String("agent"));
            }
            if (thought)
                r.thought = stringField(f, "text");
            else
                r.text = stringField(f, "text");
            m_model.beginInsertRows({}, m_rows.size(), m_rows.size());
            m_rows.append(r);
            m_model.endInsertRows();
        }
    } else if (type == QLatin1String("tool")) {
        const auto id = stringField(f, "id");
        const int at = rowById(id);
        if (at < 0) {
            Row r;
            r.kind = QStringLiteral("tool");
            r.id = id;
            r.title = stringField(f, "title");
            r.toolKind = stringField(f, "kind");
            r.status = stringField(f, "status").isEmpty() ? QStringLiteral("pending") : stringField(f, "status");
            r.input = stringField(f, "input");
            r.output = stringField(f, "output");
            r.diffs = jsonArray(f.value(QStringLiteral("diffs")));
            r.autoApproved = f.value(QStringLiteral("auto")).toBool();
            m_model.beginInsertRows({}, m_rows.size(), m_rows.size());
            m_rows.append(r);
            m_model.endInsertRows();
        } else {
            // A partial update: an absent field keeps its previous value.
            Row &row = m_rows[at];
            const auto setStr = [&](const char *key, QString &field) {
                if (f.contains(QLatin1String(key)))
                    field = stringField(f, key);
            };
            setStr("title", row.title);
            setStr("kind", row.toolKind);
            setStr("status", row.status);
            setStr("input", row.input);
            setStr("output", row.output);
            if (f.contains(QStringLiteral("diffs")))
                row.diffs = jsonArray(f.value(QStringLiteral("diffs")));
            if (f.contains(QStringLiteral("auto")))
                row.autoApproved = f.value(QStringLiteral("auto")).toBool();
            // A tool that just resolved may carry the approval answered on it.
            touchRow(at);
        }
    } else if (type == QLatin1String("permission")) {
        QVariantMap perm;
        perm.insert(QStringLiteral("requestId"), stringField(f, "requestId"));
        perm.insert(QStringLiteral("toolId"), stringField(f, "toolId"));
        perm.insert(QStringLiteral("title"), stringField(f, "title"));
        perm.insert(QStringLiteral("kind"), stringField(f, "kind"));
        perm.insert(QStringLiteral("input"), stringField(f, "input"));
        perm.insert(QStringLiteral("options"), jsonArray(f.value(QStringLiteral("options"))));
        const auto rid = perm.value(QStringLiteral("requestId")).toString();
        bool replaced = false;
        for (auto &p : m_perms) {
            if (p.value(QStringLiteral("requestId")).toString() == rid) {
                p = perm;
                replaced = true;
                break;
            }
        }
        if (!replaced)
            m_perms.append(perm);
        // Attach to its tool row when one exists; the view falls back to a
        // trailing card otherwise.
        const int at = rowById(perm.value(QStringLiteral("toolId")).toString());
        if (at >= 0) {
            m_rows[at].perm = perm;
            touchRow(at);
        }
    } else if (type == QLatin1String("permission_resolved")) {
        const auto rid = stringField(f, "requestId");
        m_perms.erase(std::remove_if(m_perms.begin(), m_perms.end(),
                                     [&](const QVariantMap &p) {
                                         return p.value(QStringLiteral("requestId")).toString() == rid;
                                     }),
                      m_perms.end());
        for (int i = 0; i < m_rows.size(); ++i) {
            if (m_rows[i].perm.value(QStringLiteral("requestId")).toString() == rid) {
                m_rows[i].perm = {};
                touchRow(i);
            }
        }
    } else if (type == QLatin1String("approvals")) {
        m_approvalsMode = stringField(f, "mode") == QLatin1String("ask") ? QStringLiteral("ask") : QStringLiteral("read-only");
    } else if (type == QLatin1String("turn_end")) {
        for (int i = 0; i < m_rows.size(); ++i) {
            if (m_rows[i].open) {
                m_rows[i].open = false;
                touchRow(i);
            }
        }
        if (!m_replaying) {
            m_busy = false;
            m_activity.clear();
        }
    } else if (type == QLatin1String("state")) {
        m_bannerState = stringField(f, "state");
        m_bannerError = stringField(f, "error");
        m_busy = m_bannerState == QLatin1String("busy") || m_bannerState == QLatin1String("starting");
        m_connected = m_bannerState != QLatin1String("dead");
        if (!m_busy)
            m_activity.clear();
    } else if (type == QLatin1String("models")) {
        m_models = jsonArray(f.value(QStringLiteral("models")));
        m_currentModel = stringField(f, "current");
        const auto agent = stringField(f, "agent");
        if (!agent.isEmpty())
            m_currentAgent = agent;
    } else if (type == QLatin1String("commands")) {
        m_commands = jsonArray(f.value(QStringLiteral("commands")));
    } else if (type == QLatin1String("session_info")) {
        m_sessionId = stringField(f, "sessionId");
        m_sessionTitle = stringField(f, "title");
    } else if (type == QLatin1String("usage")) {
        m_usage = {{QStringLiteral("size"), f.value(QStringLiteral("size")).toInt()},
                   {QStringLiteral("used"), f.value(QStringLiteral("used")).toInt()}};
    } else if (type == QLatin1String("history")) {
        m_sessions = jsonArray(f.value(QStringLiteral("sessions")));
    } else if (type == QLatin1String("replay_start")) {
        m_model.beginResetModel();
        m_rows.clear();
        m_perms.clear();
        m_standalonePerms.clear();
        m_replaying = true;
        m_model.endResetModel();
    } else if (type == QLatin1String("replay_end")) {
        m_replaying = false;
    } else {
        return; // unknown frame kinds are forward-compatible noise
    }
    rebuildStandalonePerms();
    emit touched();
}

void ChatBridge::rebuildStandalonePerms() {
    QSet<QString> toolIds;
    for (const auto &row : m_rows)
        if (row.kind == QLatin1String("tool"))
            toolIds.insert(row.id);
    QVariantList out;
    for (const auto &p : m_perms) {
        const auto toolId = p.value(QStringLiteral("toolId")).toString();
        if (toolId.isEmpty() || !toolIds.contains(toolId))
            out.append(p);
    }
    m_standalonePerms = out;
}
