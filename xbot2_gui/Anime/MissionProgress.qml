import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Common

Item {

    id: control

    property string previousStep: ""
    property string currentStep: ""
    property string nextStep: ""

    // mission stage name (e.g. "Uncapping")
    property string stageName: ""

    property string cycleLabel: ""
    property int cycleIndex: -1
    property int cycleCount: 0

    property bool active: false

    readonly property color baseColor: Robosintesi.colors.text
    readonly property color accentColor: Robosintesi.colors.accent

    implicitHeight: column.implicitHeight

    ColumnLayout {

        id: column

        anchors.fill: parent
        spacing: 8

        RowLayout {

            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            visible: control.stageName !== "" || control.cycleCount > 0

            Label {
                text: control.stageName.toUpperCase()
                visible: control.stageName !== ""
                color: control.accentColor
                font.pixelSize: 13
                font.letterSpacing: 3
                font.bold: true
            }

            Label {
                text: "·"
                visible: control.stageName !== "" && cycleLabel.visible
                color: control.accentColor
                font.pixelSize: 13
                opacity: 0.6
            }

            Label {
                id: cycleLabel

                text: (control.cycleLabel + " " + (Math.max(control.cycleIndex, 0) + 1)
                       + " / " + control.cycleCount).trim().toUpperCase()
                visible: control.cycleCount > 0
                color: control.accentColor
                font.pixelSize: 13
                font.letterSpacing: 2
                font.bold: true
            }
        }

        RowLayout {

            Layout.fillWidth: true
            spacing: CommonProperties.geom.spacing

            StepChip {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("previous")
                text: control.previousStep
                baseColor: control.baseColor
                accentColor: control.accentColor
            }

            StepChip {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                label: qsTr("current state")
                text: control.currentStep
                baseColor: control.baseColor
                accentColor: control.accentColor
                current: true
                pulsing: control.active
            }

            StepChip {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                label: qsTr("next")
                text: control.nextStep
                baseColor: control.baseColor
                accentColor: control.accentColor
            }
        }
    }

    component StepChip: Rectangle {

        id: chip

        property string label: ""
        property string text: ""
        property bool current: false
        property bool pulsing: false
        property color baseColor: "white"
        property color accentColor: "white"
        // if no step is set render it as a placeholder
        readonly property bool empty: chip.text === ""
        property color strokeColor: chip.baseColor

        implicitHeight: current ? 84 : 66

        color: "transparent"
        radius: CommonProperties.geom.defaultRadius
        border.width: current ? 2 : 1
        border.color: chip.strokeColor
        opacity: empty ? 0.25 : (current ? 1.0 : 0.6)

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        SequentialAnimation {

            running: chip.pulsing && !chip.empty
            loops: Animation.Infinite
            onStopped: chip.strokeColor = chip.baseColor

            ColorAnimation {
                target: chip
                property: "strokeColor"
                to: chip.accentColor
                duration: 900
                easing.type: Easing.InOutQuad
            }

            ColorAnimation {
                target: chip
                property: "strokeColor"
                to: chip.baseColor
                duration: 900
                easing.type: Easing.InOutQuad
            }
        }

        ColumnLayout {

            anchors.fill: parent
            anchors.margins: 8
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: chip.label
                horizontalAlignment: Text.AlignHCenter
                color: chip.baseColor
                opacity: 0.7
                font.pixelSize: 12
                font.letterSpacing: 1
                visible: !chip.current
            }

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: chip.empty ? "—" : chip.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: chip.baseColor
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
                font.pixelSize: chip.current ? 26 : 15
                font.bold: chip.current
                font.letterSpacing: chip.current ? 1 : 0

                // small pop whenever the step changes
                onTextChanged: stepChanged.restart()
            }
        }

        SequentialAnimation {
            id: stepChanged
            NumberAnimation { target: chip; property: "scale"; to: 0.97; duration: 90 }
            NumberAnimation { target: chip; property: "scale"; to: 1.0; duration: 160; easing.type: Easing.OutBack }
        }
    }
}
