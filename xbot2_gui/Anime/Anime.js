.import Common 1.0 as Common
let error = Common.CommonProperties.notifications.error

function jsCallback(js) {

    if(root.isCurrentPage) {
        robotViewer.updateRobotState(js,
                                     robotViewer.robotState,
                                     'linkPos')
    }
}


function objCallback(obj) {

    if(obj.type === 'mission_status') {
        root.missionRunning = obj.running
        root.missionPaused = obj.paused
    }
}


function startMission() {

    client.doRequest('POST', '/mission/start',
                     '',
                     (msg) =>
                     {
                         if(msg.success) {
                             root.missionRunning = true
                         }
                         else {
                             error(msg.message, 'mission')
                         }
                     })
}


function stopMission() {

    client.doRequest('POST', '/mission/stop',
                     '',
                     (msg) =>
                     {
                         if(msg.success) {
                             root.missionRunning = false
                             root.missionPaused = false
                         }
                         else {
                             error(msg.message, 'mission')
                         }
                     })
}


function setMissionPaused(paused) {

    client.doRequest('POST', '/mission/set_paused?paused=' + paused,
                     '',
                     (msg) =>
                     {
                         if(msg.success) {
                             root.missionPaused = paused
                         }
                         else {
                             error(msg.message, 'mission')
                         }
                     })
}


