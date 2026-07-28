import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Common
import Font

Popup {
    id: popup
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay
    width: 400
    height: Math.min(520, Math.max(260, scenarioColumn.implicitHeight + 40))

    property var scenarios: []

    property int selectedIndex: -1
    property bool missionRunning: false
    property bool showInfo: false

    readonly property var selectedScenario:
        (selectedIndex >= 0 && selectedIndex < scenarios.length) ? scenarios[selectedIndex] : undefined

    signal scenarioSelected(var scenario)

    onOpened: showInfo = false

    background: Rectangle {
        color: Robosintesi.colors.background
        // border.color: CommonProperties.colors.accent
        // border.width: 2
        radius: CommonProperties.geom.defaultRadius

    }

    Flipable {
        id: flipable
        anchors.fill: parent
        anchors.margins: 20

        property bool flipped: popup.showInfo

        front: Item {
            anchors.fill: parent

            ColumnLayout {
                id: scenarioColumn
                width: parent.width
                anchors.centerIn: parent
                spacing: 16

                Label {
                    visible: popup.scenarios.length === 0
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: Robosintesi.colors.text
                    text: "No scenario defined in the launcher configuration"
                }

                Repeater {
                    model: popup.scenarios

                    ScenarioCard {
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true

                        label: modelData.label
                        info: modelData.info
                        running: popup.missionRunning

                        onRunClicked: {
                            popup.selectedIndex = index
                            popup.scenarioSelected(modelData)
                            popup.close()
                        }

                        onInfoClicked: {
                            popup.selectedIndex = index
                            popup.showInfo = true
                        }
                    }
                }

                RstIconButton {
                    Layout.alignment: Qt.AlignHCenter
                    iconText: MaterialSymbolNames.goBack
                    iconColor: Robosintesi.colors.text
                    backgroundColor: "transparent"
                    onClicked: popup.close()
                }
            }
        }

        back: ColumnLayout {
            anchors.fill: parent
            spacing: 16

            Label {
                text: popup.selectedScenario ? popup.selectedScenario.label : ""
                font.pixelSize: 20
                font.bold: true
                color: Robosintesi.colors.text
                Layout.alignment: Qt.AlignHCenter
            }

            ScrollView {
                id: infoScroll

                Layout.fillWidth: true
                Layout.fillHeight: true

                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Label {
                    width: infoScroll.availableWidth
                    wrapMode: Text.WordWrap
                    color: Robosintesi.colors.text
                    text: popup.selectedScenario ? popup.selectedScenario.info : "No information available."
                }
            }

            RstIconButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 100
                iconText: MaterialSymbolNames.goBack
                iconColor: Robosintesi.colors.text
                backgroundColor: "transparent"
                onClicked: popup.showInfo = false
            }
        }

        transform: Rotation {
            id: rotation
            origin.x: flipable.width / 2
            origin.y: flipable.height / 2
            axis.x: 0; axis.y: 1; axis.z: 0
            angle: 0
        }

        states: State {
            name: "back"
            PropertyChanges { target: rotation; angle: 180 }
            when: flipable.flipped
        }

        transitions: Transition {
            NumberAnimation { target: rotation; property: "angle"; duration: 400 }
        }
    }
}
