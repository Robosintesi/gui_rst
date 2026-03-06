pragma Singleton

import QtQuick

QtObject {

    property QtObject colors: QtObject {
        property color background: "#01314C"
        property color foreground: "#005683"
        property color text: "#D6D7D5"
        property color error: "#E63462" //#F45B69
        property color ok:"#22AAA1" //"#48E5C2"
        property color accent: "#357D97"
    }

    property QtObject icons: QtObject {
        readonly property string ideogrammaCoolGray: Qt.resolvedUrl("icons/Ideogramma-Robosintesi-Cool-Gray.svg")
        readonly property string ideogrammaBlack: Qt.resolvedUrl("icons/Ideogramma-Robosintesi-Black.svg")
        readonly property string ideogrammaBlu: Qt.resolvedUrl("icons/Ideogramma-Robosintesi-Blu.svg")
        readonly property string logotipoCoolGray: Qt.resolvedUrl("icons/Logotipo-Robosintesi-Cool-Gray.svg")
        readonly property string logotipoBlack: Qt.resolvedUrl("icons/Logotipo-Robosintesi-Black.svg")
        readonly property string logotipoBlu: Qt.resolvedUrl("icons/Logotipo-Robosintesi-Blu.svg")
    }
}
