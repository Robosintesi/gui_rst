import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Font
import Launcher
import Main
import Rst

// Process page: processes and plugins | console; same routes as Launcher/Launcher.js
Item {
    id: root

    property ClientEndpoint client
    property bool isCurrentPage
    // errors and plugin changes while the page is not shown, for the badge of its tab
    property int numErrors: 0

    // [{name, status, cmdline, visible, ...}] from /process/get_list
    property var processes: []
    // name -> status, from proc_status
    property var processStates: ({})
    property var plugins: []
    // name -> state, from the plugin stats
    property var pluginStates: ({})
    property bool showAll: false
    readonly property var shownProcesses: processes.filter(p => showAll || p.visible)
    readonly property var consoleSources: ["all"].concat(processes.map(p => p.name))

    function refreshProcesses() {
        client.doRequest('GET', '/process/get_list', '', (msg) => root.processes = msg)
    }

    function refreshPlugins(quiet) {
        client.doRequest('GET', '/plugin/get_list', '', (msg) => root.plugins = msg.plugins, quiet)
    }

    function processCmd(name, cmd, options) {
        client.doRequest('PUT', `/process/${name}/command/${cmd}`,
                         JSON.stringify({ name: name, cmd: cmd, options: options }), (msg) => {})
    }

    function pluginCmd(name, cmd) {
        client.doRequest('PUT', `/plugin/${name}/command/${cmd}`, '', (msg) => {})
    }

    function refresh() {
        refreshProcesses()
        refreshPlugins(true)
    }

    Component.onCompleted: if (client.isConnected) refresh()

    Connections {
        target: root.client

        function onIsConnectedChanged() {
            if (root.client.isConnected) {
                root.refresh()
            }
        }

        function onObjectReceived(msg) {
            if (msg.type === "proc_status" && root.processStates[msg.name] !== msg.status) {
                root.processStates = Object.assign({}, root.processStates, { [msg.name]: msg.status })
            }
        }

        function onPluginStatMessageReceived(msg) {
            let changed = root.plugins.filter(n => (msg[n]?.state ?? "") !== (root.pluginStates[n] ?? ""))
            if (changed.length === 0) {
                return
            }
            root.numErrors += changed.length
            // no Object.fromEntries in the QML JavaScript engine
            let states = {}
            for (let n of root.plugins) {
                states[n] = msg[n]?.state ?? ""
            }
            root.pluginStates = states
        }

        function onProcessOutputReceived(msg) {
            if (msg.out.length > 0) {
                log.append(RstLog.Info, msg.name, msg.out)
            }
            if (msg.err.length > 0) {
                log.append(RstLog.Err, msg.name, msg.err)
                root.numErrors += 1
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ScrollView {
            id: listScroll
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(760, root.width * 0.45)
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                width: listScroll.availableWidth
                spacing: 16

                RstPanel {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        spacing: 12

                        RstKicker {
                            Layout.fillWidth: true
                            text: "PROCESSES"
                            detail: root.shownProcesses.length
                        }

                        Switch {
                            text: "show all"
                            checked: root.showAll
                            onToggled: root.showAll = checked
                        }

                        RefreshButton {
                            onClicked: root.refreshProcesses()
                        }
                    }

                    Repeater {
                        model: root.shownProcesses

                        StatusRow {
                            id: processRow
                            required property var modelData
                            Layout.fillWidth: true
                            name: modelData.name
                            status: root.processStates[modelData.name] ?? modelData.status
                            kind: "process"
                            active: status === "Running" || status === "Waiting"
                            hasConsole: true
                            onShowConsole: log.source = modelData.name
                            onStart: {
                                options.applySettings()
                                root.processCmd(modelData.name, "start", options.options)
                            }
                            onStop: root.processCmd(modelData.name, "stop", {})

                            ConfigurePanel {
                                id: options
                                Layout.fillWidth: true
                                enabled: !processRow.active
                                description: processRow.modelData.cmdline
                            }

                            RstButton {
                                Layout.fillWidth: true
                                kind: RstButton.Destructive
                                text: "Kill"
                                iconText: Robosintesi.symbols.stopCircle
                                onClicked: root.processCmd(processRow.modelData.name, "kill", {})
                            }
                        }
                    }
                }

                RstPanel {
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 8
                        spacing: 12

                        RstKicker {
                            Layout.fillWidth: true
                            text: "PLUGINS"
                            detail: `${root.plugins.filter(n => root.pluginStates[n] === "Running").length} running`
                        }

                        RefreshButton {
                            onClicked: root.refreshPlugins(false)
                        }
                    }

                    Repeater {
                        model: root.plugins

                        StatusRow {
                            id: pluginRow
                            required property string modelData
                            Layout.fillWidth: true
                            enabled: status !== "" && status !== "InitFailed"
                            name: modelData
                            status: root.pluginStates[modelData] ?? ""
                            kind: "plugin"
                            active: status === "Running" || status === "Starting"
                            onStart: root.pluginCmd(modelData, "start")
                            onStop: root.pluginCmd(modelData, "stop")

                            RstButton {
                                Layout.fillWidth: true
                                kind: RstButton.Destructive
                                text: "Abort"
                                iconText: Robosintesi.symbols.stopCircle
                                onClicked: root.pluginCmd(pluginRow.modelData, "abort")
                            }
                        }
                    }
                }
            }
        }

        RstPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                RstKicker {
                    Layout.fillWidth: false
                    text: "CONSOLE"
                    detail: `${log.count} lines`
                }

                // one item per process: it scrolls when they do not fit
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: sourceFilter.implicitHeight
                    contentWidth: sourceFilter.implicitWidth
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    RstSegmented {
                        id: sourceFilter
                        model: root.consoleSources
                        currentIndex: Math.max(0, root.consoleSources.indexOf(log.source))
                        onActivated: index => log.source = index === 0 ? "" : root.consoleSources[index]
                    }
                }

                RstIconButton {
                    iconText: MaterialSymbolNames.copy
                    onClicked: log.copy()
                }

                RstIconButton {
                    iconText: Robosintesi.symbols.deleteSweep
                    onClicked: log.clear()
                }

                RstIconButton {
                    iconText: MaterialSymbolNames.tune
                    onClicked: log.showSettings()
                }
            }

            RstLog {
                id: log
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 16
            }
        }
    }

    // labeled tonal chip of 11a
    component RefreshButton: RstButton {
        implicitHeight: 40
        leftPadding: 12
        rightPadding: 16
        spacing: 6
        kind: RstButton.Secondary
        text: "Refresh"
        iconText: Robosintesi.symbols.refresh
        iconSize: 20
        font.pixelSize: 14
    }

    // a process or a plugin: state, console, settings (the children go in its popup), start/stop
    component StatusRow: Rectangle {
        id: statusRow

        property string name
        property string status
        // "process" or "plugin"
        property string kind
        // stop instead of start
        property bool active: false
        property bool hasConsole: false
        default property alias settingsContent: settingsColumn.data

        signal start()
        signal stop()
        signal showConsole()

        readonly property bool failed: ["Killed", "Aborted", "InitFailed", "Killing", "Stopping"].includes(status)
        readonly property bool changing: ["Waiting", "Starting", "Killing", "Stopping"].includes(status)
        readonly property color tint: failed ? Robosintesi.status.err
                                             : active ? Robosintesi.status.ok : Qt.alpha(Robosintesi.colors.text, 0.3)

        implicitHeight: 88
        radius: Robosintesi.geom.radius
        color: Qt.alpha(Robosintesi.colors.background, 0.45)
        opacity: enabled ? 1 : Robosintesi.geom.disabledOpacity

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 16
            spacing: 12

            Rectangle {
                implicitWidth: 12
                implicitHeight: 12
                radius: 6
                color: statusRow.tint

                // ends on opacity 1 when it stops
                SequentialAnimation on opacity {
                    running: statusRow.changing
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    NumberAnimation { to: 0.3; duration: 555; easing.type: Easing.OutSine }
                    NumberAnimation { to: 1; duration: 555; easing.type: Easing.InSine }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    text: statusRow.name
                    elide: Text.ElideRight
                    font.family: Robosintesi.fonts.headline.font.family
                    font.pixelSize: 20
                    color: Robosintesi.colors.text
                }

                Label {
                    Layout.fillWidth: true
                    text: `${(statusRow.status || "unknown").toLowerCase()} · ${statusRow.kind}`
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    color: statusRow.failed ? Robosintesi.status.err
                                            : statusRow.active ? Robosintesi.status.ok : Robosintesi.colors.textSecondary
                }
            }

            RowButton {
                visible: statusRow.hasConsole
                iconText: Robosintesi.symbols.article
                onClicked: statusRow.showConsole()
            }

            RowButton {
                iconText: MaterialSymbolNames.tune
                onClicked: settingsPopup.open()
            }

            RstButton {
                kind: statusRow.active ? RstButton.Destructive : RstButton.Primary
                text: statusRow.active ? "Stop" : "Start"
                iconText: statusRow.active ? MaterialSymbolNames.stop : MaterialSymbolNames.play
                onClicked: statusRow.active ? statusRow.stop() : statusRow.start()
            }
        }

        Popup {
            id: settingsPopup
            x: statusRow.width - width - 16
            y: statusRow.height + 4
            width: Math.min(480, statusRow.width)

            contentItem: ColumnLayout {
                id: settingsColumn
                spacing: 16

                RstKicker {
                    text: statusRow.name.toUpperCase()
                }
            }
        }
    }

    component RowButton: RstIconButton {
        Layout.preferredWidth: 56
        Layout.preferredHeight: 56
    }
}
