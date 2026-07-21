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
    height: 350

    property int selectedScenario: 1
    property bool showInfo: false

    signal scenarioSelected(int scenario)

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
                anchors.centerIn: parent
                spacing: 16
                // Label {
                //     text: "Select Scenario"
                //     font.pixelSize: 24
                //     font.bold: true
                //     color: Robosintesi.colors.text
                //     Layout.alignment: Qt.AlignHCenter
                // }

                Repeater {
                    model: 4
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        RstButton {
                            Layout.fillWidth: false
                            Layout.preferredHeight: 50
                            text: "run scenario " + (index + 1)
                            onClicked: {
                                popup.selectedScenario = index + 1
                                popup.scenarioSelected(index + 1)
                                popup.close()
                            }
                        }
                        
                        RstIconButton {
                            iconText: MaterialSymbolNames.info
                            backgroundColor: "transparent"
                            iconColor: Robosintesi.colors.text
                            onClicked: {
                                popup.selectedScenario = index + 1
                                popup.showInfo = true
                            }
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
                text: "Scenario " + popup.selectedScenario + " Info"
                font.pixelSize: 20
                font.bold: true
                color: Robosintesi.colors.text
                Layout.alignment: Qt.AlignHCenter
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    color: Robosintesi.colors.text
                    text: getScenarioInfo(popup.selectedScenario)
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

function getScenarioInfo(scenario) {
        switch(scenario) {
            case 1: return "Scenario 1: brief description of the first scenario"
            case 2: return "Scenario 2: brief description of the second scenario"
            case 3: return "Scenario 3: brief description of the third scenario"
            case 4: return "Scenario 4: brief description of the fourth scenario"
            default: return "No information available."
        }
    }
}
