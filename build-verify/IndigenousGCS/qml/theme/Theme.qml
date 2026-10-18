pragma Singleton
import QtQuick 2.15

QtObject {
    readonly property int    fontSizeTiny:    9
    readonly property int    fontSizeSmall:   11
    readonly property int    fontSizeNormal:  13
    readonly property int    fontSizeMedium:  15
    readonly property int    fontSizeLarge:   18
    readonly property int    fontSizeHuge:    22
    readonly property int    fontSizeDisplay: 28
    readonly property string fontFamily:      "monospace"
    readonly property string fontFamilyUI:    "sans-serif"

    readonly property int    radiusSmall:     3
    readonly property int    radiusMedium:    6
    readonly property int    radiusLarge:     10

    readonly property int    spacingXS:       3
    readonly property int    spacingS:        6
    readonly property int    spacingM:        10
    readonly property int    spacingL:        16
    readonly property int    spacingXL:       24

    readonly property int    sideBarWidth:    200
    readonly property int    topBarHeight:    44
    readonly property int    statusBarHeight: 28
    readonly property int    toolBarHeight:   36
}
