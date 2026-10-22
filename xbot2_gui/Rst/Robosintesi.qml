pragma Singleton

import QtQuick

// Robosintesi visual identity (see README.md), used by the Rst controls and by RstWindow
QtObject {
    id: theme

    // palette of the brand book
    property QtObject brand: QtObject {
        readonly property color blue: "#005683"
        readonly property color blue20k: "#02496F"
        readonly property color blue50k: "#01314C"
        readonly property color coolGray: "#D6D7D5"
        readonly property color coolGray20k: "#B8BAB8"
        readonly property color coolGray60k: "#727472"
        readonly property color accent: "#357D97"
        readonly property color white: "#FFFFFF"
        readonly property color black: "#000000"
    }

    property QtObject colors: QtObject {
        property color background: theme.brand.blue50k
        property color foreground: theme.brand.blue
        property color text: theme.brand.coolGray
        property color textSecondary: theme.brand.coolGray20k
        property color accent: theme.brand.accent
        property color panel: theme.brand.blue20k
        // selected joint: its link in 3D and the dot of its badge
        property color selection: "#22AAA1"
    }

    // not in the brand book; RstWindow also gives them to the fork's components
    property QtObject status: QtObject {
        property color ok: "#59C9A5"
        property color warn: "#FC7753"
        property color err: "#E63462"
        // negative side of the joint gauges
        property color negative: "#59B4D9"
        // text and icon of a destructive button, on err at 14%
        property color errText: "#FF8FA9"
    }

    property QtObject geom: QtObject {
        property int radius: 16
        property int radiusSmall: 4
        // minimum height of a control, so it is easy to hit on the tablet [px]
        property int touchHeight: 48
        property real disabledOpacity: 0.4
    }

    // Space Grotesk for titles and kickers, Inter for the rest (buttons in Inter SemiBold)
    property QtObject fonts: QtObject {
        readonly property FontLoader headline: FontLoader {
            source: Qt.resolvedUrl("fonts/SpaceGrotesk-Bold.ttf")
        }
        readonly property FontLoader body: FontLoader {
            source: Qt.resolvedUrl("fonts/Inter_18pt-Regular.ttf")
        }
        // the bold face of body, picked by font.bold
        readonly property FontLoader bodyBold: FontLoader {
            source: Qt.resolvedUrl("fonts/Inter_18pt-Bold.ttf")
        }
        // buttons, with font.weight: Font.DemiBold
        readonly property FontLoader bodySemiBold: FontLoader {
            source: Qt.resolvedUrl("fonts/Inter_18pt-SemiBold.ttf")
        }
        // Material Symbols Rounded for RstIcon, static (fonts/static_icons.py): thin and filled
        readonly property FontLoader icons: FontLoader {
            source: Qt.resolvedUrl("fonts/MaterialSymbolsRoundedThin.ttf")
        }
        readonly property FontLoader iconsFilled: FontLoader {
            source: Qt.resolvedUrl("fonts/MaterialSymbolsRoundedFilled.ttf")
        }
        // text of buttons, checkboxes and switches [px]
        property int control: 16
    }

    property QtObject logos: QtObject {
        readonly property string ideogramBlue: Qt.resolvedUrl("logos/ideogram_blue.svg")
        readonly property string ideogramCoolGray: Qt.resolvedUrl("logos/ideogram_cool_gray.svg")
        readonly property string ideogramBlack: Qt.resolvedUrl("logos/ideogram_black.svg")
        readonly property string logotypeBlue: Qt.resolvedUrl("logos/logotype_blue.svg")
        readonly property string logotypeCoolGray: Qt.resolvedUrl("logos/logotype_cool_gray.svg")
        readonly property string logotypeBlack: Qt.resolvedUrl("logos/logotype_black.svg")
        readonly property string logotypeHorizontalWhite: Qt.resolvedUrl("logos/logotype_horizontal_white.svg")
    }

    // Material Symbols code points missing from the fork's MaterialSymbolNames
    property QtObject symbols: QtObject {
        readonly property string info: '\ue88e'
        readonly property string robotArm: '\uf049'
        readonly property string wifiConnected: '\ue63e'
        readonly property string wifiDisconnected: '\ue648'
        readonly property string check: '\ue5ca'
        readonly property string radioUnchecked: '\ue836'
        readonly property string pause: '\ue034'
        readonly property string arrowForward: '\ue5c8'
        readonly property string expandMore: '\ue5cf'
        readonly property string rotation3d: '\ue84d'
        readonly property string landscape: '\ue3f7'
        readonly property string centerFocus: '\ue3b4'
        readonly property string stopCircle: '\uef71'
        readonly property string showChart: '\ue6e1'
        readonly property string send: '\ue163'
        readonly property string undo: '\ue166'
        readonly property string viewInAr: '\ue9fe'
        readonly property string add: '\ue145'
        readonly property string remove: '\ue15b'
        readonly property string chevronRight: '\ue5cc'
        readonly property string link: '\ue157'
        readonly property string linkOff: '\ue16f'
        readonly property string restart: '\uf053'
        readonly property string deleteSweep: '\ue16c'
        readonly property string article: '\uef42'
        readonly property string refresh: '\ue5d5'
    }
}
