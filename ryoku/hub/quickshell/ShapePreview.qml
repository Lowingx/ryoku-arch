pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.Ui.Singletons

// Static preview of the Shape widget for the Desktop Widgets grid: a single
// decorative diamond in the accent, drawn at the widget's native size.
Item {
    id: root

    implicitWidth: 140
    implicitHeight: 140

    Rectangle {
        anchors.centerIn: parent
        width: 98
        height: 98
        rotation: 45
        radius: 12
        color: Tokens.sun
    }
}
