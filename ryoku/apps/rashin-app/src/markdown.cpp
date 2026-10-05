#include "markdown.hpp"

#include <QRegularExpression>
#include <QStringList>
#include <QUrl>

// markdown.cpp: a small, safe CommonMark subset -> Qt rich text. Escape
// first, then transform; the agent's text can never inject markup because
// every character that matters for HTML arrives already entity-encoded.

namespace {

QString escapeHtml(const QString &raw) {
    QString out = raw;
    out.replace(QLatin1Char('&'), QLatin1String("&amp;"));
    out.replace(QLatin1Char('<'), QLatin1String("&lt;"));
    out.replace(QLatin1Char('>'), QLatin1String("&gt;"));
    return out;
}

// Inline spans: `code`, **bold**, *italic*, [text](url).
QString inlineMd(const QString &line) {
    QString out = escapeHtml(line);

    static const QRegularExpression codeRe(QStringLiteral("`([^`]+)`"));
    out.replace(codeRe, QStringLiteral("<code>\\1</code>"));

    static const QRegularExpression boldRe(QStringLiteral("\\*\\*([^*]+)\\*\\*"));
    out.replace(boldRe, QStringLiteral("<b>\\1</b>"));

    static const QRegularExpression italicRe(QStringLiteral("(?<![\\w*])\\*([^*\\n]+)\\*(?![\\w*])"));
    out.replace(italicRe, QStringLiteral("<i>\\1</i>"));

    static const QRegularExpression linkRe(QStringLiteral("\\[([^\\]]+)\\]\\(([^)\\s]+)\\)"));
    out.replace(linkRe, QStringLiteral("<a href=\"\\2\">\\1</a>"));

    return out;
}

} // namespace

QString Markdown::toHtml(const QString &text) const {
    const auto lines = text.split(QLatin1Char('\n'));
    QString html;
    bool inCode = false;
    bool inList = false;
    QStringList codeBuf;

    auto closeList = [&]() {
        if (inList) {
            html += QLatin1String("</ul>");
            inList = false;
        }
    };
    auto flushCode = [&]() {
        html += QStringLiteral("<pre>%1</pre>").arg(escapeHtml(codeBuf.join(QLatin1Char('\n'))));
        codeBuf.clear();
    };

    for (const auto &line : lines) {
        const auto trimmed = line.trimmed();
        if (trimmed.startsWith(QLatin1String("```"))) {
            if (inCode) {
                flushCode();
                inCode = false;
            } else {
                closeList();
                inCode = true;
            }
            continue;
        }
        if (inCode) {
            codeBuf.append(line);
            continue;
        }
        if (trimmed.startsWith(QLatin1String("# "))) {
            closeList();
            html += QStringLiteral("<h3>%1</h3>").arg(inlineMd(trimmed.mid(2)));
            continue;
        }
        if (trimmed.startsWith(QLatin1String("## ")) || trimmed.startsWith(QLatin1String("### "))
            || trimmed.startsWith(QLatin1String("#### "))) {
            closeList();
            auto body = trimmed;
            while (body.startsWith(QLatin1Char('#')))
                body = body.mid(1);
            html += QStringLiteral("<h4>%1</h4>").arg(inlineMd(body.trimmed()));
            continue;
        }
        if (trimmed.startsWith(QLatin1String("> "))) {
            closeList();
            html += QStringLiteral("<blockquote>%1</blockquote>").arg(inlineMd(trimmed.mid(2)));
            continue;
        }
        static const QRegularExpression bulletRe(QStringLiteral("^([-*]|\\d+\\.)\\s+(.*)$"));
        const auto m = bulletRe.match(trimmed);
        if (m.hasMatch()) {
            if (!inList) {
                html += QLatin1String("<ul>");
                inList = true;
            }
            html += QStringLiteral("<li>%1</li>").arg(inlineMd(m.captured(2)));
            continue;
        }
        closeList();
        if (trimmed.isEmpty()) {
            html += QLatin1String("<p/>");
            continue;
        }
        html += QStringLiteral("<p>%1</p>").arg(inlineMd(line));
    }
    if (inCode)
        flushCode();
    closeList();
    return html;
}

QString Markdown::plain(const QString &text) const {
    QString out = text;
    static const QRegularExpression codeRe(QStringLiteral("`([^`]+)`"));
    out.replace(codeRe, QStringLiteral("\\1"));
    static const QRegularExpression boldRe(QStringLiteral("\\*\\*([^*]+)\\*\\*"));
    out.replace(boldRe, QStringLiteral("\\1"));
    static const QRegularExpression italicRe(QStringLiteral("(?<![\\w*])\\*([^*\\n]+)\\*(?![\\w*])"));
    out.replace(italicRe, QStringLiteral("\\1"));
    static const QRegularExpression linkRe(QStringLiteral("\\[([^\\]]+)\\]\\(([^)\\s]+)\\)"));
    out.replace(linkRe, QStringLiteral("\\1 (\\2)"));
    return out;
}
