import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

import Common
import Font
import Home
import Main
import Rst

// Network page: server, link and statistics | server log
Item {
    id: root

    property ClientEndpoint client
    property bool isCurrentPage
    // warnings and errors while the page is not shown, for the badge of its tab
    property int numErrors: 0

    property string serverVersion: "—"

    // link statistics, from the counters of the client every 2 s (as Home/ServerStatusCard)
    property real rxKbps: 0
    property real txKbps: 0
    property real telemetryHz: 0
    property real droppedHz: 0
    // last 60 s: [rx, tx] in kbps (rate) and in kB since the start (total)
    readonly property int historyLength: 30
    property var rateHistory: []
    property var totalHistory: []
    property int statsMode: 0

    function connectToServer() {
        client.hostname = hostField.text
        client.port = parseInt(portField.text)
        client.autoConnect = true
        client.active = true
    }

    function disconnectFromServer() {
        client.autoConnect = false
        client.active = false
    }

    function fetchVersion() {
        client.doRequestAsync('GET', '/version', '')
        .then((res) => root.serverVersion = res.version)
        .catch(() => {})
    }

    Component.onCompleted: if (client.isConnected) fetchVersion()

    Connections {
        target: root.client

        function onIsConnectedChanged() {
            if (root.client.isConnected) {
                root.fetchVersion()
            }
        }
    }

    Connections {
        target: CommonProperties.notifications

        function onNewInfo(txt, name) {
            log.append(RstLog.Info, name, txt)
        }

        function onNewWarning(txt, name) {
            log.append(RstLog.Warn, name, txt)
            root.numErrors += 1
        }

        function onNewError(txt, name) {
            log.append(RstLog.Err, name, txt)
            root.numErrors += 1
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true

        property real lastRx: 0
        property real lastTx: 0
        property int lastTelemetry: 0
        property int lastDropped: 0

        onTriggered: {
            let c = root.client
            // the client resets bytesSent at each connection
            root.rxKbps = Math.max(0, c.bytesRecv - lastRx) / interval * 8
            root.txKbps = Math.max(0, c.bytesSent - lastTx) / interval * 8
            root.telemetryHz = (c.jsMsgRecv - lastTelemetry) / interval * 1000
            root.droppedHz = (c.jsDropped - lastDropped) / interval * 1000
            lastRx = c.bytesRecv
            lastTx = c.bytesSent
            lastTelemetry = c.jsMsgRecv
            lastDropped = c.jsDropped
            root.rateHistory = root.rateHistory.concat([[root.rxKbps, root.txKbps]]).slice(-root.historyLength)
            root.totalHistory = root.totalHistory.concat([[c.bytesRecv / 1024, c.bytesSent / 1024]]).slice(-root.historyLength)
        }
    }

    Timer {
        id: delayedConnect
        interval: 3000
        onTriggered: root.connectToServer()
    }

    Popup {
        id: configPopup
        anchors.centerIn: Overlay.overlay
        width: Overlay.overlay.width * 0.8
        height: Overlay.overlay.height * 0.8
        modal: true
        focus: true

        Configuration {
            anchors.fill: parent
            onClosed: configPopup.close()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(760, root.width * 0.45)
            spacing: 16

            RstPanel {
                Layout.fillWidth: true
                spacing: 20

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RstKicker {
                            text: "SERVER"
                        }

                        Label {
                            Layout.fillWidth: true
                            text: `${root.client.hostname}:${root.client.port}`
                            elide: Text.ElideRight
                            font.family: Robosintesi.fonts.headline.font.family
                            font.pixelSize: 34
                            font.letterSpacing: 1
                            color: Robosintesi.colors.text
                        }

                        Label {
                            text: `server ${root.serverVersion} · client ${Qt.application.name} ${appData.version.join('.')}`
                            font.pixelSize: 14
                            color: Robosintesi.colors.textSecondary
                        }
                    }

                    RstPill {
                        Layout.alignment: Qt.AlignTop
                        implicitHeight: 32
                        padding: 12
                        gap: 6
                        iconSize: 16
                        fontSize: 13
                        tint: root.client.isConnected ? Robosintesi.status.ok : Robosintesi.colors.textSecondary
                        iconText: root.client.isConnected ? Robosintesi.symbols.check : Robosintesi.symbols.radioUnchecked
                        label: root.client.isConnected ? "connected" : root.client.autoConnect ? "connecting" : "disconnected"
                    }

                    RstIconButton {
                        Layout.alignment: Qt.AlignTop
                        iconText: MaterialSymbolNames.tune
                        onClicked: configPopup.open()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Field {
                        id: hostField
                        Layout.preferredWidth: 2
                        label: "host"
                        text: root.client.hostname
                        onAccepted: root.connectToServer()
                    }

                    Field {
                        id: portField
                        Layout.preferredWidth: 1
                        label: "port"
                        text: root.client.port
                        onAccepted: root.connectToServer()
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RstButton {
                        readonly property bool connected: root.client.isConnected

                        Layout.fillWidth: true
                        Layout.preferredWidth: 2
                        Layout.preferredHeight: 64
                        kind: connected ? RstButton.Secondary : RstButton.Primary
                        text: connected ? "Disconnect" : "Connect"
                        iconText: connected ? Robosintesi.symbols.linkOff : Robosintesi.symbols.link
                        onClicked: connected ? root.disconnectFromServer() : root.connectToServer()
                    }

                    RstButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 64
                        kind: RstButton.Secondary
                        text: "Reset"
                        iconText: Robosintesi.symbols.restart
                        onClicked: {
                            root.client.doRequest('POST', '/restart', '')
                            delayedConnect.restart()
                        }
                    }
                }
            }

            RstPanel {
                Layout.fillWidth: true
                spacing: 20

                RstKicker {
                    text: "LINK"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 8

                    LinkTile {
                        label: "ping"
                        value: root.client.srvRtt.toFixed(1)
                        unit: "ms"
                    }

                    LinkTile {
                        label: "telemetry"
                        value: root.telemetryHz.toFixed(0)
                        unit: "Hz"
                        detail: `${root.droppedHz.toFixed(0)} dropped`
                        detailColor: root.droppedHz > 0 ? Robosintesi.status.warn : Robosintesi.status.ok
                    }

                    LinkTile {
                        label: "data rx"
                        value: root.rxKbps.toFixed(1)
                        unit: "kbps"
                    }

                    LinkTile {
                        label: "data tx"
                        value: root.txKbps.toFixed(1)
                        unit: "kbps"
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
                        Layout.fillWidth: true
                        text: "NETWORK STATISTICS"
                        detail: "last 60 s"
                    }

                    RstSegmented {
                        model: ["rate", "total"]
                        currentIndex: root.statsMode
                        onActivated: index => root.statsMode = index
                    }
                }

                RowLayout {
                    spacing: 20

                    Repeater {
                        model: [["rx", Robosintesi.colors.text], ["tx", Robosintesi.status.negative]]

                        RowLayout {
                            required property var modelData
                            spacing: 6

                            Rectangle {
                                implicitWidth: 14
                                implicitHeight: 3
                                radius: 2
                                color: parent.modelData[1]
                            }

                            Label {
                                text: parent.modelData[0]
                                font.pixelSize: 13
                                color: Robosintesi.colors.textSecondary
                            }
                        }
                    }
                }

                Rectangle {
                    id: chart

                    readonly property var history: root.statsMode === 0 ? root.rateHistory : root.totalHistory
                    readonly property real maxValue: Math.max(1, ...history.map(s => Math.max(s[0], s[1]))) * 1.1

                    // series n of the history as points of the plot, the newest on the right
                    function points(n) {
                        let w = plot.width
                        let h = plot.height
                        let first = root.historyLength - history.length
                        return history.map((s, i) => Qt.point((first + i) / (root.historyLength - 1) * w,
                                                              h - s[n] / maxValue * h))
                    }

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 120
                    radius: 12
                    color: Qt.alpha(Robosintesi.colors.background, 0.45)

                    Item {
                        id: plot
                        anchors.fill: parent
                        anchors.margins: 16

                        Repeater {
                            model: 4

                            Rectangle {
                                required property int index
                                y: index * (plot.height - 1) / 3
                                width: plot.width
                                height: 1
                                color: Qt.alpha(Robosintesi.colors.text, 0.08)
                            }
                        }

                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer

                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: Robosintesi.colors.text
                                strokeWidth: 2.5
                                PathPolyline { path: chart.points(0) }
                            }

                            ShapePath {
                                fillColor: "transparent"
                                strokeColor: Robosintesi.status.negative
                                strokeWidth: 2.5
                                PathPolyline { path: chart.points(1) }
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
                    Layout.fillWidth: true
                    text: "SERVER LOG"
                    detail: `${log.count} lines`
                }

                Switch {
                    text: "verbose"
                    checked: log.minLevel === RstLog.Info
                    onToggled: log.minLevel = checked ? RstLog.Info : RstLog.Warn
                }

                Switch {
                    text: "autoscroll"
                    checked: log.autoscroll
                    onToggled: log.autoscroll = checked
                }

                RstIconButton {
                    iconText: MaterialSymbolNames.copy
                    onClicked: log.copy()
                }

                RstIconButton {
                    iconText: Robosintesi.symbols.deleteSweep
                    onClicked: log.clear()
                }
            }

            RstLog {
                id: log
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 16
                showSource: false
                minLevel: RstLog.Warn
                textFormat: Text.StyledText
            }
        }
    }

    component LinkTile: RstReadout {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: 104
        kicker: false
        valueSize: 32
    }

    component Field: ColumnLayout {
        id: field

        property alias label: fieldLabel.text
        property alias text: input.text

        signal accepted()

        Layout.fillWidth: true
        spacing: 8

        Label {
            id: fieldLabel
            font.pixelSize: 13
            color: Robosintesi.colors.textSecondary
        }

        TextField {
            id: input
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            leftPadding: 16
            rightPadding: 16
            topPadding: 0
            bottomPadding: 0
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 18
            color: Robosintesi.colors.text
            onAccepted: field.accepted()

            background: Rectangle {
                radius: 12
                color: Qt.alpha(Robosintesi.colors.background, 0.6)
                border.color: Qt.alpha(Robosintesi.colors.text, 0.2)
                border.width: 1
            }
        }
    }
}
