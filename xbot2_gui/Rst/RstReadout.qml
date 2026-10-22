import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// read-only value: label, value with its unit and an optional detail after it; "—" when missing
Rectangle {
    id: readout

    property string label
    // label as a kicker (VBATT) or as plain text (ping)
    property bool kicker: true
    // already formatted
    property string value
    property string unit
    property int valueSize: 28
    property string detail
    property color detailColor: Robosintesi.colors.textSecondary
    // a chart icon next to the label, that emits plotRequested
    property bool plottable: false

    signal plotRequested()

    implicitHeight: column.implicitHeight + 24
    radius: 12
    color: Qt.alpha(Robosintesi.colors.background, 0.45)

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                Layout.fillWidth: true
                text: readout.label
                elide: Text.ElideRight
                font.pixelSize: readout.kicker ? 12 : 13
                font.letterSpacing: readout.kicker ? 3 : 0
                color: Robosintesi.colors.textSecondary
            }

            RstIcon {
                visible: readout.plottable
                text: Robosintesi.symbols.showChart
                size: 18
                color: Robosintesi.colors.textSecondary

                TapHandler {
                    onTapped: readout.plotRequested()
                }
            }
        }

        // a taller tile keeps the value at the bottom
        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            spacing: 6

            Label {
                Layout.alignment: Qt.AlignBaseline
                text: readout.value
                font.pixelSize: readout.valueSize
                font.features: ({ "tnum": 1 })
                color: readout.value === "—" ? Qt.alpha(Robosintesi.colors.text, 0.4) : Robosintesi.colors.text
            }

            Label {
                Layout.alignment: Qt.AlignBaseline
                text: readout.unit
                font.pixelSize: 16
                color: Robosintesi.colors.textSecondary
            }

            Label {
                Layout.alignment: Qt.AlignBaseline
                Layout.leftMargin: 6
                visible: text !== ""
                text: readout.detail
                font.pixelSize: 13
                color: readout.detailColor
            }
        }
    }
}
