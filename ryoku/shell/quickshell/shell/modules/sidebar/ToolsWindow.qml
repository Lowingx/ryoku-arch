pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC
import Ryoku.Ui
import Ryoku.Ui.Singletons
import shell.services
import "cards" as Cards

UtilityWindow {
    id: root

    property string page: ""

    windowTitle: I18n.tr("Ryoku Tools")
    heading: I18n.tr("Tools")
    subtitle: I18n.tr("Downloads, compression, packages, and active jobs")

    onActiveChanged: {
        if (root.active) {
            tool.lastPage = "";
            Qt.callLater(tool.applyPage);
        } else {
            tool.pickerOpen = false;
            tool.setupOpen = false;
        }
    }
    onPageChanged: if (root.active) {
        tool.lastPage = "";
        Qt.callLater(tool.applyPage);
    }

    body: [
    Item {
        anchors.fill: parent

        Flickable {
            id: scroll
            anchors.fill: parent
            contentWidth: width
            contentHeight: Math.max(height, tool.implicitHeight)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: !tool.pickerOpen && !tool.setupOpen

            QQC.ScrollBar.vertical: ScrollRail {
                policy: tool.pickerOpen || tool.setupOpen ? QQC.ScrollBar.AlwaysOff : QQC.ScrollBar.AsNeeded
                motionEnabled: !Tokens.reduceMotion && !Motion.reduce
            }

            Cards.ToolsCard {
                id: tool
                width: scroll.width
                height: Math.max(scroll.height, implicitHeight)
                s: root.s
                open: root.active
                reveal: root.active ? 1 : 0
                tabActive: root.active
                page: root.page
                viewportHeight: scroll.height
                compact: false
                onRequestClose: root.requestClose()
                onPick: scroll.contentY = 0
                onSetupOpenChanged: if (setupOpen) scroll.contentY = 0
            }
        }
    }
    ]
}
