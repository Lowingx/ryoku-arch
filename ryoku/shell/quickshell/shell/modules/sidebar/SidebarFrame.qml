pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import shell.services
import "../../components"

Rectangle {
    property real s: 1
    readonly property bool classic: Config.sidebars.layout === "classic"
    radius: classic ? Theme.radiusWidget : Tokens.radius * s * 3
    color: classic ? Theme.surface : Tokens.paper
    border.width: Tokens.border
    border.color: classic ? Theme.outline : Tokens.lineStrong
    antialiasing: true
    SumiEdge { visible: parent.classic; radius: parent.radius }
}
