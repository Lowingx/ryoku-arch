import QtQuick
import Ryoku.Ui.Singletons

Item {
    id: card

    required property var item
    property bool selected: false
    property bool focusVisible: false
    property bool reducedMotion: false

    signal hoverChanged(bool hovered)
    signal activated()

    Rectangle {
        id: frame
        anchors.fill: parent
        anchors.margins: Tokens.s2
        color: card.selected ? Tokens.tint5 : Tokens.paper
        border.width: card.focusVisible || card.selected ? Tokens.border * 2 : Tokens.border
        border.color: card.focusVisible ? Tokens.bone : (card.selected ? Tokens.lineStrong : Tokens.line)

        ProductCover {
            id: cover
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: Math.round(parent.height * 0.67)
            item: card.item
            selected: false
            active: card.enabled && hover.hovered && card.Window.window && card.Window.window.active
        }

        Column {
            objectName: "ryostore-cover-metadata"
            anchors {
                left: parent.left; leftMargin: Tokens.s3
                right: parent.right; rightMargin: Tokens.s3
                top: cover.bottom; topMargin: Tokens.s3
            }
            spacing: Tokens.s1

            Row {
                width: parent.width
                spacing: Tokens.s2

                Text {
                    width: parent.width - position.implicitWidth - parent.spacing
                    text: String(card.item && (card.item.name || card.item.id) || I18n.tr("Untitled"))
                    color: Tokens.ink
                    font.family: Tokens.display
                    font.pixelSize: Tokens.fRow
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    id: position
                    text: String(card.item && (card.item.categoryName || card.item.category) || "").toUpperCase()
                    color: Tokens.inkMuted
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fTiny
                    font.letterSpacing: Tokens.trackLabel
                    elide: Text.ElideRight
                }
            }

            Text {
                width: parent.width
                text: String(card.item && card.item.summary || "")
                visible: text !== ""
                color: Tokens.inkDim
                font.family: Tokens.ui
                font.pixelSize: Tokens.fSmall
                maximumLineCount: 2
                wrapMode: Text.Wrap
                elide: Text.ElideRight
            }
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Tokens.border * 2
            visible: card.selected
            color: Tokens.bone
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: card.hoverChanged(hovered)
    }

    TapHandler { onTapped: card.activated() }
}
