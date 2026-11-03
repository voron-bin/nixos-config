import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

// Bluetooth drop-down, loaded through a Loader inside a popup in shell.qml.
// Own file so a Quickshell build without the Bluetooth module only loses this panel.
//   click a device  -> connect / disconnect (unpaired devices are paired + trusted first)
//   right-click     -> forget a paired device
Item {
    id: bp

    property string fontFamily: "PxPlus IBM VGA 8x14"
    property int fontPixelSize: 14

    // same palette as the bar
    readonly property color cBase: "#1C1917"
    readonly property color cText: "#D6CFC2"
    readonly property color cMuted: "#7A7568"
    readonly property color cBorder: "#3D3833"
    readonly property color cRust: "#A84826"
    readonly property color cHover: "#33D6CFC2"

    readonly property var adapter: Bluetooth.defaultAdapter

    component T: Text {
        color: bp.cText
        font.family: bp.fontFamily
        font.pixelSize: bp.fontPixelSize
        font.kerning: false
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter
    }

    component Btn: Rectangle {
        id: b
        property string label
        property bool active: false
        property bool flash: false
        signal activated()
        implicitWidth: bl.implicitWidth + 28
        implicitHeight: bl.implicitHeight + 12
        color: (bm.pressed || b.flash) ? bp.cRust : (bm.containsMouse ? bp.cHover : "transparent")
        border.width: 1
        border.color: b.active ? bp.cRust : (bm.containsMouse ? bp.cMuted : bp.cBorder)
        Timer { id: ft; interval: 180; onTriggered: b.flash = false }
        T {
            id: bl
            anchors.centerIn: parent
            text: b.label
            color: (bm.pressed || b.flash) ? bp.cBase : (b.active ? bp.cRust : bp.cText)
        }
        MouseArea {
            id: bm
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { b.flash = true; ft.restart(); b.activated(); }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        T { text: "BLUETOOTH"; color: bp.cRust }

        // no adapter (no hardware, or hardware.bluetooth.enable is off)
        T {
            visible: bp.adapter === null || bp.adapter === undefined
            text: "НЕТ АДАПТЕРА"
            color: bp.cMuted
        }

        RowLayout {
            visible: bp.adapter !== null && bp.adapter !== undefined
            Layout.fillWidth: true
            spacing: 8

            Btn {
                label: "BT " + (bp.adapter?.enabled ? "ВКЛ" : "ВЫКЛ")
                active: bp.adapter?.enabled ?? false
                onActivated: { if (bp.adapter) bp.adapter.enabled = !bp.adapter.enabled; }
            }
            Btn {
                label: bp.adapter?.discovering ? "СТОП" : "ПОИСК"
                active: bp.adapter?.discovering ?? false
                onActivated: {
                    if (bp.adapter && bp.adapter.enabled)
                        bp.adapter.discovering = !bp.adapter.discovering;
                }
            }
            Item { Layout.fillWidth: true }
            T {
                text: bp.adapter?.discovering ? "ПОИСК..." : ""
                color: bp.cMuted
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: bp.cBorder }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: Bluetooth.devices

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var d: modelData
                // paired / connected devices always; nearby unpaired ones only while scanning
                readonly property bool shown: d.connected || d.paired || d.bonded
                                              || (bp.adapter?.discovering ?? false)
                property bool wantConnect: false

                visible: shown
                width: list.width
                height: shown ? 34 : 0
                color: rowMa.containsMouse ? bp.cHover : "transparent"
                border.width: 1
                border.color: d.connected ? bp.cRust : (rowMa.containsMouse ? bp.cMuted : "transparent")

                // after pairing succeeds, trust it and connect
                Connections {
                    target: row.d
                    function onPairedChanged() {
                        if (row.wantConnect && row.d.paired) {
                            row.d.trusted = true;
                            row.d.connect();
                            row.wantConnect = false;
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12

                    T {
                        Layout.fillWidth: true
                        text: row.d.name && row.d.name !== "" ? row.d.name : row.d.address
                        elide: Text.ElideRight
                        color: row.d.connected ? bp.cRust : bp.cText
                    }
                    T {
                        visible: row.d.batteryAvailable
                        text: Math.round(row.d.battery * 100) + "%"
                        color: bp.cMuted
                    }
                    T {
                        text: row.d.connected ? "ПОДКЛ"
                            : (row.d.state === BluetoothDeviceState.Connecting ? "..."
                            : (row.d.paired || row.d.bonded ? "СОПР" : "НОВОЕ"))
                        color: row.d.connected ? bp.cRust : bp.cMuted
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            if (row.d.paired || row.d.bonded) row.d.forget();
                            return;
                        }
                        if (row.d.connected) {
                            row.d.disconnect();
                        } else if (row.d.paired || row.d.bonded) {
                            row.d.connect();
                        } else {
                            row.wantConnect = true;
                            row.d.pair();
                        }
                    }
                }
            }
        }

        T {
            text: "ЛКМ подключить · ПКМ забыть"
            color: bp.cMuted
        }
    }
}
