import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Loaded through a Loader in shell.qml. Shows a scaled-down live view of one
// workspace: every window on it, drawn where it sits on the monitor.
// Kept in its own file so that if screen capture isn't available, only the
// preview fails to load and the rest of the bar keeps working.
Item {
    id: pv

    property int wsId: 1
    property var screenObj: null          // the monitor's screen (x, y, width, height)
    property string fontFamily: "PxPlus IBM VGA 8x14"
    property int fontPixelSize: 20

    readonly property real screenW: screenObj ? screenObj.width : 1920
    readonly property real screenH: screenObj ? screenObj.height : 1080
    readonly property real screenX: screenObj ? screenObj.x : 0
    readonly property real screenY: screenObj ? screenObj.y : 0
    readonly property real zoom: width / screenW
    readonly property var wins: Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id === wsId)

    // monitor area
    Rectangle {
        anchors.fill: parent
        color: "#141210"
        border.width: 1
        border.color: "#3D3833"
    }

    Text {
        anchors.centerIn: parent
        visible: pv.wins.length === 0
        text: "ПУСТО"
        color: "#7A7568"
        font.family: pv.fontFamily
        font.pixelSize: pv.fontPixelSize
    }

    Repeater {
        model: pv.wins

        Rectangle {
            id: win
            required property var modelData
            readonly property var ipc: modelData.lastIpcObject
            readonly property var at: ipc && ipc.at ? ipc.at : [0, 0]
            readonly property var sz: ipc && ipc.size ? ipc.size : [0, 0]

            x: (at[0] - pv.screenX) * pv.zoom
            y: (at[1] - pv.screenY) * pv.zoom
            width: sz[0] * pv.zoom
            height: sz[1] * pv.zoom
            color: "#262320"
            border.width: 1
            border.color: "#A84826"
            clip: true

            ScreencopyView {
                anchors.fill: parent
                anchors.margins: 1
                captureSource: win.modelData.wayland
                live: true
            }
        }
    }
}
