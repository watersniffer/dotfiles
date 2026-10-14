pragma Singleton

import QtQml

// Minimal stand-in for the `GlobalStates` object that services/MprisController.qml
// references but which upstream never defines anywhere in the project - not even
// in its own shell.qml. Every reference to it therefore threw
// "ReferenceError: GlobalStates is not defined" on startup.
//
// MprisController uses it for exactly three things, all of which belong to a
// media-key OSD (on-screen display) feature that belongs to a fuller shell:
//
//     !GlobalStates.screenLocked        - don't show OSD while the screen is locked
//     GlobalStates.osdMediaAction = ... - "play"/"pause"/"next"/"previous"
//     GlobalStates.osdMediaOpen = true   - open the OSD
//
// So the bare minimum to stop the errors is these three properties. Nothing here
// renders an OSD on its own; if you ever wire an OSD up to it, read these and
// open your own window.
//
// Registered in common/qmldir, which is the module MprisController imports, so
// the unqualified `GlobalStates` name now resolves.

QtObject {
    id: root

    // True while the screen is locked; OSDs should not fight the lock screen.
    property bool screenLocked: false

    // Media-key OSD request, set by MprisController and consumed by whatever
    // draws the OSD. One of "play", "pause", "next", "previous".
    property string osdMediaAction: ""

    // Set true when an OSD should be shown; cleared by whatever draws it.
    property bool osdMediaOpen: false
}
