pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons
import shell.services

Item {
    id: root

    required property real s
    required property bool active
    property bool detailed: false
    signal requestDetail()

    readonly property var current: root.active ? Weather.current : null
    readonly property var hours: root.active ? Weather.hourly : []
    readonly property var days: root.active ? Weather.daily : []
    readonly property bool available: root.current !== null && Weather.hasData
    readonly property int hourCount: Math.min(root.detailed ? 8 : 3, root.hours.length)
    readonly property int dayCount: Math.min(5, root.days.length)

    implicitHeight: Math.round((root.detailed ? 388 : 108) * root.s)

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius * root.s * 1.5
        color: Tokens.role("primaryContainer", Tokens.paperLift)
        border.width: Tokens.border
        border.color: Tokens.role("primary", Tokens.lineStrong)
        clip: true

        Rectangle {
            id: weatherGlow
            anchors.right: parent.right
            anchors.top: parent.top
            width: Math.round((root.detailed ? 260 : 140) * root.s)
            height: width
            radius: width / 2
            color: Tokens.role("secondaryContainer", Tokens.tint10)
            opacity: 0.62
            transform: Translate { x: weatherGlow.width * 0.32; y: -weatherGlow.height * 0.48 }
        }

        Column {
            anchors.fill: parent
            anchors.margins: (root.detailed ? Tokens.s3 : Tokens.s2) * root.s
            spacing: Tokens.s2 * root.s

            Item {
                width: parent.width
                height: Math.round((root.detailed ? 67 : 42) * root.s)

                Column {
                    anchors.left: parent.left
                    anchors.right: action.left
                    anchors.rightMargin: Tokens.s2 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.detailed ? Tokens.s1 * root.s : 0

                    Text {
                        width: parent.width
                        text: root.available ? Weather.temp : root.stateTitle()
                        color: Tokens.role("onPrimaryContainer", Tokens.ink)
                        font.family: root.available ? Tokens.display : Tokens.ui
                        font.pixelSize: (root.available ? (root.detailed ? Tokens.fHero : Tokens.fValue) : Tokens.fSmall) * root.s
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: root.available
                            ? Weather.condition + (Weather.location.length > 0 ? " · " + Weather.location : "")
                            : root.stateDetail()
                        color: Tokens.role("onPrimaryContainer", Tokens.inkDim)
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall * root.s
                        elide: Text.ElideRight
                    }
                }

                CornerButton {
                    id: action
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s
                    text: root.detailed ? I18n.tr("Refresh") : I18n.tr("Forecast")
                    glyph: root.detailed ? "refresh" : "arrow_forward"
                    subtle: !root.detailed
                    emphasis: root.detailed
                    Accessible.name: text
                    onClicked: {
                        if (root.detailed)
                            Weather.retry();
                        else
                            root.requestDetail();
                    }
                }
            }

            Row {
                id: compactHours
                visible: root.available && root.hourCount > 0
                width: parent.width
                height: root.detailed ? Math.round(74 * root.s) : Math.round(38 * root.s)

                Repeater {
                    model: root.hourCount
                    delegate: Item {
                        id: hour
                        required property int index
                        readonly property var entry: root.hours[index]
                        width: compactHours.width / root.hourCount
                        height: compactHours.height

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Tokens.border
                            visible: hour.index > 0
                            color: Tokens.role("onPrimaryContainer", Tokens.lineSoft)
                        }

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - Tokens.s2 * root.s
                            spacing: root.detailed ? Tokens.s1 * root.s : 0

                            Text {
                                width: parent.width
                                text: hour.entry ? hour.entry.time || "" : ""
                                color: Tokens.role("onPrimaryContainer", Tokens.inkMuted)
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fTiny * root.s
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: hour.entry ? hour.entry.temperature || "" : ""
                                color: Tokens.role("onPrimaryContainer", Tokens.ink)
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fSmall * root.s
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                visible: root.detailed
                                width: parent.width
                                text: hour.entry ? I18n.tr("%1% rain").arg(hour.entry.precip || 0) : ""
                                color: Tokens.role("onPrimaryContainer", Tokens.inkMuted)
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fTiny * root.s
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }

            Item {
                visible: root.detailed && root.available
                width: parent.width
                height: Math.round(42 * root.s)

                Row {
                    anchors.fill: parent
                    spacing: Tokens.s2 * root.s

                    Repeater {
                        model: [
                            { label: I18n.tr("Feels"), value: root.current ? root.current.feelsLike || "" : "" },
                            { label: I18n.tr("Humidity"), value: root.current ? String(root.current.humidity || 0) + "%" : "" },
                            { label: I18n.tr("Wind"), value: root.current ? (root.current.wind || "") + (root.current.windUnits || "") : "" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: (parent.width - parent.spacing * 2) / 3
                            height: parent.height
                            radius: Tokens.radius * root.s
                            color: Tokens.role("surfaceContainerLow", Tokens.tint5)

                            Column {
                                anchors.centerIn: parent
                                width: parent.width - Tokens.s2 * root.s
                                spacing: 0
                                Text {
                                    width: parent.width
                                    text: modelData.label
                                    color: Tokens.inkMuted
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fTiny * root.s
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: modelData.value
                                    color: Tokens.ink
                                    font.family: Tokens.ui
                                    font.pixelSize: Tokens.fSmall * root.s
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }

            Column {
                visible: root.detailed && root.available
                width: parent.width
                spacing: 0

                Text {
                    width: parent.width
                    height: Math.round(24 * root.s)
                    text: I18n.tr("Next days")
                    color: Tokens.role("onPrimaryContainer", Tokens.ink)
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fSmall * root.s
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: root.dayCount
                    delegate: Item {
                        id: day
                        required property int index
                        readonly property var entry: root.days[index]
                        width: parent.width
                        height: Math.round(31 * root.s)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: Tokens.border
                            color: Tokens.role("onPrimaryContainer", Tokens.lineSoft)
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: day.entry ? day.entry.weekday || day.entry.day || "" : ""
                            color: Tokens.role("onPrimaryContainer", Tokens.inkDim)
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall * root.s
                            font.weight: Font.Medium
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: day.entry ? (day.entry.low || "") + "  /  " + (day.entry.high || "") : ""
                            color: Tokens.role("onPrimaryContainer", Tokens.ink)
                            font.family: Tokens.ui
                            font.pixelSize: Tokens.fSmall * root.s
                            font.weight: Font.DemiBold
                            font.features: ({ "tnum": 1 })
                        }
                    }
                }
            }
        }
    }

    function stateTitle() {
        if (Weather.status === "loading") return I18n.tr("Reading weather");
        if (Weather.status === "error") return I18n.tr("Weather unavailable");
        return I18n.tr("No forecast yet");
    }

    function stateDetail() {
        if (Weather.errorText.length > 0) return Weather.errorText;
        return I18n.tr("Set a location in Ryoku Settings");
    }
}
