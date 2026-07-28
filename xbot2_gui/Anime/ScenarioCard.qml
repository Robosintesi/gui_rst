import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Common
import Font

RowLayout {

    id: card

    property string label: ""

    property string info: ""

    property bool running: false

    signal runClicked()
    signal infoClicked()

    spacing: 4

    RstButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        text: card.label
        enabled: !card.running
        opacity: enabled ? 1 : 0.5
        onClicked: card.runClicked()
    }

    RstIconButton {
        visible: card.info !== ""
        iconText: MaterialSymbolNames.info
        backgroundColor: "transparent"
        iconColor: Robosintesi.colors.text
        onClicked: card.infoClicked()
    }
}
