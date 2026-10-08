pragma Singleton
import QtQuick

QtObject {
    // Human-Crafted Instrumentation Color Palette (Clean Slate & Light Theme)
    readonly property color mainBg: "#f8fafc"
    readonly property color panelBg: "#ffffff"
    readonly property color cardBg: "#f1f5f9"
    readonly property color headerBg: "#ffffff"
    readonly property color subPanelBg: "#e2e8f0"
    readonly property color dialBg: "#0f172a"

    // High-Contrast Automotive Accent Indicators
    readonly property color cyanAccent: "#0284c7"
    readonly property color cyanGlow: "#06b6d4"
    readonly property color redlineAccent: "#dc2626"
    readonly property color warningAmber: "#d97706"
    readonly property color greenSuccess: "#16a34a"

    // Typography Colors
    readonly property color textPrimary: "#0f172a"
    readonly property color textSecondary: "#475569"
    readonly property color textMuted: "#64748b"
    readonly property color textInverse: "#ffffff"

    // Panel Borders & Shadows
    readonly property color borderDark: "#cbd5e1"
    readonly property color borderLight: "#e2e8f0"
    readonly property color borderGlow: "#0284c744"
}
