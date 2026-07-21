import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import ViewerQuick3D
import Main

Node {

    property ClientEndpoint client

    property string meshUri

    property alias visible: model.visible
    property alias axesVisible: axes.visible
    property color color: Qt.rgba(0.8, 0.8, 0.8, 1.0)
    property alias alpha: material.opacity

    property alias scale: model.scale
    property alias localPosition: model.position
    property alias localRotation: model.rotation

    property real cylinderRadius
    property real cylinderLength
    
    property vector3d boxSize: Qt.vector3d(0, 0, 0)

    property string parentJointName
    property bool isSelected: false


    // private
    id: root

    property Geometry modelGeometry: MeshGeometry {
        id: geom
    }

    Node {

        id: wrapperNode

        Model {
            id: model
            visible: true
            pickable: true
            property alias parentJointName: root.parentJointName
            property alias isSelected: root.isSelected
            materials: [
                PrincipledMaterial {
                    id: material
                    baseColor: root.isSelected ?
                                Qt.darker(root.color, 1.5) :
                                root.color
                    metalness: 0
                    roughness: 0
                }
            ]
        }

        Axes3D {
            id: axes
            scale: Qt.vector3d(0.1, 0.1, 0.1)
        }

    }


    CachedVisual {

        id: cachedVisual

        onMeshReady: {
            geom.setUrl(cachedVisual.file)
            model.geometry = geom
        }
    }

    Component.onCompleted: {

        if(meshUri[0] === '#') {

            let meshMap = Object()
            meshMap['#CYLINDER'] = '#Cylinder'
            meshMap['#BOX'] = '#Cube'

            model.source = meshMap[meshUri]
            
            if(meshUri === '#CYLINDER') {
                wrapperNode.eulerRotation.x = 90
                wrapperNode.scale.x = root.cylinderRadius * 0.01 * 2
                wrapperNode.scale.y = root.cylinderLength * 0.01
                wrapperNode.scale.z = root.cylinderRadius * 0.01 * 2
                wrapperNode.position.z = root.cylinderLength * 0.1 / 2
            }
            else if(meshUri === '#BOX') {
                // #Cube: 100x100x100 unità
                // boxSize in mm (come cylinderRadius/Length), converti con *0.01
                wrapperNode.scale.x = root.boxSize.x * 0.01
                wrapperNode.scale.y = root.boxSize.y * 0.01
                wrapperNode.scale.z = root.boxSize.z * 0.01
            }

        }
        else {

            cachedVisual.addMesh(encodeURIComponent(meshUri),
                                 `http://${client.hostname}:${client.port}/visual/get_mesh/${encodeURIComponent(meshUri)}`)
        }


    }

}
