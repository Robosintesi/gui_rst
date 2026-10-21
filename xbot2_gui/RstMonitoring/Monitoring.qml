import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import Common
import Font
import Main
import Rst

import "/qt/qml/Main/sharedData.js" as SharedData
import "/qt/qml/Monitoring/Monitoring.js" as Logic
import "Format.js" as Format

// Monitoring page: safety and joints | selected joint, detail and command | 3D viewer
Item {
    id: root

    property ClientEndpoint client
    property bool isCurrentPage
    property Item livePlot: CommonProperties.globalLivePlot
    enabled: client.robotConnected

    // latest joint state, updated only while the page is visible
    property var js
    property var jointNames: []
    property var groups: []
    property var qmin: []
    property var qmax: []
    property var vmax: []
    property var taumax: []

    property string selected
    readonly property int selectedIndex: jointNames.indexOf(selected)
    readonly property string selectedGroup: groups.find(g => g.joints.includes(selected))?.name ?? ""
    property int field: 0
    // joint name -> fault code, "" when there is none
    property var faults: ({})

    property bool jointActive: true
    property bool filterActive
    property real filterCutoff
    property real vbatt
    property real iload
    property real vbattAlarm: 49.5
    // shortcut: fixed temperature scale [°C], until the server sends the temperature limits
    readonly property real tempMax: 80
    readonly property real tempWarn: 60

    readonly property var fields: [
        { name: "position", key: "linkPos", unit: "rad" },
        { name: "velocity", key: "motVel", unit: "rad/s" },
        { name: "torque", key: "tor", unit: "Nm" },
        { name: "temp", key: "motorTemp", unit: "°C" }
    ]

    readonly property var sections: [
        { name: "POSITION", unit: "rad", cells: [["reference", "posRef"], ["link", "linkPos"], ["motor", "motPos"]] },
        { name: "VELOCITY", unit: "rad/s", cells: [["reference", "velRef"], ["link", "linkVel"], ["motor", "motVel"]] },
        { name: "TORQUE", unit: "Nm", cells: [["reference", "torRef"], ["measured", "tor"], ["motor", "motTor"]] },
        // the cells of these sections have each their unit, in the label
        { name: "CONTROL", unit: "", cells: [["feedforward", "torFfwd", "Nm"], ["stiffness", "k", "Nm/rad"], ["damping", "d", "Nm·s/rad"]] },
        { name: "HEALTH", unit: "", cells: [["motor", "motorTemp", "°C"], ["driver", "driverTemp", "°C"], ["fault code", "fault"]] }
    ]

    function value(key, i) {
        if (key === "fault") {
            return faults[jointNames[i]] ?? ""
        }
        return js?.[key]?.[i]
    }

    // [lower, upper] of field f for joint i
    function range(f, i) {
        switch (f) {
        case 0: return [qmin[i], qmax[i]]
        case 1: return [-vmax[i], vmax[i]]
        case 2: return [-taumax[i], taumax[i]]
        default: return [0, tempMax]
        }
    }

    function loadInfo() {
        jointNames = SharedData.jointNames
        groups = SharedData.jointGroups
        qmin = SharedData.qmin
        qmax = SharedData.qmax
        vmax = SharedData.vmax
        taumax = SharedData.taumax
        if (!jointNames.includes(selected)) {
            selected = jointNames[0] ?? ""
        }
    }

    function checkBattery(v) {
        if (v > 0 && v < vbattAlarm) {
            CommonProperties.notifications.error(`battery voltage V_batt = ${v} V`, "PMS")
            vbattAlarm = v - 0.5
        }
        if (v > vbattAlarm + 2) {
            vbattAlarm = v - 0.5
        }
    }

    Component.onCompleted: if (SharedData.jointNames.length > 0) loadInfo()

    Connections {
        target: root.client

        function onFinalized() {
            root.loadInfo()
        }

        function onJointStateReceived(js) {
            if (root.isCurrentPage) {
                root.js = js
                robotView.updateState(js)
            }
            Logic.addJointStatePoint(root.livePlot, js)
            root.vbatt = js.vbatt
            root.iload = js.ibatt
            root.checkBattery(js.vbatt)
        }

        function onObjectReceived(obj) {
            if (obj.type === "joint_device_info") {
                root.filterActive = obj.filter_active
                root.filterCutoff = obj.filter_cutoff_hz
                if (root.jointActive && !obj.joint_active) {
                    CommonProperties.notifications.error("Safety triggered", "robot")
                }
                root.jointActive = obj.joint_active
            } else if (obj.type === "joint_fault") {
                let faults = Object.assign({}, root.faults)
                obj.name.forEach((n, i) => faults[n] = obj.fault[i])
                root.faults = faults
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        // safety and joints
        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(560, root.width * 0.3)
            spacing: 16

            RstPanel {
                Layout.fillWidth: true

                RstKicker {
                    text: "SAFETY"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // emergency stop: solid red, not the tonal Destructive of 11a
                    RstButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        backgroundColor: root.jointActive ? Robosintesi.status.err : Robosintesi.status.ok
                        textColor: Robosintesi.brand.white
                        text: root.jointActive ? "Stop" : "Restore"
                        iconText: root.jointActive ? Robosintesi.symbols.stopCircle : MaterialSymbolNames.play
                        iconSize: 36
                        spacing: 12
                        font.pixelSize: 32
                        onClicked: Logic.setSafetyState(!root.jointActive)
                    }

                    RstIconButton {
                        Layout.preferredWidth: 80
                        Layout.preferredHeight: 80
                        iconSize: 36
                        iconText: Robosintesi.symbols.expandMore
                        onClicked: safetyMenu.open()

                        Popup {
                            id: safetyMenu
                            y: parent.height + 8
                            x: parent.width - width

                            // both show the state of the robot, a tap only sends the request
                            contentItem: ColumnLayout {
                                spacing: 16
                                enabled: root.jointActive

                                RstKicker {
                                    text: "FILTER"
                                    detail: root.filterCutoff + " Hz"
                                }

                                Switch {
                                    text: "filter active"
                                    checkable: false
                                    checked: root.filterActive
                                    onClicked: Logic.setFilterActive(!root.filterActive)
                                }

                                RstSegmented {
                                    enabled: root.filterActive
                                    model: ["safe", "medium", "fast"]
                                    currentIndex: root.filterCutoff <= 2 ? 0 : root.filterCutoff <= 10 ? 1 : 2
                                    onActivated: index => Logic.setFilterProfile(model[index])
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RstReadout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        label: "VBATT"
                        value: Format.number(root.vbatt, Format.decimals("V"))
                        unit: "V"
                    }

                    RstReadout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        label: "ILOAD"
                        value: Format.number(root.iload, Format.decimals("A"))
                        unit: "A"
                    }
                }
            }

            RstPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 20
                horizontalPadding: 16

                RowLayout {
                    Layout.fillWidth: true

                    RstKicker {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        text: "JOINTS"
                        detail: root.jointNames.length
                    }

                    RstSegmented {
                        model: root.fields.map(f => f.name)
                        currentIndex: root.field
                        onActivated: index => root.field = index
                    }
                }

                // the list, with a fade at the bottom while it goes on
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ScrollView {
                        id: jointsScroll
                        anchors.fill: parent
                        contentWidth: availableWidth
                        clip: true

                        ColumnLayout {
                            width: jointsScroll.availableWidth
                            spacing: 16

                            Repeater {
                                model: root.groups

                                ColumnLayout {
                                    id: group
                                    required property var modelData
                                    Layout.fillWidth: true
                                    spacing: 8

                                    RstKicker {
                                        Layout.leftMargin: 16
                                        text: group.modelData.name.toUpperCase().replace(/_/g, " ")
                                    }

                                    // rounded card: the mask clips the selected row too
                                    Item {
                                        Layout.fillWidth: true
                                        implicitHeight: rows.implicitHeight

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Robosintesi.geom.radius
                                            color: Qt.alpha(Robosintesi.colors.background, 0.45)
                                            layer.enabled: true
                                            layer.effect: MultiEffect {
                                                maskEnabled: true
                                                maskSource: cardMask
                                                maskThresholdMin: 0.5
                                                maskSpreadAtMin: 1.0
                                            }

                                            Column {
                                                id: rows
                                                width: parent.width

                                                Repeater {
                                                    model: group.modelData.joints

                                                    JointRow {
                                                        required property string modelData
                                                        required property int index
                                                        readonly property int idx: root.jointNames.indexOf(modelData)
                                                        readonly property var limits: root.range(root.field, idx)

                                                        width: rows.width
                                                        name: modelData
                                                        value: root.value(root.fields[root.field].key, idx)
                                                        lower: limits[0] ?? -1
                                                        upper: limits[1] ?? 1
                                                        unit: root.fields[root.field].unit
                                                        decimals: Math.min(2, Format.decimals(root.fields[root.field].unit))
                                                        oneSided: root.field === 3
                                                        warnAt: root.tempWarn
                                                        selected: modelData === root.selected
                                                        onClicked: root.selected = modelData

                                                        Rectangle {
                                                            visible: index < group.modelData.joints.length - 1
                                                            anchors.bottom: parent.bottom
                                                            width: parent.width
                                                            height: 1
                                                            color: Qt.alpha(Robosintesi.colors.text, 0.1)
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            id: cardMask
                                            anchors.fill: parent
                                            radius: Robosintesi.geom.radius
                                            visible: false
                                            layer.enabled: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: !jointsScroll.contentItem.atYEnd
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 24
                        gradient: Gradient {
                            GradientStop { position: 0; color: Qt.alpha(Robosintesi.colors.panel, 0) }
                            GradientStop { position: 1; color: Robosintesi.colors.panel }
                        }
                    }
                }
            }
        }

        // selected joint
        ScrollView {
            id: detailScroll
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(600, root.width * 0.32)
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                width: detailScroll.availableWidth
                spacing: 16

                RstPanel {
                    Layout.fillWidth: true

                    RstKicker {
                        text: "JOINT"
                    }

                    Label {
                        Layout.fillWidth: true
                        text: root.selected
                        elide: Text.ElideRight
                        // Inter: the 1 of Space Grotesk reads badly in the joint names
                        font.pixelSize: 34
                        font.bold: true
                        color: Robosintesi.colors.text
                    }

                    RowLayout {
                        spacing: 8

                        RstPill {
                            visible: root.selectedGroup !== ""
                            implicitHeight: 32
                            padding: 12
                            tint: Robosintesi.colors.text
                            label: root.selectedGroup.replace(/_/g, " ")
                        }

                        RstPill {
                            readonly property string fault: root.faults[root.selected] ?? ""
                            implicitHeight: 32
                            padding: 12
                            gap: 6
                            iconSize: 16
                            iconText: fault === "" ? Robosintesi.symbols.check : ""
                            tint: fault === "" ? Robosintesi.status.ok : Robosintesi.status.err
                            label: fault === "" ? "no fault" : fault
                        }
                    }

                    Repeater {
                        model: root.sections

                        ColumnLayout {
                            id: section
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            spacing: 10

                            RstKicker {
                                text: section.modelData.name
                                detail: section.modelData.unit
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: section.modelData.cells

                                    RstReadout {
                                        required property var modelData
                                        // a number, or the fault code as it is
                                        readonly property var raw: root.value(modelData[1], root.selectedIndex)
                                        readonly property string cellUnit: modelData[2] ?? section.modelData.unit

                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.preferredHeight: 76
                                        kicker: false
                                        valueSize: 24
                                        label: modelData[2] ? modelData[0] + " " + modelData[2] : modelData[0]
                                        value: typeof raw === "string" && raw !== "" ? raw : Format.number(raw, Format.decimals(cellUnit))
                                        plottable: Format.valid(raw)
                                        onPlotRequested: Logic.addJointStateSeries(root.livePlot, root.selected, modelData[1])
                                    }
                                }
                            }
                        }
                    }
                }

                JointCommand {
                    Layout.fillWidth: true
                    enabled: root.jointActive
                    client: root.client
                    joint: root.selected
                    qmin: root.qmin[root.selectedIndex] ?? -1
                    qmax: root.qmax[root.selectedIndex] ?? 1
                    vmax: root.vmax[root.selectedIndex] ?? 0
                    taumax: root.taumax[root.selectedIndex] ?? 0
                    js: root.js
                    jointIndex: root.selectedIndex
                    robotCmd: robotView.robotCmd
                    onPreviewChanged: robotView.showCmd = true
                    onResetCmd: robotView.resetCmd()
                }
            }
        }

        // 3D viewer
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RobotView {
                id: robotView
                anchors.fill: parent
                client: root.client
                selected: root.selected
                onJointClicked: jointName => root.selected = jointName
            }

            Rectangle {
                visible: root.selected !== ""
                anchors { left: parent.left; top: parent.top; margins: 16 }
                width: badgeRow.implicitWidth + 40
                height: 60
                radius: Robosintesi.geom.radius
                color: Qt.alpha(Robosintesi.colors.background, 0.85)

                RowLayout {
                    id: badgeRow
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        implicitWidth: 10
                        implicitHeight: 10
                        radius: 5
                        color: Robosintesi.colors.selection
                    }

                    Label {
                        text: root.selected
                        font.pixelSize: 18
                        font.bold: true
                        color: Robosintesi.colors.text
                    }

                    Label {
                        text: Format.number(root.value(root.fields[root.field].key, root.selectedIndex),
                                            Format.decimals(root.fields[root.field].unit))
                              + " " + root.fields[root.field].unit
                        font.pixelSize: 18
                        font.features: ({ "tnum": 1 })
                        color: Robosintesi.colors.textSecondary
                    }
                }
            }
        }
    }
}
