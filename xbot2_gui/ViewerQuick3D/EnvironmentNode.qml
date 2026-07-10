import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

import Common
import Main
import "EnvironmentNode.js" as Logic

Node {

    property ClientEndpoint client

    property real alpha: 1.0

    property color color: 'lightgray'

    property bool axesVisible: false

    signal modelChanged()

    function createViewer() {
        Logic.createViewer()
    }

    // private
    id: root

    Repeater3D {

        id: visualRepeater

        model: 0

        delegate: CustomMesh {
            meshUri: modelData.filename
            parentJointName: modelData.linkName
            cylinderLength: modelData.length || 0
            cylinderRadius: modelData.radius || 0
            boxSize: modelData.size || Qt.vector3d(0, 0, 0)
            scale: modelData.scale
            position: modelData.origin_xyz
            rotation: modelData.origin_rot
            color: modelData.color ? Qt.rgba(modelData.color[0], modelData.color[1], modelData.color[2], 1.0) : root.color
            alpha: root.alpha
            visible: root.visible
            client: root.client
            axesVisible: root.axesVisible
            isSelected: false
        }
    }

    Component.onCompleted: {
        createViewer()
    }
}
