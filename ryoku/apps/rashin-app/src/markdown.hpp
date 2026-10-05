#pragma once

#include <QObject>
#include <QString>
#include <qqmlintegration.h>

// Markdown converts the agent's answer text into the HTML subset Qt's Text
// rendering handles, so the chat reads as prose instead of raw syntax. It is
// deliberately small: headings, bold, italic, inline code, fenced code blocks,
// links, lists, and blockquotes. Everything is escaped first, so agent output
// can never inject markup; links render in the primary colour and the app
// opens them through the desktop's default handler.
class Markdown : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
public:
    explicit Markdown(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE QString toHtml(const QString &text) const;
    // Plain text with the syntax stripped, for copy buttons.
    Q_INVOKABLE QString plain(const QString &text) const;
};
