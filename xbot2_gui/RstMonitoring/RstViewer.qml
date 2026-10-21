import QtQuick
import QtQuick.Effects
import QtQuick3D
import QtQuick3D.Helpers

import Rst
import ViewerQuick3D

// 3D view of the Robosintesi pages: camera, lights, grid, rounded corners and the toolbar frame;
// the robot nodes are its children, the toolbar buttons go in tools
Item {
    id: viewer

    default property alias content: scene.data
    property alias tools: toolRow.data
    property bool showAxes: false
    property color color: Robosintesi.colors.panel

    // the 3D object under a tap, or null
    signal tapped(var objectHit)

    function resetView() {
        originNode.resetView()
    }

    Node {
        id: scene

        Node {
            id: originNode

            x: 50
            y: 100
            z: 50
            eulerRotation.y: 40
            eulerRotation.x: -40

            PerspectiveCamera {
                id: camera
                z: 200
                clipNear: 1
            }

            function resetView() {
                x = 50
                y = 100
                z = 50
                eulerRotation.y = 40
                eulerRotation.x = -40
                camera.z = 200
            }
        }

        Axes3D {
            visible: viewer.showAxes
        }

        DirectionalLight {
            ambientColor: Qt.rgba(0.5, 0.5, 0.5, 1.0)
            brightness: 1
            eulerRotation.x: -25
        }

        DirectionalLight {
            ambientColor: Qt.rgba(-0.5, -0.5, 0.5, 1.0)
            brightness: 1
            eulerRotation.x: 25
        }

        // X and Y of the robot on the floor (scene X and Z)
        FloorAxis {
            direction: Qt.vector3d(1, 0, 0)
            tint: Qt.alpha(Robosintesi.colors.text, 0.5)
        }

        FloorAxis {
            direction: Qt.vector3d(0, 0, 1)
            tint: Qt.alpha(Robosintesi.status.negative, 0.6)
        }
    }

    View3D {
        id: view3d
        anchors.fill: parent
        importScene: scene
        camera: camera

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Color
            clearColor: viewer.color
            // its own axes are saturated red and blue: FloorAxis draws them
            InfiniteGrid {
                gridInterval: 30
                gridAxes: false
            }
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        OrbitCameraController {
            anchors.fill: parent
            camera: camera
            origin: originNode
        }

        TapHandler {
            onTapped: point => viewer.tapped(view3d.pick(point.position.x, point.position.y).objectHit)
        }
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: Robosintesi.geom.radius
        visible: false
        layer.enabled: true
    }

    Rectangle {
        visible: toolRow.children.length > 0
        anchors { top: parent.top; right: parent.right; margins: 16 }
        width: toolRow.implicitWidth + 12
        height: toolRow.implicitHeight + 12
        radius: Robosintesi.geom.radius
        color: Qt.alpha(Robosintesi.colors.background, 0.85)

        Row {
            id: toolRow
            anchors.centerIn: parent
            spacing: 4
        }
    }

    // 1 px line through the origin
    component FloorAxis: Model {
        property vector3d direction
        property color tint

        geometry: ProceduralMesh {
            positions: [direction.times(-10000), direction.times(10000)]
            primitiveMode: ProceduralMesh.Lines
        }

        materials: PrincipledMaterial {
            lighting: PrincipledMaterial.NoLighting
            alphaMode: PrincipledMaterial.Blend
            baseColor: tint
        }
    }
}
