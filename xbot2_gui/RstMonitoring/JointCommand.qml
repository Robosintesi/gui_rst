import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Font
import Main
import Rst

import "/qt/qml/Main/sharedData.js" as SharedData
import "Format.js" as Format

// command of the selected joint, with the routes and ranges of Monitoring/JointCommand.js:
// position, stiffness and damping go as a trajectory, a velocity or a torque is sent while send
// is held
RstPanel {
    id: panel

    property ClientEndpoint client
    property string joint
    property real qmin: -1
    property real qmax: 1
    property real vmax: 0
    property real taumax: 0
    // latest joint state of the page and index of the joint in it, for "now"
    property var js
    property int jointIndex: -1
    // RobotModelNode of the command robot (ghost)
    property var robotCmd

    // the ghost moved, so it should be shown
    signal previewChanged()
    // the ghost should go back to the references
    signal resetCmd()

    readonly property var modes: [
        { name: "position", ctrl: "Position", unit: "rad", key: "linkPos" },
        { name: "velocity", ctrl: "Velocity", unit: "rad/s", key: "motVel" },
        { name: "torque", ctrl: "Effort", unit: "Nm", key: "tor" },
        { name: "stiffness", ctrl: "Stiffness", unit: "Nm/rad", key: "k" },
        { name: "damping", ctrl: "Damping", unit: "Nm·s/rad", key: "d" }
    ]
    property int mode: 0
    readonly property var current: modes[mode]
    readonly property int decimals: Format.decimals(current.unit)
    readonly property bool continuous: current.ctrl === "Velocity" || current.ctrl === "Effort"
    // stiffness and damping: from 0, filled from the left
    readonly property bool unipolar: mode >= 3
    // set by reset(), so the range does not follow the gain while it changes
    property real gainMax: 100
    readonly property real lower: [qmin, -vmax, -Math.min(taumax, 50), 0, 0][mode]
    readonly property real upper: [qmax, vmax, Math.min(taumax, 50), gainMax, gainMax][mode]
    readonly property var now: jointIndex >= 0 ? js?.[current.key]?.[jointIndex] : undefined
    property real target: 0
    property real trajectoryTime: 5
    property bool running: false

    function reset() {
        let js = SharedData.latestJointState
        let i = SharedData.jointNames.indexOf(joint)
        let k = js && i >= 0 ? js.k[i] : 0
        let d = js && i >= 0 ? js.d[i] : 0
        gainMax = mode === 3 ? Math.max(k * 10, 100) : Math.max(d * 10, 50)
        target = js && i >= 0 ? [js.posRef[i], 0, 0, k, d][mode] : 0
        resetCmd()
    }

    function setTarget(v) {
        target = Math.max(lower, Math.min(upper, v))
        if (mode === 0 && robotCmd && robotCmd.ndof > 0) {
            let q = [...robotCmd.q]
            q[robotCmd.jointNames.indexOf(joint)] = target
            robotCmd.q = q
            previewChanged()
        }
    }

    function send() {
        if (running) {
            client.doRequestAsync('POST', '/joint_command/goto/stop')
            return
        }
        running = true
        client.doRequestAsync('PUT', `/joint_command/goto/${joint}?qref=${target}&time=${trajectoryTime}&ctrl=${current.ctrl}`)
        .then(() => panel.running = false)
        .catch((err) => { panel.running = false; console.error(err) })
    }

    function sendContinuous() {
        client.sendTextMessageUdp(JSON.stringify({type: 'joint_cmd', joint_names: [joint], command: [target], ctrl: current.ctrl}))
    }

    onJointChanged: reset()
    onModeChanged: reset()

    spacing: 20

    RowLayout {
        Layout.fillWidth: true

        RstKicker {
            Layout.fillWidth: true
            text: "COMMAND"
            detail: panel.joint
        }

        RstIconButton {
            Layout.topMargin: -12
            Layout.bottomMargin: -12
            Layout.rightMargin: -12
            checked: settings.visible
            iconText: MaterialSymbolNames.tune
            onClicked: settings.visible = !settings.visible
        }
    }

    RowLayout {
        id: settings
        visible: false
        spacing: 12

        Label {
            text: "trajectory time [s]"
            font.pixelSize: 14
            color: Robosintesi.colors.textSecondary
        }

        SpinBox {
            from: 1
            to: 10
            value: panel.trajectoryTime
            onValueModified: panel.trajectoryTime = value
        }
    }

    RstSegmented {
        Layout.fillWidth: true
        fillWidth: true
        itemHeight: 48
        fontSize: 15
        model: panel.modes.map(m => m.name)
        currentIndex: panel.mode
        onActivated: index => panel.mode = index
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                Layout.alignment: Qt.AlignBaseline
                text: Format.number(panel.target, panel.decimals)
                font.pixelSize: 44
                font.bold: true
                font.features: ({ "tnum": 1 })
                color: Robosintesi.colors.text
            }

            Label {
                Layout.alignment: Qt.AlignBaseline
                Layout.fillWidth: true
                text: panel.current.unit + " · now " + Format.number(panel.now, panel.decimals)
                elide: Text.ElideRight
                font.pixelSize: 16
                color: Robosintesi.colors.textSecondary
            }
        }

        StepButton {
            iconText: Robosintesi.symbols.remove
            onClicked: panel.setTarget(panel.target - (panel.upper - panel.lower) / 100)
        }

        StepButton {
            iconText: Robosintesi.symbols.add
            onClicked: panel.setTarget(panel.target + (panel.upper - panel.lower) / 100)
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        // fill from zero, so the sign of the command is visible
        Slider {
            id: slider
            Layout.fillWidth: true
            from: panel.lower
            to: panel.upper
            value: panel.target
            onMoved: panel.setTarget(value)

            readonly property real zeroPosition: to > from ? Math.max(0, Math.min(1, -from / (to - from))) : 0

            background: Item {
                x: slider.leftPadding
                y: slider.topPadding + (slider.availableHeight - height) / 2
                implicitWidth: 200
                implicitHeight: 24
                width: slider.availableWidth
                height: 24

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Qt.alpha(Robosintesi.colors.text, 0.14)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(slider.zeroPosition, slider.visualPosition) * parent.width
                    width: Math.abs(slider.visualPosition - slider.zeroPosition) * parent.width
                    height: 8
                    radius: 4
                    color: Robosintesi.colors.text
                }

                // current stiffness or damping
                Rectangle {
                    visible: panel.unipolar && Format.valid(panel.now) && slider.to > slider.from
                    x: Math.max(0, Math.min(1, (panel.now - slider.from) / (slider.to - slider.from))) * parent.width - 1
                    width: 2
                    height: 24
                    color: Robosintesi.status.negative
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + (slider.availableHeight - height) / 2
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                color: Robosintesi.colors.text
                border.color: Qt.alpha(Robosintesi.brand.black, 0.25)
                border.width: 1
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Repeater {
                id: rangeLabels
                model: panel.unipolar ? ["0", "max " + Format.number(panel.upper, panel.decimals)]
                                      : [Format.number(panel.lower, panel.decimals), "0", Format.number(panel.upper, panel.decimals)]

                Label {
                    required property int index
                    required property string modelData
                    Layout.fillWidth: true
                    horizontalAlignment: index === 0 ? Text.AlignLeft
                                                     : index === rangeLabels.count - 1 ? Text.AlignRight : Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 13
                    color: Robosintesi.colors.textSecondary
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 12
        spacing: 12

        RstButton {
            id: sendButton
            Layout.fillWidth: true
            Layout.preferredWidth: 2
            Layout.preferredHeight: 72
            kind: panel.running ? RstButton.Destructive : RstButton.Primary
            text: panel.running ? "Stop" : "Send"
            iconText: panel.running ? MaterialSymbolNames.stop : Robosintesi.symbols.send
            onClicked: if (!panel.continuous) panel.send()
        }

        RstButton {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.preferredHeight: 72
            kind: RstButton.Secondary
            text: "Reset"
            iconText: Robosintesi.symbols.undo
            onClicked: panel.reset()
        }
    }

    // pressed goes false also when the touch leaves send or is taken by the scroll view
    Timer {
        interval: 20
        repeat: true
        triggeredOnStart: true
        running: panel.continuous && sendButton.pressed
        onTriggered: panel.sendContinuous()
    }

    component StepButton: RstIconButton {
        Layout.preferredWidth: 56
        Layout.preferredHeight: 56
    }
}
