pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes
import Ryoku.Ui.Singletons

// Static preview of the Day Progress widget for the Desktop Widgets grid: a ring
// filled to a sample fraction with a time at its centre. No clock, no live data;
// drawn at the widget's native size so the page scales it to fit the card.
Item {
    id: root

    implicitWidth: 200
    implicitHeight: 224

    Column {
        anchors.fill: parent
        spacing: 10

        Item {
            width: 200
            height: 200
            anchors.horizontalCenter: parent.horizontalCenter

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Qt.rgba(Tokens.ink.r, Tokens.ink.g, Tokens.ink.b, 0.16)
                    strokeWidth: 9
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 100; centerY: 100; radiusX: 89; radiusY: 89; startAngle: -90; sweepAngle: 360 }
                }
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: Tokens.sun
                    strokeWidth: 9
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 100; centerY: 100; radiusX: 89; radiusY: 89; startAngle: -90; sweepAngle: 234 }
                }
            }

            Column {
                anchors.centerIn: parent
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "14:20"
                    color: Tokens.ink
                    font.family: Tokens.ui; font.pixelSize: 38; font.weight: Font.DemiBold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.tr("65% \u00b7 of the day")
                    color: Tokens.inkMuted
                    font.family: Tokens.ui; font.pixelSize: 12
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.tr("Sun, Sep 27")
            color: Tokens.inkMuted
            font.family: Tokens.ui; font.pixelSize: 13
        }
    }
}
