import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Font
import Common
import Main
import ViewerQuick3D

import "Anime.js" as Logic

MultiPaneResponsiveLayout {


    property ClientEndpoint client
    property Item robotViewer: loader.item
    enabled: client.robotConnected
    property bool isCurrentPage
    property bool isAppRunning: false
    property bool missionRunning: false
    property bool missionPaused: false

    property string missionStage: ""
    property string missionStepPrevious: ""
    property string missionStepCurrent: ""
    property string missionStepNext: ""
    property string missionCycleLabel: ""
    property int missionCycleIndex: -1
    property int missionCycleCount: 0

    property string missionProcess: "mission"
    property string scenarioVariant: "scenario"

    property var scenarios: []
    property var selectedScenario: null

    id: root

    LayoutClassHelper {
        id: layout
        targetWidth: root.width
    }

    Item {

        property string iconText: 'Telemetry'
        property string iconChar: MaterialSymbolNames.barchart
        property real columnSize: 0.6

        id: leftRoot
        width: parent.width

        Column {

            width: parent.width
            spacing: 16

            // safety, filters, and battery
            GridLayout {

                id: jointDeviceGrid

                width: parent.width

                rows: layout.compact ? -1 : 1
                columns: layout.compact ? 1 : -1

                rowSpacing: 8
                columnSpacing: 8

            }

        }
        RowLayout {
            anchors.fill: parent
            anchors.margins: CommonProperties.geom.margins
            spacing: CommonProperties.geom.spacing

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true


                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: CommonProperties.geom.spacing

                    RstButton {
                        id:startMission
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 80
                        Layout.alignment: Qt.AlignHCenter
                        text: "start"
                        font.pixelSize: 40
                        font.letterSpacing: 2
                        font.bold: true
                        enabled: !root.missionRunning
                        opacity: enabled ? 1 : 0.5

                        onClicked: {
                            if(root.scenarios.length > 0) {
                                scenarioPopup.open()
                            }
                            else {
                                Logic.startMission(null)
                            }
                        }
                    }

                    RstButton {
                        id: pauseMission
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 80
                        Layout.alignment: Qt.AlignHCenter
                        text: root.missionPaused ? "resume" : "pause"
                        font.pixelSize: 40
                        font.letterSpacing: 2
                        font.bold: true
                        enabled: root.missionRunning
                        opacity: enabled ? 1 : 0.5
                        onClicked: Logic.setMissionPaused(!root.missionPaused)

                        // catppuccin macchiato green
                        readonly property color pausedGreen: "#a6da95"
                        readonly property color defaultTextColor: Robosintesi.colors.background

                        SequentialAnimation {
                            running: root.missionPaused
                            loops: Animation.Infinite

                            onStopped: pauseMission.textColor = pauseMission.defaultTextColor

                            ColorAnimation {
                                target: pauseMission
                                property: "textColor"
                                to: pauseMission.pausedGreen
                                duration: 700
                                easing.type: Easing.InOutQuad
                            }

                            ColorAnimation {
                                target: pauseMission
                                property: "textColor"
                                to: pauseMission.defaultTextColor
                                duration: 700
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    RstButton {
                        id: stopMission
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 80
                        Layout.alignment: Qt.AlignHCenter
                        text: "stop"
                        font.pixelSize: 40
                        font.letterSpacing: 2
                        font.bold: true
                        enabled: root.missionRunning
                        opacity: enabled ? 1 : 0.5
                        borderWidth: 2
                        textColor: enabled ? "#e78284" : Robosintesi.colors.background
                        onClicked: Logic.stopMission()
                    }
                }
            }

        }
    }

    ColumnLayout {

        property string iconText: 'Control'
        property string iconChar: MaterialSymbolNames.box3d
        property real columnSize: 1.4

        anchors.fill: parent

        Loader {

            id: loader
            width: parent.width
            asynchronous: true
            active: true

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 200

            sourceComponent: RobotModelViewer {
                id: robotViewer
                client: root.client
                color: Qt.transparent
                showCommand: false
            }

        }

        MissionProgress {
            id: missionProgress

            Layout.fillWidth: true
            Layout.margins: CommonProperties.geom.margins
            Layout.bottomMargin: CommonProperties.geom.margins

            stageName: root.missionStage
            previousStep: root.missionStepPrevious
            currentStep: root.missionStepCurrent
            nextStep: root.missionStepNext
            cycleLabel: root.missionCycleLabel
            cycleIndex: root.missionCycleIndex
            cycleCount: root.missionCycleCount
            active: root.missionRunning && !root.missionPaused
        }

    }

    ScenarioPopup {
        id: scenarioPopup
        parent: Overlay.overlay

        scenarios: root.scenarios
        missionRunning: root.missionRunning

        onAboutToShow: Logic.loadScenarios()

        onScenarioSelected: function(scenario) {
            Logic.startMission(scenario)
        }
    }

    Connections {

        target: client

        function onJointStateReceived(js) {
            Logic.jsCallback(js)
        }

        function onObjectReceived(obj) {
            Logic.objCallback(obj)
        }
    }

    Component.onCompleted: {
        if(client) {
            Logic.loadScenarios()
        }
    }

}
