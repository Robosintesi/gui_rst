import QtQuick
import QtQuick.Controls

import Main
import Rst
import ViewerQuick3D
import "/qt/qml/Main/sharedData.js" as SharedData
import "/qt/qml/ViewerQuick3D/RobotModelViewer.js" as ViewerLogic

// robot of the Monitoring page: the state, the command (ghost) and the selected joint
RstViewer {
    id: root

    property ClientEndpoint client
    property string selected
    property bool showCmd: false
    property alias robotCmd: robotCmd

    signal jointClicked(string jointName)

    function updateState(js) {
        ViewerLogic.updateViewerState(js, robotState, 'linkPos')
    }

    function resetCmd() {
        ViewerLogic.updateViewerState(SharedData.latestJointState, robotCmd, 'posRef')
    }

    onTapped: hit => {
        if (hit && hit.parentJointName) {
            root.jointClicked(hit.parentJointName)
        }
    }

    RobotModelNode {
        id: robotState
        client: root.client
        eulerRotation.x: -90
        y: 75
        color: Robosintesi.colors.text
        selectedColor: Robosintesi.colors.selection
        selectedJoints: root.selected === "" ? [] : [root.selected]
        axesVisible: root.showAxes
    }

    RobotModelNode {
        id: robotCmd
        client: root.client
        eulerRotation.x: -90
        y: 75
        color: Robosintesi.colors.accent
        opacity: 0.5
        visible: root.showCmd
    }

    tools: [
        RstToolButton {
            display: AbstractButton.TextBesideIcon
            iconText: Robosintesi.symbols.rotation3d
            text: "axes"
            checked: root.showAxes
            onClicked: root.showAxes = !root.showAxes
        },
        RstToolButton {
            display: AbstractButton.TextBesideIcon
            iconText: Robosintesi.symbols.viewInAr
            text: "command robot"
            checked: root.showCmd
            onClicked: root.showCmd = !root.showCmd
        },
        RstToolButton {
            display: AbstractButton.TextBesideIcon
            iconText: Robosintesi.symbols.centerFocus
            text: "reset view"
            onClicked: root.resetView()
        }
    ]
}
