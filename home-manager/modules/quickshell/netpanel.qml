import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Wi-Fi drop-down, loaded through a Loader inside a popup in shell.qml. Uses nmcli.
//   click a network -> connect (saved or open) / disconnect (the one you are on)
//   a new secured network opens a small terminal that asks for the password
Item {
    id: np

    property string fontFamily: "PxPlus IBM VGA 8x14"
    property int fontPixelSize: 14

    readonly property color cBase: "#1C1917"
    readonly property color cText: "#D6CFC2"
    readonly property color cMuted: "#7A7568"
    readonly property color cBorder: "#3D3833"
    readonly property color cRust: "#A84826"
    readonly property color cHover: "#33D6CFC2"

    property var networks: []       // [{ ssid, signal, security, inUse }]
    property var saved: []          // names of saved Wi-Fi connections
    property bool radioOn: true

    component T: Text {
        color: np.cText
        font.family: np.fontFamily
        font.pixelSize: np.fontPixelSize
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
        color: (bm.pressed || b.flash) ? np.cRust : (bm.containsMouse ? np.cHover : "transparent")
        border.width: 1
        border.color: b.active ? np.cRust : (bm.containsMouse ? np.cMuted : np.cBorder)
        Timer { id: ft; interval: 180; onTriggered: b.flash = false }
        T {
            id: bl
            anchors.centerIn: parent
            text: b.label
            color: (bm.pressed || b.flash) ? np.cBase : (b.active ? np.cRust : np.cText)
        }
        MouseArea {
            id: bm
            anchors.fill: parent
            hoverEnabled: true
            onClicked: { b.flash = true; ft.restart(); b.activated(); }
        }
    }

    // ---- nmcli ----
    function refresh() {
        radioProc.running = true;
        savedProc.running = true;
        listProc.running = true;     // what is cached right now
        rescanProc.running = true;   // then rescan, and list again when it finishes
    }

    // "a:b\:c:d" -> ["a", "b:c", "d"] (nmcli -t escapes colons in values)
    function splitT(line) {
        return line.replace(/\\:/g, "\u0001").split(":").map(x => x.replace(/\u0001/g, ":"));
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: np.radioOn = text.trim() === "enabled"
        }
    }
    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const f = np.splitT(line);
                    if (f.length >= 2 && f[1].indexOf("wireless") >= 0) out.push(f[0]);
                }
                np.saved = out;
            }
        }
    }
    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const best = {};
                for (const line of text.split("\n")) {
                    const f = np.splitT(line);
                    if (f.length < 4 || f[1] === "") continue;
                    const n = { ssid: f[1], signal: parseInt(f[2]) || 0, security: f[3], inUse: f[0] === "*" };
                    const old = best[n.ssid];
                    if (!old || n.inUse || (!old.inUse && n.signal > old.signal)) best[n.ssid] = n;
                }
                const arr = Object.values(best);
                arr.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal));
                np.networks = arr;
            }
        }
    }
    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onRunningChanged: if (!running) listProc.running = true
    }

    Timer { id: later; interval: 3000; onTriggered: np.refresh() }

    function connectTo(n) {
        if (n.inUse) {
            Quickshell.execDetached(["nmcli", "connection", "down", "id", n.ssid]);
        } else if (np.saved.indexOf(n.ssid) >= 0) {
            Quickshell.execDetached(["nmcli", "connection", "up", "id", n.ssid]);
        } else if (n.security === "" || n.security === "--") {
            Quickshell.execDetached(["nmcli", "device", "wifi", "connect", n.ssid]);
        } else {
            // new secured network: let nmcli ask for the password in a terminal
            Quickshell.execDetached(["kitty", "-e", "sh", "-c",
                'nmcli --ask device wifi connect "$1"; sleep 2', "_", n.ssid]);
        }
        later.restart();
    }

    Component.onCompleted: refresh()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        T { text: "WI-FI"; color: np.cRust }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Btn {
                label: "WI-FI " + (np.radioOn ? "ВКЛ" : "ВЫКЛ")
                active: np.radioOn
                onActivated: {
                    Quickshell.execDetached(["nmcli", "radio", "wifi", np.radioOn ? "off" : "on"]);
                    later.restart();
                }
            }
            Btn {
                label: "ОБНОВИТЬ"
                onActivated: np.refresh()
            }
            Item { Layout.fillWidth: true }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: np.cBorder }

        T {
            visible: np.radioOn && np.networks.length === 0
            text: "СЕТЕЙ НЕТ"
            color: np.cMuted
        }
        T {
            visible: !np.radioOn
            text: "ВЫКЛЮЧЕНО"
            color: np.cMuted
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            model: np.radioOn ? np.networks : []

            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var n: modelData

                width: list.width
                height: 34
                color: rowMa.containsMouse ? np.cHover : "transparent"
                border.width: 1
                border.color: n.inUse ? np.cRust : (rowMa.containsMouse ? np.cMuted : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 12

                    T {
                        Layout.fillWidth: true
                        text: row.n.ssid
                        elide: Text.ElideRight
                        color: row.n.inUse ? np.cRust : np.cText
                    }
                    T {
                        text: (row.n.security === "" || row.n.security === "--") ? "" : "ЗАЩ"
                        color: np.cMuted
                    }
                    T {
                        text: np.saved.indexOf(row.n.ssid) >= 0 ? "СОХР" : ""
                        color: np.cMuted
                    }
                    T {
                        text: row.n.inUse ? "ПОДКЛ" : row.n.signal + "%"
                        color: row.n.inUse ? np.cRust : np.cMuted
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: np.connectTo(row.n)
                }
            }
        }

        T {
            text: "ЛКМ подключить / отключить"
            color: np.cMuted
        }
    }
}
