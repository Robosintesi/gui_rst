function makeModel(envEntities) {

    let model = []

    for (const [key, value] of Object.entries(envEntities)) {
        let obj = {}
        obj.linkName = key
        obj.filename = value.filename
        obj.scale = Qt.vector3d(value.scale[0]*100,
                                value.scale[1]*100,
                                value.scale[2]*100)
        obj.type = value.type
        obj.radius = value.radius  // mm
        obj.length = value.length  // mm
        
        // Box size: arriva in mm dal server
        if(value.size) {
            obj.size = Qt.vector3d(value.size[0],
                                  value.size[1],
                                  value.size[2])
        }
        
        // Come RobotModelNode: trasformazioni in metri, moltiplicate per 100 per Qt3D
        obj.origin_xyz = Qt.vector3d(value.origin_xyz[0] * 100,
                                     value.origin_xyz[1] * 100,
                                     value.origin_xyz[2] * 100)
        obj.origin_rot = Qt.quaternion(value.origin_rot[3],
                                       value.origin_rot[0],
                                       value.origin_rot[1],
                                       value.origin_rot[2])
        
        // Aggiungi colore se presente
        if(value.color) {
            obj.color = value.color
        }
        
        model.push(obj)
    }

    return model
}


function createViewer() {

    // clear mesh repeater model
    visualRepeater.model = 0

    // get environment entities
    client.doRequestAsync('GET', '/visual/get_environment_entities', '')
    .then((response) => {
        console.log("Environment entities loaded:", Object.keys(response).length)
        for (const [key, value] of Object.entries(response)) {
            console.log(key, "xyz:", value.origin_xyz, "color:", value.color)
        }
        let model = makeModel(response)
        console.log("First model item:", JSON.stringify(model[0]))
        visualRepeater.model = model
    })
    .catch((err) => { 
        console.error("Error loading environment:", err) 
    })
}
