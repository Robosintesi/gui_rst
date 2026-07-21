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

    if(obj.type === 'proc_status' && obj.name === missionProcess) {
        root.missionRunning = obj.status === 'Running'
        if(!root.missionRunning) {
            root.missionPaused = false
        }
    }
    // pause/resume is mission specific, and is served by the mission handler
    else if(obj.type === 'mission_status') {
        root.missionPaused = root.missionRunning && obj.paused
    }
}


const missionProcess = 'mission'

function missionCmd(cmd, onSuccess) {

    client.doRequest('PUT',
                     '/process/' + missionProcess + '/command/' + cmd,
                     '',
                     (msg) =>
                     {
                         if(msg.success) {
                             onSuccess()
                         }
                         else {
                             error(msg.message, 'mission')
                         }
                     })
}


function startMission() {

    missionCmd('start', () => { root.missionRunning = true })
}


function stopMission() {

    missionCmd('stop', () => {
        root.missionRunning = false
        root.missionPaused = false
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


