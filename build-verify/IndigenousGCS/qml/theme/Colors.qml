pragma Singleton
import QtQuick 2.15

QtObject {
    property bool lightTheme: false

    readonly property color bg0:           lightTheme ? "#e6f4fb" : "#0d0f14"
    readonly property color bg1:           lightTheme ? "#f6fbfe" : "#13161e"
    readonly property color bg2:           lightTheme ? "#d5ebf5" : "#1a1e2a"
    readonly property color bg3:           lightTheme ? "#bfdce9" : "#222736"
    readonly property color bg4:           lightTheme ? "#a5c9da" : "#2a3045"

    readonly property color accent:        "#ff9933"   // IAF Saffron
    readonly property color accentDim:     lightTheme ? "#9a5a00" : "#b36a00"
    readonly property color accentGlow:    lightTheme ? "#ffe8bf" : "#2a1a00"
    readonly property color accentBlue:    lightTheme ? "#1769aa" : "#4a9eff"
    readonly property color accentGreen:   "#138808"   // India Green

    readonly property color ok:            "#00e676"
    readonly property color warning:       "#ffab00"
    readonly property color critical:      "#ff1744"
    readonly property color emergency:     "#ff6d00"
    readonly property color info:          "#40c4ff"

    readonly property color textPrimary:   lightTheme ? "#102b3a" : "#e8ecf4"
    readonly property color textSecondary: lightTheme ? "#426579" : "#7a8aaa"
    readonly property color textDisabled:  lightTheme ? "#7893a1" : "#3a4460"
    readonly property color textBright:    lightTheme ? "#102b3a" : "#ffffff"

    readonly property color border:        lightTheme ? "#9fc4d3" : "#2a3050"
    readonly property color borderHi:      "#ff9933"
    readonly property color borderActive:  "#4a9eff"

    readonly property color skyColor:      "#0a2040"
    readonly property color groundColor:   "#3d2008"
    readonly property color hudGreen:      "#00ff41"
    readonly property color hudAmber:      "#ffb300"
}
