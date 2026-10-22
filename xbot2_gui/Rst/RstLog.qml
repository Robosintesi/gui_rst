import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

// log lines: time · level · source · message, filtered by source and by level
Rectangle {
    id: root

    enum Level { Info, Ok, Warn, Err }

    // "" shows every source
    property string source: ""
    property int minLevel: RstLog.Info
    property bool showSource: true
    property bool autoscroll: true
    property int fontSize: 14
    // StyledText for the notifications, which can have <b>; PlainText for the process output
    property int textFormat: Text.PlainText
    // the oldest lines go away beyond this
    property int maxLines: 5000
    property int padding: 12
    // the sources seen so far, in order
    property var sources: []
    readonly property alias count: shown.count
    readonly property alias contentHeight: view.contentHeight

    readonly property font cellFont: Qt.font({ family: Robosintesi.fonts.body.font.family,
                                                pixelSize: fontSize, features: { "tnum": 1 } })
    readonly property var levelNames: ["INFO", "OK", "WARN", "ERR"]
    readonly property var levelColors: [Robosintesi.colors.textSecondary, Robosintesi.status.ok,
                                        Robosintesi.status.warn, Robosintesi.status.err]

    function append(level, source, message) {
        let line = {
            time: new Date().toLocaleTimeString(Qt.locale("C"), "hh:mm:ss.zzz"),
            level: level,
            source: source,
            message: message
        }
        all.append(line)
        if (all.count > maxLines) {
            all.remove(0)
        }
        if (!sources.includes(source)) {
            sources = sources.concat([source])
        }
        if (!accepts(line)) {
            return
        }
        shown.append(line)
        if (shown.count > maxLines) {
            shown.remove(0)
        }
        if (autoscroll) {
            Qt.callLater(view.positionViewAtEnd)
        }
    }

    // clears the lines that are shown
    function clear() {
        for (let i = all.count - 1; i >= 0; i--) {
            if (accepts(all.get(i))) {
                all.remove(i)
            }
        }
        shown.clear()
    }

    function copy() {
        let lines = []
        for (let i = 0; i < shown.count; i++) {
            let l = shown.get(i)
            lines.push(`${l.time} ${levelNames[l.level]} ${l.source} ${l.message}`)
        }
        appData.copyToClipboard(lines.join("\n"))
    }

    function showSettings() {
        settingsPopup.open()
    }

    function accepts(line) {
        return line.level >= minLevel && (source === "" || line.source === source)
    }

    function refilter() {
        shown.clear()
        for (let i = 0; i < all.count; i++) {
            if (accepts(all.get(i))) {
                shown.append(all.get(i))
            }
        }
        Qt.callLater(view.positionViewAtEnd)
    }

    onSourceChanged: refilter()
    onMinLevelChanged: refilter()

    radius: 12
    color: Qt.alpha(Robosintesi.colors.background, 0.7)

    ListModel {
        id: all
    }

    ListModel {
        id: shown
    }

    ListView {
        id: view
        anchors.fill: parent
        anchors.margins: root.padding
        clip: true
        model: shown
        ScrollBar.vertical: ScrollBar {}

        delegate: RowLayout {
            id: line

            required property string time
            required property int level
            required property string source
            required property string message

            width: ListView.view.width
            spacing: 12

            Label {
                Layout.alignment: Qt.AlignTop
                text: line.time
                font: root.cellFont
                lineHeight: 1.75
                opacity: 0.6
                color: Robosintesi.colors.text
            }

            Label {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: root.fontSize * 2.6
                text: root.levelNames[line.level]
                font: root.cellFont
                lineHeight: 1.75
                color: root.levelColors[line.level]
            }

            Label {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 110
                visible: root.showSource
                text: line.source
                elide: Text.ElideRight
                font: root.cellFont
                lineHeight: 1.75
                color: Robosintesi.status.negative
            }

            Label {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                text: line.message
                textFormat: root.textFormat
                wrapMode: Text.WrapAnywhere
                font: root.cellFont
                lineHeight: 1.75
                color: Robosintesi.colors.text
            }
        }
    }

    Popup {
        id: settingsPopup
        x: root.width - width - 8
        y: 8

        contentItem: ColumnLayout {
            spacing: 12

            RowLayout {
                spacing: 12

                Label {
                    text: "font size"
                    font.pixelSize: 14
                    color: Robosintesi.colors.textSecondary
                }

                SpinBox {
                    from: 8
                    to: 24
                    value: root.fontSize
                    onValueModified: root.fontSize = value
                }
            }

            Switch {
                text: "autoscroll"
                checked: root.autoscroll
                onToggled: root.autoscroll = checked
            }
        }
    }

    Settings {
        category: "log"
        property alias fontSize: root.fontSize
    }
}
