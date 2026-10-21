import QtQuick
import QtQuick.Controls

// Material Symbols Rounded icon: text is a code point from Robosintesi.symbols or MaterialSymbolNames;
// thin, or filled and heavier (in primary buttons)
Label {
    property int size: 24
    property bool filled: false

    font.family: filled ? Robosintesi.fonts.iconsFilled.font.family : Robosintesi.fonts.icons.font.family
    font.pixelSize: size
    color: Robosintesi.colors.text
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
