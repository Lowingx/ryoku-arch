#pragma once

#include <QAbstractListModel>
#include <QJsonObject>
#include <QProcess>
#include <QSet>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>
#include <qqmlintegration.h>
class QQmlEngine;
class QJSEngine;

// ChatBridge is the app's window onto the one shared agent session the rashin
// daemon owns. It speaks the daemon's protocol through the resident
// `ryoku-rashin chat --follow` bridge (newline JSON both ways, the same wire
// the shell's Ask bar rides), so the daemon stays the only authority: a run,
// a tool, an approval, or a model switch exists when the daemon says so, and
// this class only projects the frames it is handed. The bridge reconnects on
// its own; a dead socket arrives as a state frame and the view degrades to
// offline honestly.
class ChatBridge : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(ChatModel *model READ model CONSTANT)
    Q_PROPERTY(bool busy READ busy NOTIFY touched)
    Q_PROPERTY(QString activity READ activity NOTIFY touched)
    Q_PROPERTY(QString approvalsMode READ approvalsMode NOTIFY touched)
    Q_PROPERTY(QString bannerState READ bannerState NOTIFY touched)
    Q_PROPERTY(QString bannerError READ bannerError NOTIFY touched)
    Q_PROPERTY(QVariantList models READ models NOTIFY touched)
    Q_PROPERTY(QString currentModel READ currentModel NOTIFY touched)
    Q_PROPERTY(QString currentAgent READ currentAgent NOTIFY touched)
    Q_PROPERTY(QVariantList commands READ commands NOTIFY touched)
    Q_PROPERTY(QVariantList sessions READ sessions NOTIFY touched)
    Q_PROPERTY(QString currentSession READ currentSession NOTIFY touched)
    Q_PROPERTY(QString sessionTitle READ sessionTitle NOTIFY touched)
    Q_PROPERTY(QVariantMap usage READ usage NOTIFY touched)
    Q_PROPERTY(QVariantList standalonePerms READ standalonePerms NOTIFY touched)
    Q_PROPERTY(QVariantList backends READ backends NOTIFY backendsChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY touched)

public:
    explicit ChatBridge(QObject *parent = nullptr);
    static ChatBridge *create(QQmlEngine * /*engine*/, QJSEngine * /*js*/) { return instance(); }
    static ChatBridge *instance();

    // One transcript row. The model is a flat stream: agent/user messages and
    // tool calls interleave in arrival order, exactly as the daemon frames
    // them, so a reply reads in the order the agent worked.
    struct Row {
        QString kind;          // "msg" | "tool"
        QString id;
        // message rows
        QString role;          // "user" | "agent"
        QString text;
        QString thought;
        bool open = false;     // still being written
        bool cont = false;     // continues the same reply below a tool
        bool failed = false;
        QVariantList images;
        // tool rows
        QString title;
        QString toolKind;
        QString status;
        QString input;
        QString output;
        QVariantList diffs;
        bool autoApproved = false;
        QVariantMap perm;      // the approval waiting on this tool, if any
    };

    class ChatModel : public QAbstractListModel {
        friend class ChatBridge; // the bridge owns the rows; the model projects them
    public:
        enum Roles {
            KindRole = Qt::UserRole + 1,
            IdRole,
            RoleRole,
            TextRole,
            ThoughtRole,
            OpenRole,
            ContRole,
            FailedRole,
            ImagesRole,
            TitleRole,
            ToolKindRole,
            StatusRole,
            InputRole,
            OutputRole,
            DiffsRole,
            AutoRole,
            PermRole,
            LiveRole
        };
        explicit ChatModel(ChatBridge *bridge) : m_bridge(bridge) {}
        int rowCount(const QModelIndex &parent = {}) const override;
        QVariant data(const QModelIndex &index, int role) const override;
        QHash<int, QByteArray> roleNames() const override;

    private:
        ChatBridge *m_bridge;
    };

    ChatModel *model() { return &m_model; }

    bool busy() const { return m_busy; }
    QString activity() const { return m_activity; }
    QString approvalsMode() const { return m_approvalsMode; }
    QString bannerState() const { return m_bannerState; }
    QString bannerError() const { return m_bannerError; }
    QVariantList models() const { return m_models; }
    QString currentModel() const { return m_currentModel; }
    QString currentAgent() const { return m_currentAgent; }
    QVariantList commands() const { return m_commands; }
    QVariantList sessions() const { return m_sessions; }
    QString currentSession() const { return m_sessionId; }
    QString sessionTitle() const { return m_sessionTitle; }
    QVariantMap usage() const { return m_usage; }
    QVariantList standalonePerms() const { return m_standalonePerms; }
    QVariantList backends() const { return m_backends; }
    bool ready() const { return m_ready; }
    bool connected() const { return m_connected; }

    // ---- outbound (each is one stdin frame on the follow bridge) ----
    Q_INVOKABLE void send(const QString &text, const QVariantList &imagePaths = {});
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void newChat();
    Q_INVOKABLE void loadSessions();
    Q_INVOKABLE void switchSession(const QString &id);
    Q_INVOKABLE void setModel(const QString &id);
    Q_INVOKABLE void setApprovals(const QString &mode);
    Q_INVOKABLE void answerPermission(const QString &requestId, const QString &optionId);
    // Switch the answering agent: the daemon drops its session and the follow
    // stream delivers fresh state and models frames.
    Q_INVOKABLE void setBackend(const QString &id);
    // One-shot daemon reads that ride the CLI (status --json, agent --json).
    Q_INVOKABLE void refreshMeta();

signals:
    void touched();
    void backendsChanged();
    void readyChanged();

private slots:
    void onReadyLine();
    void onFollowStarted();
    void onFollowExited();

private:
    void applyFrame(const QJsonObject &frame);
    void writeFrame(const QJsonObject &frame);
    void encodeAndSend(const QString &text, const QVariantList &imagePaths);
    void rebuildStandalonePerms();
    int rowById(const QString &id) const;
    void touchRow(int i);

    ChatModel m_model{this};
    QVector<Row> m_rows;
    QProcess m_follow;
    QByteArray m_lineBuf;
    QStringList m_outbox;
    bool m_started = false;
    bool m_connected = false;

    bool m_busy = false;
    QString m_activity;
    QString m_approvalsMode = QStringLiteral("read-only");
    QString m_bannerState = QStringLiteral("starting");
    QString m_bannerError;
    QVariantList m_models;
    QString m_currentModel;
    QString m_currentAgent;
    QVariantList m_commands;
    QVariantList m_sessions;
    QString m_sessionId;
    QString m_sessionTitle;
    QVariantMap m_usage;
    QVector<QVariantMap> m_perms;
    QVariantList m_standalonePerms;
    QVariantList m_backends;
    bool m_ready = true;
    bool m_replaying = false;
    quint64 m_seq = 0;
    QTimer *m_restartTimer = nullptr;
    QTimer *m_backendsTimer = nullptr;
};
