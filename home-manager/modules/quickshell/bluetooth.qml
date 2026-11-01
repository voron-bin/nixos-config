import QtQuick
import Quickshell.Bluetooth

// Loaded through a Loader in shell.qml. Kept in its own file so that if your
// Quickshell build lacks the Bluetooth module, only this indicator fails to load.
Text {
    property string fontFamily: "PxPlus IBM VGA 8x14"
    property int fontPixelSize: 14

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool anyConnected: Bluetooth.devices.values.some(d => d.connected)

    visible: adapter !== null && adapter !== undefined
    text: "BT"
    font.family: fontFamily
    font.pixelSize: fontPixelSize
    verticalAlignment: Text.AlignVCenter
    // off = muted, on = normal, device connected = rust
    color: !adapter?.enabled ? "#7A7568" : (anyConnected ? "#A84826" : "#D6CFC2")
}
