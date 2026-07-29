import QtQuick
import QtCore
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

import Common
import Menu
import Font
import Audio
import Monitoring
import Home
import Launcher

ApplicationWindow {
    id: mainWindow
    width: 1280
    height: 720
    visible: true
    color: Robosintesi.colors.background
    title: "robosintesi GUI"
    visibility: Qt.platform.os === "android" ? Window.FullScreen : Window.AutomaticVisibility

    property bool dbg: false

    readonly property bool isAppRunning: rootStack.depth > 1

    readonly property string footerTitle: {
        let it = rootStack.currentItem
        return it && it.footerTitle !== undefined ? it.footerTitle : ""
    }

    font.family: CommonProperties.robosintesiFont.headline.font.family

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

    header: ToolBar {
        id: header
        height: 120
        width: parent.width

        background: Rectangle {
            color: Robosintesi.colors.background
        }

        Image {
            id: headerLogo
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: CommonProperties.geom.margins
            anchors.bottom: parent.bottom
            anchors.bottomMargin: CommonProperties.geom.margins
            autoTransform: true
            fillMode: Image.PreserveAspectFit
            source: Robosintesi.icons.logotipoCoolGray
        }

        Label {
            id: connectionIcon
            anchors.right: parent.right
            anchors.rightMargin: CommonProperties.geom.margins
            anchors.verticalCenter: headerLogo.verticalCenter
            text: client.isConnected ? MaterialSymbolNames.wifiConnected : MaterialSymbolNames.wifiDisconnected
            font.family: 'Material Symbols Outlined'
            font.pixelSize: 32
            color: client.isConnected ? Robosintesi.colors.text : Robosintesi.colors.error
            opacity: client.isConnected ? 0.7 : 1.0

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }

            ToolTip.visible: connectionMouse.containsMouse
            ToolTip.text: client.isConnected
                          ? "Server connected (%1:%2)".arg(client.hostname).arg(client.port)
                          : "Server disconnected"

            MouseArea {
                id: connectionMouse
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
            }
        }
    }

    footer: ToolBar {
        // sourceComponent: isAppRunning ? appFooter : bootFooter
        id: footer
        height: 120
        width: parent.width

        background: Rectangle {
            color: Robosintesi.colors.background
        }

        Column {
            id: footerAnimeMark
            anchors.left: parent.left
            anchors.leftMargin: CommonProperties.geom.margins
            anchors.bottom: parent.bottom
            anchors.bottomMargin: CommonProperties.geom.margins
            spacing: 0

            Label {
                text: 'AN<font color="' + Robosintesi.colors.ok + '">i</font>ME'
                textFormat: Text.StyledText
                font.family: CommonProperties.robosintesiFont.headline.font.family
                font.pixelSize: 54
                font.bold: true
                font.letterSpacing: 2.5
                color: Robosintesi.colors.text
            }

            Label {
                text: mainWindow.footerTitle
                font.family: CommonProperties.robosintesiFont.body.font.family
                font.pixelSize: 13
                font.letterSpacing: 7
                color: Robosintesi.colors.text
                opacity: 0.55
            }
        }

        Image {
            id: footerLogo
            anchors.right: parent.right
            anchors.rightMargin: CommonProperties.geom.margins
            anchors.verticalCenter: footerAnimeMark.verticalCenter
            height: footerAnimeMark.height
            autoTransform: true
            fillMode: Image.PreserveAspectFit
            source: Robosintesi.icons.ideogrammaCoolGray
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
    property var items: Object()

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

    StackView {
        id: rootStack
        anchors.fill: parent
        initialItem: bootComponent
        pushEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 200 } }
        pushExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 200 } }
    }

    Component {
        id: bootComponent
        Item {
            anchors.fill: parent

            property string footerTitle: "MAIN PAGE"

            RowLayout {
                anchors.fill: parent
                anchors.margins: CommonProperties.geom.margins
                spacing: CommonProperties.geom.spacing

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: CommonProperties.geom.spacing

                        Button {
                            Layout.preferredWidth: 440
                            Layout.preferredHeight: 140
                            Layout.alignment: Qt.AlignHCenter
                            text: "start"
                            font.pixelSize: 60
                            font.letterSpacing: 2
                            font.bold: true

                            background: Rectangle {
                                color: Robosintesi.colors.text
                                radius: CommonProperties.geom.defaultRadius
                                border.color: Robosintesi.colors.text
                                border.width: 1
                            }

                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: Robosintesi.colors.background
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                bootConsoleItem.appendText('launcher', '<font color="#22E3A4">[BOOT] Starting application...</font>', false)
                                rootStack.push(appComponent)
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 0

                            Button {
                                width: parent.width
                                height: 44
                                flat: true

                                contentItem: RowLayout {
                                    spacing: 8
                                    Label {
                                        text: MaterialSymbolNames.advancedSettings
                                        font.family:'Material Symbols Outlined'
                                        font.pixelSize: CommonProperties.font.h1
                                    }
                                    Label {
                                        text: "advanced settings"
                                        font.pixelSize: CommonProperties.font.h1
                                        Layout.fillWidth: true
                                    }
                                }

                                onClicked: rootStack.push(advancedSettingsComponent)
                            }

                        }


                        Column {
                            Layout.fillWidth: true
                            spacing: 0

                            Button {
                                width: parent.width
                                height: 44
                                flat: true

                                contentItem: RowLayout {
                                    spacing: 8
                                    Label {
                                        text: MaterialSymbolNames.networkSettings
                                        font.family: 'Material Symbols Outlined'
                                        font.pixelSize: CommonProperties.font.h1
                                    }
                                    Label {
                                        text: "network settings"
                                        font.pixelSize: CommonProperties.font.h1
                                        Layout.fillWidth: true
                                    }
                                }

                               onClicked: rootStack.push(networkSettingsComponent)
                            }

                        }
                    }
                }


                LauncherConsoleItem {
                    id: bootConsoleItem
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                }
            }

            Component {
                id: networkSettingsComponent
                Item {
                    anchors.fill: parent

                    property string footerTitle: "NETWORK SETTINGS"

                    RstIconButton {
                        id: exitNetworkSettings

                        anchors.top: parent.top
                        anchors.right: parent.right
                        iconText: MaterialSymbolNames.goBack
                        onClicked: rootStack.pop()
                    }

                    Loader {
                        anchors.top: exitNetworkSettings.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: CommonProperties.geom.margins

                        Component.onCompleted: {
                            setSource("/qt/qml/Home/HelloScreen.qml", {'client': client})
                        }
                    }
                }

            }

            Component {
                id: advancedSettingsComponent
                Item {
                    id: advancedSettings

                    property string footerTitle: "ADVANCED SETTINGS"

                    RstIconButton {
                        id: exitAdvancedSettings

                        anchors.top: parent.top
                        anchors.right: parent.right
                        iconText: MaterialSymbolNames.goBack
                        onClicked: rootStack.pop()
                    }

                Loader {
                        anchors.top: exitAdvancedSettings.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: CommonProperties.geom.margins

                        Component.onCompleted: {
                            setSource("/qt/qml/Launcher/Launcher.qml", {'client': client})
                        }
                    }
                }
            }

            Connections {
                            target: client

                            function onProcessOutputReceived(msg) {
                                bootConsoleItem.appendText(msg.name, msg.out, false)
                                if(msg.err.length > 0) {
                                    bootConsoleItem.appendText(msg.name,
                                        '<font color="' + CommonProperties.colors.err + '">' + msg.err + '</font>', false)
                                }
                            }

                            function onConnected(msg) {
                                bootConsoleItem.appendText('network',
                                    '<font color="' + CommonProperties.colors.ok + '">[NETWORK] ' + msg + '</font>', false)
                            }

                            function onError(msg) {
                                bootConsoleItem.appendText('network',
                                    '<font color="' + CommonProperties.colors.err + '">[NETWORK] ' + msg + '</font>', false)
                            }

                            function onIsConnectedChanged() {
                                if (!client.isConnected) {
                                    bootConsoleItem.appendText('network',
                                        '<font color="' + CommonProperties.colors.warn + '">[NETWORK] Disconnected, retrying...</font>', false)
                                }
                            }
                        }
        }
    }

    Component {
        id: appComponent

        Item {
            property string currentTitle: pagesStack.currentItem ? pagesStack.currentItem.item.pageName : "App"

            property string footerTitle: {
                let p = pagesModel.children[pagesStack.currentIndex]
                return p ? p.name.toUpperCase() : ""
            }

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

            // -- Pages --
            Item {
                id: pagesModel
                visible: false

                PageItem {
                    name: "Mission"
                    page: "/qt/qml/Anime/Anime.qml"
                    iconText: MaterialSymbolNames.robotArm
                    iconFont: syms.font.family
                    active: true
                    show: true
                }

                PageItem {
                    name: "Network"
                    page: "/qt/qml/Home/HelloScreen.qml"
                    iconText: MaterialSymbolNames.netSettings
                    iconFont: syms.font.family
                    active: true
                }
                PageItem {
                    name: "Process"
                    page: "/qt/qml/Launcher/Launcher.qml"
                    iconText: MaterialSymbolNames.terminal
                    iconFont: syms.font.family
                    active: client.isConnected || mainWindow.dbg
                }
                PageItem {
                    name: "Monitoring"
                    page: "/qt/qml/Monitoring/Monitoring.qml"
                    iconText: MaterialSymbolNames.gauge
                    iconFont: syms.font.family
                    active: client.robotConnected || mainWindow.dbg
                    lazyLoad: false
                }
                PageItem {
                    name: "Playground"
                    page: "/qt/qml/TestThings/Playground2.qml"
                    iconText: MaterialSymbolNames.playground
                    iconFont: syms.font.family
                    active: true
                    show: CommonProperties.config.testing
                }
                PageItem {
                    name: "Joy"
                    page: "/qt/qml/Joy/Joy.qml"
                    iconText: MaterialSymbolNames.joystick
                    iconFont: syms.font.family
                    active: false //client.robotConnected || mainWindow.dbg
                    show: false //requestedPages.indexOf(name) > -1
                }
                PageItem {
                    name: "App"
                    page: "/qt/qml/Main/AppLauncher.qml"
                    iconText: MaterialSymbolNames.apps
                    iconFont: syms.font.family
                    active: false //true
                    show: false //requestedPages.indexOf(name) > -1
                }
            }

            // -- NavRail (Sidebar Verticale) --
            NavRailWrapper {
                id: nav
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 8 }
                width: 80; z: 1
                model: pagesModel
                visible: layout.expanded
                onCurrentIndexChanged: navBar.currentIndex = currentIndex
                // onClicked: Qt.callLater(() => pagesStack.selectIndex(currentIndex))

                Component.onCompleted: construct() // Costruisci quando l'app viene caricata
            }

            // -- NavBar (Barra Orizzontale Mobile) --
            NavRailWrapper {
                id: navBar
                visible: !layout.expanded
                model: pagesModel
                sizeFactor: 1.25
                orientation: Qt.Horizontal
                uncheckedDisplayMode: AbstractButton.IconOnly
                checkedDisplayMode: AbstractButton.TextBesideIcon
                onCurrentIndexChanged: nav.currentIndex = currentIndex
                //onClicked: Qt.callLater(() => pagesStack.selectIndex(currentIndex))
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 8; leftMargin: CommonProperties.geom.margins; rightMargin: CommonProperties.geom.margins }

                Component.onCompleted: construct()
            }

            // -- Stack Principale Pagine --
            StackLayout {
                id: pagesStack

                // Funzione helper per esporre il titolo all'ApplicationWindow
                property var currentItem: children[currentIndex]

                function selectIndex(index) {
                    if(currentIndex === index) { try { itemAt(currentIndex).item.pageSelected() } catch(e){} }
                    currentIndex = index
                }

                property int previousIndex: -1
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: navBar.visible ? navBar.top : parent.bottom
                    left: nav.visible ? nav.right : parent.left
                    margins: 8; leftMargin: CommonProperties.geom.margins; rightMargin: CommonProperties.geom.margins
                }
                currentIndex: nav.currentIndex

                onCurrentIndexChanged: {
                    try { itemAt(previousIndex).item.isCurrentPage = false } catch(err){}
                    previousIndex = currentIndex
                    try { itemAt(currentIndex).item.numErrors = 0 } catch(err){}
                    try { itemAt(currentIndex).item.pageSelected() } catch(err){}
                    try { itemAt(currentIndex).item.isCurrentPage = true } catch(err){}
                    nav.setBadgeNumber(currentIndex, 0)
                }

                Repeater {
                    id: pagesStackRepeater
                    function reloadAll() {
                        for(let i = 0; i < count; i++) {
                            let ch = itemAt(i); if(ch.active) { ch.active = false; ch.active = true }
                        }
                    }
                    model: pagesModel.children

                    Loader {
                        id: stackPageLoader
                        Layout.fillHeight: true; Layout.fillWidth: true
                        property string pageName: ''
                        active: pagesStack.currentIndex === index
                        onStatusChanged: active = true
                        onLoaded: {
                            active = true
                            items[modelData.name.toLowerCase()] = item
                            try { item.isCurrentPage = true } catch(err){}
                            item.pageName = modelData.name
                            pageName = modelData.name
                        }
                        Component.onCompleted: setSource(modelData.page, {'client': client})
                        Connections {
                            target: stackPageLoader.item
                            ignoreUnknownSignals: true
                            function onRestartUi() { pagesStackRepeater.reloadAll() }
                            function onNumErrorsChanged() {
                                if(index !== pagesStack.currentIndex) nav.setBadgeNumber(index, stackPageLoader.item.numErrors)
                                else item.numErrors = 0
                            }
                        }
                    }
                }
            }
        }
    }
}
