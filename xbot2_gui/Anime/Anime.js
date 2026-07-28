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

    if(obj.type === 'proc_status' && obj.name === root.missionProcess) {
        root.missionRunning = obj.status === 'Running'
        if(!root.missionRunning) {
            root.missionPaused = false
            clearProgress()
        }
    }
    // pause/resume is mission specific, and is served by the mission handler
    else if(obj.type === 'mission_status') {
        root.missionPaused = root.missionRunning && obj.paused
        updateProgress(obj)
    }
}

function updateProgress(obj) {

    if(!root.missionRunning) {
        clearProgress()
        return
    }

    if(obj.progress === undefined) {
        return
    }

    const p = obj.progress
    root.missionStage = p.stage ?? ''
    root.missionStepPrevious = p.previous ?? ''
    root.missionStepCurrent = p.current ?? ''
    root.missionStepNext = p.next ?? ''
    root.missionCycleLabel = p.cycle_label ?? ''
    root.missionCycleIndex = p.cycle ?? -1
    root.missionCycleCount = p.cycle_count ?? 0
}


function clearProgress() {

    root.missionStage = ''
    root.missionStepPrevious = ''
    root.missionStepCurrent = ''
    root.missionStepNext = ''
    root.missionCycleLabel = ''
    root.missionCycleIndex = -1
    root.missionCycleCount = 0
}


function loadScenarios() {

    client.doRequest('GET', '/mission/scenarios', '',
                     (msg) =>
                     {
                         if(msg.success) {
                             root.missionProcess = msg.process
                             root.scenarioVariant = msg.variant
                             root.scenarios = msg.scenarios
                         }
                         else {
                             error(msg.message, 'mission')
                         }
                     })
}


function missionCmd(cmd, body, onSuccess) {

    client.doRequest('PUT',
                     '/process/' + root.missionProcess + '/command/' + cmd,
                     body,
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


function startMission(scenario) {

    let options = {}

    if(scenario) {
        options[root.scenarioVariant] = scenario.name
    }

    missionCmd('start', JSON.stringify({options: options}), () => {
        root.selectedScenario = scenario ?? null
        root.missionRunning = true
    })
}


function stopMission() {

    missionCmd('stop', '', () => {
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


