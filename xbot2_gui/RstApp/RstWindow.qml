import QtQuick
import QtCore
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material as M

import Common
import Rst
import Menu
import Font
import Audio
import Monitoring
import Main

ApplicationWindow {
    id: mainWindow
    width: 1280
    height: 720
    visible: true
    color: Robosintesi.colors.background
    title: Qt.application.name
    visibility: Qt.platform.os === "android" ? Window.FullScreen : Window.AutomaticVisibility

    property bool dbg: false

    // set by the app; the first page is the one shown at start
    property list<PageItem> pages
    property alias client: client

    font.family: Robosintesi.fonts.body.font.family

    // the Material controls and the fork's components (CommonProperties) get the Robosintesi values
    M.Material.accent: Robosintesi.colors.accent
    M.Material.primary: Robosintesi.colors.foreground
    M.Material.background: Robosintesi.colors.background
    M.Material.foreground: Robosintesi.colors.text
    Binding { target: CommonProperties.colors; property: "ok"; value: Robosintesi.status.ok }
    Binding { target: CommonProperties.colors; property: "warn"; value: Robosintesi.status.warn }
    Binding { target: CommonProperties.colors; property: "err"; value: Robosintesi.status.err }
    Binding { target: CommonProperties.geom; property: "cardRadius"; value: Robosintesi.geom.radius }

    palette {
        active {
            highlight: Robosintesi.colors.text
            highlightedText: Robosintesi.colors.background
            buttonText: Robosintesi.colors.text
            text: Robosintesi.colors.foreground
            accent: Robosintesi.colors.text
            window: Robosintesi.colors.background
        }
        inactive {
            highlight: Robosintesi.colors.text
            highlightedText: Robosintesi.colors.background
            buttonText: Robosintesi.colors.text
            text: Robosintesi.colors.foreground
            accent: Robosintesi.colors.text
            window: Robosintesi.colors.background
        }
        disabled {
            window: Qt.lighter(Robosintesi.colors.background)
            buttonText: Robosintesi.colors.text
        }
    }

    // page tab of the top bar, created by the NavRailWrapper
    Component {
        id: tabComponent

        AbstractButton {
            id: tab

            property string iconChar
            property int index
            property int badgeNum: 0
            // set by the NavRailWrapper, not used here
            property url iconSource
            property real sizeFactor: 1.0

            readonly property bool selected: tabs.currentIndex === index
            readonly property color tint: selected ? Robosintesi.colors.background : Robosintesi.colors.text

            implicitWidth: implicitContentWidth + leftPadding + rightPadding
            implicitHeight: 48
            leftPadding: 18
            rightPadding: 18
            opacity: enabled ? 1 : Robosintesi.geom.disabledOpacity

            onClicked: tabs.currentIndex = index

            background: Rectangle {
                radius: 14
                color: tab.selected ? Robosintesi.colors.text : "transparent"
            }

            contentItem: RowLayout {
                spacing: 8

                RstIcon {
                    text: tab.iconChar
                    size: 22
                    color: tab.tint
                }

                Label {
                    text: tab.text
                    font.pixelSize: 15
                    font.bold: tab.selected
                    color: tab.tint
                }
            }

            // errors on a page that is not shown
            Rectangle {
                visible: tab.badgeNum > 0
                anchors { top: parent.top; right: parent.right; margins: 6 }
                width: 8
                height: 8
                radius: 4
                color: Robosintesi.status.err
            }
        }
    }

    header: ToolBar {
        id: header
        height: 72
        width: parent.width

        background: Rectangle {
            color: Robosintesi.colors.background

            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 1
                color: Qt.alpha(Robosintesi.colors.text, 0.12)
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            spacing: 20

            Image {
                Layout.preferredHeight: 26
                Layout.preferredWidth: 26 * implicitWidth / Math.max(1, implicitHeight)
                fillMode: Image.PreserveAspectFit
                source: Robosintesi.logos.logotypeCoolGray
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 48

                NavRailWrapper {
                    id: tabs
                    anchors.fill: parent
                    orientation: Qt.Horizontal
                    barButtonComponent: tabComponent
                    model: pagesModel
                }
            }

            RstPill {
                compact: true
                tint: client.isConnected ? Robosintesi.status.ok : Robosintesi.status.err
                iconText: client.isConnected ? Robosintesi.symbols.wifiConnected : Robosintesi.symbols.wifiDisconnected
                label: client.isConnected ? "server connected" : "server disconnected"

                HoverHandler { id: connectionHover }
                ToolTip.visible: connectionHover.hovered
                ToolTip.text: client.isConnected
                              ? "Server connected (%1:%2)".arg(client.hostname).arg(client.port)
                              : "Server disconnected"
            }
        }
    }

    // only the Robosintesi ideogram
    footer: ToolBar {
        height: 72
        width: parent.width

        background: Rectangle {
            color: Robosintesi.colors.background

            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: 1
                color: Qt.alpha(Robosintesi.colors.text, 0.12)
            }
        }

        Image {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            height: 40
            width: height * implicitWidth / Math.max(1, implicitHeight)
            fillMode: Image.PreserveAspectFit
            source: Robosintesi.logos.ideogramCoolGray
        }
    }

    Component.onCompleted: {
        appData.keepScreenOn(true)
    }

    LayoutClassHelper {
        id: layout
        targetWidth: mainWindow.width
    }

    MaterialSymbols { id: syms }

    // pages of the app, shown by the tabs and by pagesStack
    Item {
        id: pagesModel
        visible: false
        children: mainWindow.pages
    }

    ClientEndpoint {
        id: client
        onObjectReceived: function(obj) {
            if(obj.type === 'server_log') {
                CommonProperties.notifications.message(obj.txt, 'webserver', obj.severity)
            }
        }
    }

    Settings {
        category: 'layout'
        property alias x: mainWindow.x
        property alias y: mainWindow.y
        property alias width: mainWindow.width
        property alias height: mainWindow.height
    }

    Connections {
        target: AudioBroadcaster
        function onReadyRead() {
            if(AudioBroadcaster.bytesAvailable < 2048 || !AudioBroadcaster.enableSend) return
            let data = AudioBroadcaster.readBase64(2048)
            let msg = { 'type': 'speech', 'data': data }
            client.sendTextMessage(JSON.stringify(msg))
        }
    }

    // warnings and errors for 3 s over every page, as the notification popup of IIT's main.qml
    Rectangle {
        id: toast

        property bool shown: false

        function show(level, source, message) {
            toastLog.append(level, source, message)
            shown = true
            toastTimer.restart()
        }

        z: 300
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(720, parent.width - 48)
        height: Math.min(parent.height / 2, toastLog.contentHeight + 2 * toastLog.padding)
        y: shown ? parent.height - height - 24 : parent.height
        visible: y < parent.height
        radius: Robosintesi.geom.radius
        color: Robosintesi.colors.panel
        border.color: Qt.alpha(Robosintesi.colors.text, 0.14)

        Behavior on y {
            SequentialAnimation {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                ScriptAction { script: if (!toast.shown) toastLog.clear() }
            }
        }

        RstLog {
            id: toastLog
            anchors.fill: parent
            color: "transparent"
            textFormat: Text.StyledText
        }

        TapHandler {
            onTapped: toast.shown = false
        }

        Timer {
            id: toastTimer
            interval: 3000
            onTriggered: toast.shown = false
        }

        Connections {
            target: CommonProperties.notifications

            function onNewWarning(txt, name) {
                toast.show(RstLog.Warn, name, txt)
            }

            function onNewError(txt, name) {
                toast.show(RstLog.Err, name, txt)
            }
        }
    }

    // the pages, under the tabs
    Item {
        anchors.fill: parent

        SoftSafetyButton {
            id: softEmergency
            client: client
            visible: CommonProperties.config.showSoftEmergency
            anchors { right: parent.right; bottom: parent.bottom; margins: 16 }
            z: 200; width: 70; height: 70; opacity: 0.8
        }

        MonWidget {
            expanded: layout.expanded
            anchors { left: parent.left; top: parent.top; margins: 8 }
            z: 200; opacity: 0.8
            visible: CommonProperties.config.showMonWidget
            width: expanded ? 94 : implicitWidth
        }

        StackLayout {
            id: pagesStack

            property int previousIndex: -1
            anchors.fill: parent
            anchors.margins: 24
            currentIndex: tabs.currentIndex

            onCurrentIndexChanged: {
                try { itemAt(previousIndex).item.isCurrentPage = false } catch(err){}
                previousIndex = currentIndex
                try { itemAt(currentIndex).item.numErrors = 0 } catch(err){}
                try { itemAt(currentIndex).item.pageSelected() } catch(err){}
                try { itemAt(currentIndex).item.isCurrentPage = true } catch(err){}
                tabs.setBadgeNumber(currentIndex, 0)
            }

            Repeater {
                id: pagesStackRepeater
                function reloadAll() {
                    for(let i = 0; i < count; i++) {
                        let ch = itemAt(i); if(ch.active) { ch.active = false; ch.active = true }
                    }
                }
                model: pagesModel.children

                // a page loads the first time it is shown, or at start with lazyLoad: false
                Loader {
                    id: stackPageLoader
                    Layout.fillHeight: true; Layout.fillWidth: true
                    active: !modelData.lazyLoad || pagesStack.currentIndex === index
                    onLoaded: {
                        active = true
                        try { item.isCurrentPage = pagesStack.currentIndex === index } catch(err){}
                    }
                    Component.onCompleted: setSource(modelData.page, {'client': client})
                    Connections {
                        target: stackPageLoader.item
                        ignoreUnknownSignals: true
                        function onRestartUi() { pagesStackRepeater.reloadAll() }
                        function onNumErrorsChanged() {
                            if(index !== pagesStack.currentIndex) tabs.setBadgeNumber(index, stackPageLoader.item.numErrors)
                            else item.numErrors = 0
                        }
                    }
                }
            }
        }
    }
}
