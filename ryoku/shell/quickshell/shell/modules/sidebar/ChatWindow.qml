pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import shell.services
import "cards" as Cards

UtilityWindow {
    id: root

    property string page: ""

    windowTitle: I18n.tr("Ryoku Chat")
    heading: I18n.tr("Chat")
    subtitle: I18n.tr("Needle history, models, approvals, and tools")

    body: [
    Cards.ChatCard {
        anchors.fill: parent
        s: root.s
        open: root.active
        reveal: root.active ? 1 : 0
        tabActive: root.active
        viewportHeight: height
        compact: false
        onRequestClose: root.requestClose()
    }
    ]
}
