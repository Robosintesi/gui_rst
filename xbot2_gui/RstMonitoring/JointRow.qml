import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Rst

import "Format.js" as Format

// joint of the JOINTS list: name, a bar from the center (negative to the left, positive to the
// right, each side scaled to its own limit) and the value; temperatures fill from the left
Rectangle {
    id: row

    property string name
    property var value
    property real lower: -1
    property real upper: 1
    property string unit
    property int decimals: 2
    property bool selected: false
    // temperatures: from the left, 0 to upper, warn color from warnAt
    property bool oneSided: false
    property real warnAt: Infinity
    // hysteresis of the "at zero" state, in the unit of the value
    property real zeroIn: 0.005
    property real zeroOut: 0.008

    signal clicked()

    readonly property bool valid: Format.valid(value)
    // from 95% of the limit, or from warnAt for the temperatures
    readonly property bool nearLimit: Math.abs(fraction) >= 0.95 || (valid && value >= warnAt)
    property bool atZero: false
    // -1..1, the fraction of the side the value is on
    readonly property real fraction: {
        if (!valid) {
            return 0
        }
        if (oneSided || value >= 0) {
            return upper > 0 ? Math.max(0, Math.min(1, value / upper)) : 0
        }
        return lower < 0 ? -Math.min(1, value / lower) : 0
    }

    onValueChanged: {
        if (oneSided || !valid) {
            atZero = false
        } else if (atZero ? Math.abs(value) > zeroOut : Math.abs(value) < zeroIn) {
            atZero = !atZero
        }
    }

    implicitHeight: 80
    color: selected ? Qt.alpha(Robosintesi.colors.text, 0.12) : "transparent"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: row.name
                elide: Text.ElideRight
                font.pixelSize: 16
                color: Robosintesi.colors.text
            }

            Item {
                id: bar

                readonly property real origin: row.oneSided ? 0 : width / 2
                readonly property real fillWidth: row.fraction === 0 ? 0
                                                                     : Math.max(6, Math.abs(row.fraction) * (width - origin))

                Layout.fillWidth: true
                implicitHeight: 12

                // out of zero: track and fill
                Item {
                    anchors.fill: parent
                    opacity: row.atZero ? 0 : 1

                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Qt.alpha(Robosintesi.colors.text, 0.14)
                    }

                    // rounded only at the outer end
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: row.fraction < 0 ? bar.origin - width : bar.origin
                        width: bar.fillWidth
                        height: 6
                        radius: 3
                        color: row.nearLimit ? Robosintesi.status.warn
                                             : row.fraction < 0 ? Robosintesi.status.negative : Robosintesi.colors.text

                        Behavior on width { NumberAnimation { duration: 120 } }

                        Rectangle {
                            x: row.fraction < 0 ? parent.width - width : 0
                            width: Math.min(3, parent.width)
                            height: parent.height
                            color: parent.color
                        }
                    }
                }

                // at zero: a thin track with a gap, and a capsule in the gap
                Item {
                    anchors.fill: parent
                    opacity: row.atZero ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 120 } }

                    Repeater {
                        model: 2

                        Rectangle {
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            x: index === 0 ? 0 : parent.width / 2 + 14
                            width: parent.width / 2 - 14
                            height: 2
                            color: Qt.alpha(Robosintesi.colors.text, 0.14)
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 20
                        height: 8
                        radius: 4
                        color: Robosintesi.status.ok
                    }
                }

                // zero tick, on top
                Rectangle {
                    visible: !row.oneSided
                    anchors.centerIn: parent
                    width: 2
                    height: 12
                    color: Qt.alpha(Robosintesi.colors.text, 0.5)
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: false
            Layout.preferredWidth: 88
            spacing: 2

            Label {
                Layout.alignment: Qt.AlignRight
                text: Format.number(row.atZero ? 0 : row.value, row.decimals)
                font.pixelSize: 22
                font.features: ({ "tnum": 1 })
                color: row.atZero ? Robosintesi.status.ok : Robosintesi.colors.text
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: row.atZero ? "at zero" : row.unit
                font.pixelSize: 12
                color: row.atZero ? Robosintesi.status.ok : Robosintesi.colors.textSecondary
            }
        }

        RstIcon {
            text: Robosintesi.symbols.chevronRight
            size: 22
            color: Robosintesi.colors.textSecondary
        }
    }

    TapHandler {
        onTapped: row.clicked()
    }
}
