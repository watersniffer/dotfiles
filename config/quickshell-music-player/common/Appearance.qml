pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool animationsEnabled: true
    property real fontSizeScale: 1.0

    // Design Tokens - Colors (Material 3 Dark by default, adapts to album art)
    // AMOLED palette, taken from ~/.config/waybar/colors.css so this widget
    // matches the bar exactly:
    //   @base #0b0b11   @text #bfbcc7   @subtext #85838b
    readonly property var colors: ({
        colPrimary: "#bfbcc7",
        colPrimaryHover: "#cfced9",
        colPrimaryActive: "#9c9ba4",
        colPrimaryContainer: "#22222b",
        colOnPrimary: "#0b0b11",
        colOnPrimaryContainer: "#bfbcc7",
        colSecondary: "#85838b",
        colSecondaryContainer: "#1a1a21",
        colSecondaryContainerHover: "#24242d",
        colSecondaryContainerActive: "#2e2e39",
        colOnSecondary: "#0b0b11",
        colOnSecondaryContainer: "#bfbcc7",
        colLayer0: "#0b0b11",
        colOnLayer0: "#bfbcc7",
        colLayer1: "#121219",
        colOnLayer1: "#bfbcc7",
        colLayer2: "#1a1a22",
        colLayer3: "#23232c",
        colLayer3Hover: "#2c2c36",
        colLayer0Base: "#0b0b11",
        colLayer1Hover: "#1a1a22",
        colLayer1Active: "#23232c",
        colOnLayer3: "#bfbcc7",
        colSubtext: "#85838b",
        colSurface: "#0b0b11",
        colOnSurface: "#bfbcc7",
        colSurfaceContainer: "#121219",
        colSurfaceContainerHigh: "#1a1a22",
        colSurfaceContainerHighest: "#23232c",
        colOutline: "#3a3a44",
        colOutlineVariant: "#23232c",
        colShadow: "#000000",
        colScrim: "#99000000"
    })

    // Inir fixed color palette compatibility
    readonly property var inir: ({
        colText: "#e2e2e0",
        colTextSecondary: "#a0a4a0",
        colPrimary: "#a5d0bb",
        colOnPrimary: "#122019",
        colLayer1: "#1a1c1b",
        colLayer2: "#282a29",
        colBorder: "rgba(255, 255, 255, 0.1)",
        roundingNormal: 18,
        roundingLarge: 24
    })

    readonly property var m3colors: ({
        m3primary: root.colors.colPrimary,
        darkmode: true
    })

    // Corner Rounding Tokens
    readonly property var rounding: ({
        none: 0,
        small: 8,
        normal: 14,
        large: 20,
        verylarge: 26,
        verysmall: 6,
        unsharpen: 2,
        full: 9999,
        screenRounding: 18
    })

    // Sizing Tokens
    readonly property var sizes: ({
        elevationMargin: 0,
        hyprlandGapsOut: 8
    })

    // Typography Metrics
    readonly property var font: ({
        family: {
            main: "sans-serif",
            numbers: "sans-serif",
            monospace: "monospace",
            icons: "Material Symbols Outlined, Material Symbols Rounded, Material Icons, sans-serif",
            title: "sans-serif"
        },
        variableAxes: {
            main: ({}),
            numbers: ({})
        },
        pixelSize: {
            smallest: Math.round(10 * root.fontSizeScale),
            smaller: Math.round(11 * root.fontSizeScale),
            small: Math.round(12 * root.fontSizeScale),
            normal: Math.round(14 * root.fontSizeScale),
            large: Math.round(15 * root.fontSizeScale),
            larger: Math.round(16 * root.fontSizeScale),
            huge: Math.round(22 * root.fontSizeScale)
        }
    })

    // Easing Animation Curves
    readonly property var animationCurves: ({
        emphasizedDecel: [0.05, 0.7, 0.1, 1.0, 1.0, 1.0],
        emphasizedAccel: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0],
        standard: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0],
        standardDecel: [0, 0, 0, 1, 1, 1],
        expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1.0, 1.0]
    })

    readonly property var animation: ({
        elementMoveFast: {
            duration: 200,
            type: Easing.BezierSpline,
            bezierCurve: root.animationCurves.emphasizedDecel
        },
        elementMove: {
            duration: 500,
            type: Easing.BezierSpline,
            bezierCurve: root.animationCurves.emphasizedDecel
        },
        elementMoveEnter: {
            duration: 400,
            type: Easing.BezierSpline,
            bezierCurve: root.animationCurves.emphasizedDecel
        },
        stateChange: {
            duration: 200,
            type: Easing.BezierSpline,
            bezierCurve: root.animationCurves.standard
        },
        elementResize: {
            duration: 350,
            type: Easing.BezierSpline,
            bezierCurve: root.animationCurves.emphasizedDecel
        }
    })

    // Token groups for the shell's other global styles. They are switched off
    // here (see the flags below), but the shared widgets still read them, so
    // they need real values.
    readonly property var zzz: ({
        accent: root.colors.colPrimary, accentSoft: root.colors.colPrimaryContainer,
        bg: root.colors.colLayer0, paper: root.colors.colLayer1, paperAlt: root.colors.colLayer2,
        ink: root.colors.colOnLayer1, inkMuted: root.colors.colSubtext, ghostInk: root.colors.colOutlineVariant,
        onColor: root.colors.colOnPrimary, onMuted: root.colors.colSubtext,
        sticker: root.colors.colPrimary, onSticker: root.colors.colOnPrimary,
        signal: "#ffb4ab", posterCool: root.colors.colSecondary,
        hairlineStrong: root.colors.colOutline, metricFill: root.colors.colPrimary, metricTrack: root.colors.colLayer2,
        technicalGrid: root.colors.colOutlineVariant, technicalGridStrong: root.colors.colOutline,
        technicalMarker: root.colors.colPrimary, technicalWarning: "#ffb4ab",
        registrationMark: root.colors.colOutline, registrationMarkAlt: root.colors.colOutlineVariant,
        registrationRail: root.colors.colOutlineVariant, diagonalStripe: root.colors.colOutlineVariant,
        borderThick: 2, controlRadius: 10, cornerRadius: 12, panelRadius: 18, cutCorner: 10,
        markerLength: 8, markerThickness: 2, overshootDuration: 300, useDiagonals: false
    })
    readonly property var angel: ({
        colPrimary: root.colors.colPrimary, colOnPrimary: root.colors.colOnPrimary,
        colText: root.colors.colOnLayer1, colTextSecondary: root.colors.colSubtext,
        colBorder: root.colors.colOutlineVariant, colBorderHover: root.colors.colOutline,
        colBorderSubtle: root.colors.colOutlineVariant,
        colGlassCard: root.colors.colLayer1, colGlassCardHover: root.colors.colLayer2,
        colGlassCardActive: root.colors.colSurfaceContainerHigh, colGlassTooltip: root.colors.colLayer2,
        colEscalonado: root.colors.colLayer2, colEscalonadoHover: root.colors.colSurfaceContainerHigh,
        colEscalonadoBorder: root.colors.colOutlineVariant,
        borderWidth: 1, cardBorderWidth: 1, borderCoverage: 1.0, blurSaturation: 1.0, overlayOpacity: 0.4,
        escalonadoOffsetX: 4, escalonadoOffsetY: 4, escalonadoHoverOffsetX: 6, escalonadoHoverOffsetY: 6,
        roundingNormal: 14, roundingSmall: 8
    })
    readonly property var aurora: ({
        colElevatedSurface: root.colors.colLayer2, colSubSurface: root.colors.colLayer1,
        colSubSurfaceActive: root.colors.colLayer2, colTooltipSurface: root.colors.colLayer2,
        colTooltipBorder: root.colors.colOutlineVariant, popupTransparentize: 0.1
    })
    readonly property var cookie: ({
        roundNormal: 14, shadowBlur: 0.6, shadowColor: "#66000000", shadowOffset: 2, shadowSpread: 0
    })

    // Worldview & Style compatibility flags
    readonly property bool zzzEverywhere: false
    readonly property bool inirEverywhere: false
    readonly property bool angelEverywhere: false
    readonly property bool auroraEverywhere: false
    readonly property bool cookieEverywhere: false
    // AMOLED: disables the coloured glow/aurora overlays that tinted the
    // card from the album art. Set true to get them back.
    readonly property bool effectsEnabled: false
    readonly property bool gameModeMinimal: false
}
