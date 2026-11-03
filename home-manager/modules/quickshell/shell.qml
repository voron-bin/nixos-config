import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire

// Quickshell bar modelled on your ashell config, with Caelestia-style panels:
//   left:   [launcher, workspaces А-К] [window title]
//   center: media player (click: media panel, middle-click: play/pause)
//   right:  [CPU, RAM, temp, GPU*] [VPN] [clock, indicators] [ПИТ]
//   click the clock      -> dashboard (clock, calendar, weather, resources)
//   click the network    -> control panel (toggles, volume sliders)
//   click ПИТ            -> session menu (lock, logout, sleep, reboot, shutdown)
//   volume / mic / brightness changes pop up an OSD
// * GPU, battery and Bluetooth only appear on machines that have them.
// Helper scripts in this folder: stats.sh, brightness.sh, ctl.sh

ShellRoot {
    id: root

    // ---- appearance ----
    readonly property real uiScale: 1.5            // used for button sizes only
    // This font is built on a 14px grid, so it is sharpest at multiples of 14
    // (14, 28). 20 is what you chose; if it looks soft, try 14 or 28.
    readonly property int fontSize: 20
    readonly property int barHeight: 50
    readonly property string fontFamily: "PxPlus IBM VGA 8x14"

    readonly property color cBase: "#1C1917"
    readonly property color cText: "#D6CFC2"
    readonly property color cMuted: "#7A7568"
    readonly property color cBorder: "#3D3833"
    readonly property color cRust: "#A84826"
    readonly property color cWarn: "#B89650"
    readonly property color cDanger: "#C8302E"
    readonly property color cHover: "#33D6CFC2"    // soft highlight (cText at 20%)

    readonly property var wsNames: ["А", "Б", "В", "Г", "Д", "Е", "Ж", "З", "И", "К"]

    // Weather city for the dashboard, e.g. "Voronezh". Empty = guess from your IP
    // (the request goes to wttr.in). Set weatherEnabled to false to turn it off.
    readonly property bool weatherEnabled: true
    readonly property string weatherLocation: ""

    // ---- state fed by stats.sh ----
    property int cpu: 0
    property int memUsed: 0
    property int memTotal: 0
    property int cpuTemp: -1
    property int gpuTemp: -1        // -1 = no amdgpu (laptop)
    property int battery: -1        // -1 = no battery (desktop)
    property bool charging: false
    property bool vpnOn: false
    property string netType: "none"
    property bool rec: false        // screen recording running
    property int watts10: -1        // battery power draw, tenths of a watt
    property int battMins: -1       // minutes to empty (or to full while charging)
    property int battHealth: -1     // full capacity vs design, percent

    property bool idleInhibit: false

    // ---- state fed by ctl.sh / brightness.sh ----
    property string wifi: "--"
    property string bt: "--"
    property string profile: "--"
    property string weather: "—"
    property int brightness: -1

    // ---- OSD ----
    property bool osdReady: false
    property string osdLabel: ""
    property real osdValue: 0
    property bool osdMuted: false

    function showOsd(label, value, muted) {
        if (!osdReady)
            return;
        osdLabel = label;
        osdValue = value;
        osdMuted = muted;
        osdTimer.restart();
    }

    onBrightnessChanged: if (brightness >= 0) showOsd("ЯРК", brightness / 100, false)

    Timer {
        interval: 3000
        running: true
        onTriggered: root.osdReady = true
    }
    Timer {
        id: osdTimer
        interval: 1500
    }

    // ---- audio ----
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    readonly property string volText: !sink?.audio ? "ГРМ --"
        : (sink.audio.muted ? "ГРМ ВЫКЛ" : "ГРМ " + Math.round(sink.audio.volume * 100) + "%")
    readonly property string micText: !source?.audio ? "МИК --"
        : (source.audio.muted ? "МИК ВЫКЛ" : "МИК")

    Connections {
        target: root.sink ? root.sink.audio : null
        function onVolumeChanged() { root.showOsd("ГРМ", root.sink.audio.volume, root.sink.audio.muted); }
        function onMutedChanged() { root.showOsd("ГРМ", root.sink.audio.volume, root.sink.audio.muted); }
    }
    Connections {
        target: root.source ? root.source.audio : null
        function onMutedChanged() { root.showOsd("МИК", root.source.audio.volume, root.source.audio.muted); }
    }

    // ---- media (center) ----
    // the player you picked in the media panel; otherwise the one that's playing
    property var pickedPlayer: null
    readonly property var player: {
        const ps = Mpris.players.values;
        if (pickedPlayer && ps.includes(pickedPlayer))
            return pickedPlayer;
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }

    // seconds -> m:ss
    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        const r = s % 60;
        return Math.floor(s / 60) + ":" + (r < 10 ? "0" : "") + r;
    }
    readonly property string mediaText: !player ? ""
        : ((player.isPlaying ? "► " : "║ ")
           + (player.trackArtist ? player.trackArtist + " — " : "")
           + player.trackTitle)

    // ---- clock (Russian, e.g. "Сб 31 окт · 17:14") ----
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string dayStr: {
        let day = clock.date.toLocaleDateString(Qt.locale("ru_RU"), "ddd d MMM").replace(/\./g, "");
        return day.charAt(0).toUpperCase() + day.slice(1);
    }
    readonly property string dateStr: dayStr + " · " + Qt.formatTime(clock.date, "HH:mm")
    // calendar: monthOffset is how many months away from the current one we're viewing
    property int monthOffset: 0
    readonly property var monthNames: ["Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
                                       "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"]
    readonly property var viewDate: new Date(clock.date.getFullYear(), clock.date.getMonth() + monthOffset, 1)
    readonly property string monthStr: monthNames[viewDate.getMonth()] + " " + viewDate.getFullYear()

    // ---- processes ----
    Process {
        id: stats
        command: ["sh", Quickshell.shellPath("stats.sh")]
        running: true
        stdout: SplitParser {
            // cpu memUsed memTotal cpuTemp gpuTemp battery charging vpn net
            onRead: data => {
                const p = data.trim().split(" ");
                if (p.length < 13)
                    return;
                root.cpu = parseInt(p[0]);
                root.memUsed = parseInt(p[1]);
                root.memTotal = parseInt(p[2]);
                root.cpuTemp = parseInt(p[3]);
                root.gpuTemp = parseInt(p[4]);
                root.battery = parseInt(p[5]);
                root.charging = p[6] === "1";
                root.vpnOn = p[7] === "on";
                root.netType = p[8];
                root.rec = p[9] === "1";
                root.watts10 = parseInt(p[10]);
                root.battMins = parseInt(p[11]);
                root.battHealth = parseInt(p[12]);
            }
        }
    }

    // prints the backlight percentage whenever it changes (exits on machines without one)
    Process {
        command: ["sh", Quickshell.shellPath("brightness.sh")]
        running: true
        stdout: SplitParser {
            onRead: data => root.brightness = parseInt(data.trim())
        }
    }

    // wifi / bluetooth / power profile state, refreshed when the control panel opens
    Process {
        id: ctlStatus
        command: ["sh", Quickshell.shellPath("ctl.sh"), "status"]
        stdout: SplitParser {
            onRead: data => {
                const p = data.trim().split(" ");
                if (p.length < 3)
                    return;
                root.wifi = p[0];
                root.bt = p[1];
                root.profile = p[2];
            }
        }
    }
    Timer {
        id: ctlRefresh
        interval: 800
        onTriggered: ctlStatus.running = true
    }
    function ctl(action) {
        Quickshell.execDetached(["sh", Quickshell.shellPath("ctl.sh"), action]);
        ctlRefresh.restart();
    }

    Process {
        id: weatherProc
        command: ["sh", Quickshell.shellPath("ctl.sh"), "weather", root.weatherLocation]
        stdout: StdioCollector {
            onStreamFinished: root.weather = text.trim() || "—"
        }
    }
    Timer {
        interval: 1800000
        repeat: true
        running: root.weatherEnabled
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    // ---- notifications: this shell is the notification daemon (so mako must go) ----
    property bool dnd: false          // do not disturb: no toasts, history still collects

    ListModel { id: history }         // newest first, max 30

    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        actionsSupported: false
        imageSupported: false
        onNotification: n => {
            n.tracked = true;
            history.insert(0, {
                app: n.appName,
                summary: n.summary,
                body: n.body,
                critical: n.urgency === NotificationUrgency.Critical,
                time: Qt.formatTime(new Date(), "HH:mm")
            });
            if (history.count > 30)
                history.remove(30, history.count - 30);
        }
    }

    // ---- reusable pieces ----
    component BarText: Text {
        color: root.cText
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.hintingPreference: Font.PreferFullHinting
        font.kerning: false
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter
    }

    // Put inside a BarText: tracks hover and draws a soft highlight behind the text.
    // Use onEntered / onExited / onClicked on it as needed.
    component HoverArea: MouseArea {
        anchors.fill: parent
        anchors.margins: -8
        z: -1                       // keeps the highlight behind the text
        hoverEnabled: true

        Rectangle {
            anchors.fill: parent
            color: root.cHover
            opacity: parent.containsMouse ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

    // bordered button; set confirm: true to require a second click (for reboot/shutdown)
    component MenuBtn: Rectangle {
        id: mb
        property string label
        property bool active: false
        property bool confirm: false
        property bool armed: false
        property bool flash: false      // brief rust fill after a click, so clicks are visible
        signal activated()

        implicitWidth: lbl.implicitWidth + 28
        implicitHeight: lbl.implicitHeight + 12
        color: (ma.pressed || mb.flash) ? root.cRust : (ma.containsMouse ? root.cHover : "transparent")
        border.width: 1
        border.color: mb.active ? root.cRust : (ma.containsMouse ? root.cMuted : root.cBorder)

        Timer {
            id: disarm
            interval: 3000
            onTriggered: mb.armed = false
        }
        Timer {
            id: flashT
            interval: 180
            onTriggered: mb.flash = false
        }
        BarText {
            id: lbl
            anchors.centerIn: parent
            text: mb.armed ? "ТОЧНО?" : mb.label
            color: (ma.pressed || mb.flash) ? root.cBase
                 : (mb.armed ? root.cWarn : (mb.active ? root.cRust : root.cText))
        }
        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                mb.flash = true;
                flashT.restart();
                if (mb.confirm && !mb.armed) {
                    mb.armed = true;
                    disarm.restart();
                } else {
                    mb.armed = false;
                    mb.activated();
                }
            }
        }
    }

    // label + horizontal bar + value text
    component Meter: RowLayout {
        id: m
        property string label
        property real value: 0
        property string valueText
        property color barColor: root.cRust
        spacing: 10

        BarText { text: m.label; color: root.cMuted; Layout.preferredWidth: 90 }
        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: 12
            color: root.cBorder
            Rectangle {
                height: parent.height
                width: parent.width * Math.max(0, Math.min(1, m.value))
                color: m.barColor
            }
        }
        BarText {
            text: m.valueText
            Layout.preferredWidth: 110
            horizontalAlignment: Text.AlignRight
        }
    }

    // muted label + value, for detail panels
    component InfoRow: RowLayout {
        id: ir
        property string label
        property string value
        spacing: 10

        BarText { text: ir.label; color: root.cMuted; Layout.preferredWidth: 170 }
        BarText { text: ir.value; Layout.fillWidth: true; elide: Text.ElideRight }
    }

    // like Meter, but click/drag to change the value
    component Slider: RowLayout {
        id: s
        property string label
        property real value: 0
        signal moved(real v)
        spacing: 10

        BarText { text: s.label; color: root.cMuted; Layout.preferredWidth: 90 }
        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            height: 16
            color: root.cBorder
            Rectangle {
                height: parent.height
                width: parent.width * Math.max(0, Math.min(1, s.value))
                color: root.cRust
            }
            MouseArea {
                anchors.fill: parent
                onPressed: m => s.moved(Math.max(0, Math.min(1, m.x / width)))
                onPositionChanged: m => { if (pressed) s.moved(Math.max(0, Math.min(1, m.x / width))); }
            }
        }
        BarText {
            text: Math.round(s.value * 100) + "%"
            Layout.preferredWidth: 90
            horizontalAlignment: Text.AlignRight
        }
    }

    // ---- OSD: one overlay per monitor, click-through ----
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors.bottom: true
            margins.bottom: 90
            implicitWidth: 460
            implicitHeight: 70
            color: "transparent"
            visible: osdTimer.running
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region {}

            Rectangle {
                anchors.fill: parent
                color: root.cBase
                border.width: 1
                border.color: root.cBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    BarText { text: root.osdLabel; color: root.cRust; Layout.preferredWidth: 90 }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        height: 16
                        color: root.cBorder
                        Rectangle {
                            height: parent.height
                            width: parent.width * Math.max(0, Math.min(1, root.osdValue))
                            color: root.osdMuted ? root.cMuted : root.cRust
                        }
                    }
                    BarText {
                        text: root.osdMuted ? "ВЫКЛ" : Math.round(root.osdValue * 100) + "%"
                        Layout.preferredWidth: 90
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

    // ---- toasts: new notifications, top-right under the bar (click one to dismiss) ----
    PanelWindow {
        screen: Quickshell.screens[0]
        anchors {
            top: true
            right: true
        }
        margins.top: root.barHeight + 8
        margins.right: 10
        implicitWidth: 460
        implicitHeight: Math.max(1, toastCol.implicitHeight)
        color: "transparent"
        visible: !root.dnd && notifServer.trackedNotifications.values.length > 0
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        ColumnLayout {
            id: toastCol
            width: parent.width
            spacing: 8

            Repeater {
                model: notifServer.trackedNotifications

                Rectangle {
                    id: toast
                    required property var modelData
                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical

                    Layout.fillWidth: true
                    implicitHeight: toastText.implicitHeight + 24
                    color: root.cBase
                    border.width: 1
                    border.color: toast.critical ? root.cDanger : root.cRust

                    // critical notifications stay until you click them
                    Timer {
                        interval: 6000
                        running: !toast.critical
                        onTriggered: toast.modelData.expire()
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: toast.modelData.dismiss()
                    }

                    ColumnLayout {
                        id: toastText
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 12
                        spacing: 2

                        BarText {
                            Layout.fillWidth: true
                            text: toast.modelData.appName
                            color: root.cMuted
                            elide: Text.ElideRight
                        }
                        BarText {
                            Layout.fillWidth: true
                            text: toast.modelData.summary
                            elide: Text.ElideRight
                        }
                        BarText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: toast.modelData.body
                            color: root.cMuted
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    // ---- one bar per active monitor ----
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData

            // which popup is open: "", "media", "dash", "control", "session"
            property string open: ""
            function toggle(name) { open = (open === name) ? "" : name; }

            // ---- responsive bar: items drop out (in this order) before they can collide ----
            //   1. window title  2. performance stats  3. mic + network text
            // The music text in the middle never goes away. Needs are measured from the
            // items' own widths, so they do not depend on what is currently shown.
            readonly property real mediaHalf: mediaT.visible ? mediaT.width / 2 : 0
            readonly property real leftBase: 10 + launcherRow.implicitWidth
            readonly property real btW: btL.item ? btL.item.implicitWidth : 0
            readonly property real rightBase:
                10 + 20
                + uvdT.implicitWidth + dateT.implicitWidth + idleT.implicitWidth
                + volT.implicitWidth + sessT.implicitWidth
                + (root.vpnOn ? vpnT.implicitWidth : 0)
                + (root.rec ? recT.implicitWidth : 0)
                + (root.battery >= 0 ? batT.implicitWidth : 0)
                + btW
                + 24 * (2 + (root.vpnOn ? 1 : 0) + (root.rec ? 1 : 0))
                + 14 * (2 + (root.battery >= 0 ? 1 : 0) + (btW > 0 ? 1 : 0))
            readonly property real statsFull:
                cpuT.implicitWidth + memT.implicitWidth
                + (root.cpuTemp >= 0 ? tempT.implicitWidth : 0)
                + (root.gpuTemp >= 0 ? gpuT.implicitWidth : 0)
                + 14 * (1 + (root.cpuTemp >= 0 ? 1 : 0) + (root.gpuTemp >= 0 ? 1 : 0))
                + 24
            readonly property real micNetFull: micT.implicitWidth + netT.implicitWidth + 28
            // room each side may use. Without music playing the sides share the whole bar.
            readonly property real availR: mediaT.visible ? width / 2 - mediaHalf - 24
                                                          : width - leftBase - 24
            readonly property real availL: mediaT.visible ? width / 2 - mediaHalf - 24
                                                          : width - rightBase - 24
            readonly property bool showStats: rightBase + statsFull + micNetFull <= availR
            readonly property bool showMicNet: rightBase + micNetFull <= availR
            readonly property bool showTitle: leftBase + 20 + 120 <= availL
            readonly property real titleMax: Math.max(0, Math.min(width * 0.3, availL - leftBase - 20))
            onOpenChanged: {
                if (open === "control") ctlStatus.running = true;
                if (open === "ws") Hyprland.refreshToplevels();   // fresh window positions for the preview
                if (open !== "dash") root.monthOffset = 0;   // calendar returns to this month
            }

            // ---- hover-to-open: a popup opens shortly after the pointer rests on its
            // trigger and closes shortly after the pointer leaves both trigger and popup ----
            property string pending: ""
            property int previewWs: 1       // workspace shown in the preview popup
            property real previewX: 0       // where that workspace's button sits on the bar
            function hoverIn(name) {
                closeTimer.stop();
                if (open === name) {
                    openTimer.stop();
                    return;
                }
                pending = name;
                openTimer.restart();
            }
            function hoverOut(name) {
                if (pending === name)
                    openTimer.stop();
                closeTimer.restart();
            }
            function popupHover(h) {
                if (h) closeTimer.stop();
                else closeTimer.restart();
            }
            Timer {
                id: openTimer
                interval: 100
                onTriggered: panel.open = panel.pending
            }
            Timer {
                id: closeTimer
                interval: 350
                onTriggered: panel.open = ""
            }

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: root.barHeight
            color: root.cBase

            IdleInhibitor {
                window: panel
                enabled: root.idleInhibit
            }

            // bottom border line
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                height: 1
                color: root.cBorder
            }

            // ================= LEFT =================
            RowLayout {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 10
                }
                spacing: 20

                // launcher + workspaces
                RowLayout {
                    id: launcherRow
                    spacing: 10

                    BarText {
                        text: "ПУСК"
                        color: root.cRust
                        HoverArea {
                            onClicked: Quickshell.execDetached(["rofi", "-show", "drun"])
                        }
                    }

                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: 10

                            Rectangle {
                                id: wsBtn
                                required property int index
                                readonly property int wsId: index + 1
                                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                                readonly property bool isFocused: Hyprland.focusedWorkspace?.id === wsId
                                readonly property bool isUrgent: ws !== undefined && ws.urgent

                                Layout.preferredWidth: Math.round(22 * root.uiScale)
                                Layout.preferredHeight: Math.round(18 * root.uiScale)
                                Layout.alignment: Qt.AlignVCenter
                                color: isFocused ? root.cRust : (wsMa.containsMouse ? root.cHover : "transparent")
                                border.width: 1
                                border.color: isUrgent ? root.cDanger : (isFocused ? root.cRust : "transparent")

                                BarText {
                                    anchors.centerIn: parent
                                    text: root.wsNames[wsBtn.index]
                                    color: wsBtn.isFocused ? root.cBase
                                         : (wsBtn.ws !== undefined ? root.cText : root.cMuted)
                                }

                                MouseArea {
                                    id: wsMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    // hover a workspace that has windows to preview it
                                    onEntered: {
                                        if (wsBtn.ws === undefined) return;
                                        panel.previewWs = wsBtn.wsId;
                                        panel.previewX = wsBtn.mapToItem(null, 0, 0).x;
                                        panel.hoverIn("ws");
                                    }
                                    onExited: panel.hoverOut("ws")
                                    // hyprctl speaks the Lua dispatch syntax on Hyprland 0.55+
                                    onClicked: Quickshell.execDetached([
                                        "hyprctl", "dispatch",
                                        'hl.dsp.focus({ workspace = "' + wsBtn.wsId + '" })'
                                    ])
                                }
                            }
                        }
                    }
                }

                // window title (truncated like truncate_title_after_length = 80)
                BarText {
                    id: titleT
                    visible: panel.showTitle
                    readonly property string raw: Hyprland.activeToplevel?.title ?? ""
                    text: raw.length > 80 ? raw.slice(0, 80) + "…" : raw
                    elide: Text.ElideRight
                    Layout.maximumWidth: panel.titleMax
                }
            }

            // ================= CENTER =================
            BarText {
                id: mediaT
                anchors.centerIn: parent
                text: root.mediaText
                visible: root.mediaText !== ""
                elide: Text.ElideRight
                width: Math.min(implicitWidth, panel.width * 0.25)
                HoverArea {
                    onEntered: panel.hoverIn("media")
                    onExited: panel.hoverOut("media")
                    onClicked: if (root.player) root.player.togglePlaying()
                }
            }

            // ================= RIGHT =================
            RowLayout {
                anchors {
                    right: parent.right
                    top: parent.top
                    bottom: parent.bottom
                    rightMargin: 10
                }
                spacing: 24

                // system group
                RowLayout {
                    spacing: 14
                    visible: panel.showStats
                    BarText { id: cpuT; text: "ЦП " + root.cpu + "%" }
                    BarText { id: memT; text: "ОЗУ " + root.memUsed + "/" + root.memTotal + "ГБ" }
                    BarText { id: tempT; text: "ТЕМП " + root.cpuTemp + "°"; visible: root.cpuTemp >= 0 }
                    BarText { id: gpuT; text: "ГП " + root.gpuTemp + "°"; visible: root.gpuTemp >= 0 }
                }

                // VPN (hidden when off)
                BarText {
                    id: vpnT
                    text: "ВПН"
                    visible: root.vpnOn
                }

                // screen recording indicator (start/stop with SUPER + R)
                BarText {
                    id: recT
                    text: "ЗАП"
                    color: root.cDanger
                    visible: root.rec
                }

                // notifications: hover for the history
                BarText {
                    id: uvdT
                    text: root.dnd ? "УВД --" : "УВД " + history.count
                    color: (root.dnd || history.count === 0) ? root.cMuted : root.cText
                    HoverArea {
                        onEntered: panel.hoverIn("notif")
                        onExited: panel.hoverOut("notif")
                    }
                }

                // clock + settings indicators
                RowLayout {
                    spacing: 14

                    // click: dashboard
                    BarText {
                        id: dateT
                        text: root.dateStr
                        color: panel.open === "dash" ? root.cRust : root.cText
                        HoverArea {
                            onEntered: panel.hoverIn("dash")
                            onExited: panel.hoverOut("dash")
                        }
                    }

                    // idle inhibitor: click to toggle
                    BarText {
                        id: idleT
                        text: root.idleInhibit ? "БДИ" : "СОН"
                        color: root.idleInhibit ? root.cRust : root.cMuted
                        HoverArea {
                            onClicked: root.idleInhibit = !root.idleInhibit
                        }
                    }

                    // audio: click to mute
                    BarText {
                        id: volT
                        text: root.volText
                        HoverArea {
                            onEntered: panel.hoverIn("control")
                            onExited: panel.hoverOut("control")
                            onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                        }
                    }

                    // microphone: click to mute
                    BarText {
                        id: micT
                        visible: panel.showMicNet
                        text: root.micText
                        HoverArea {
                            onEntered: panel.hoverIn("control")
                            onExited: panel.hoverOut("control")
                            onClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
                        }
                    }

                    // network: click for the control panel
                    BarText {
                        id: netT
                        visible: panel.showMicNet
                        text: root.netType === "wifi" ? "WI-FI" : (root.netType === "ethernet" ? "ЛАН" : "НЕТ СЕТИ")
                        color: panel.open === "net" ? root.cRust
                             : (root.netType === "none" ? root.cMuted : root.cText)
                        HoverArea {
                            onEntered: panel.hoverIn("net")
                            onExited: panel.hoverOut("net")
                        }
                    }

                    // battery (laptop only)
                    BarText {
                        id: batT
                        visible: root.battery >= 0
                        text: "БАТ " + root.battery + "%" + (root.charging ? "+" : "")
                        color: (root.battery <= 15 && !root.charging) ? root.cDanger
                             : (root.battery <= 30 && !root.charging ? root.cWarn : root.cText)
                        HoverArea {
                            onEntered: panel.hoverIn("bat")
                            onExited: panel.hoverOut("bat")
                        }
                    }

                    // bluetooth (laptop only; separate file so a missing module can't break the bar)
                    Loader {
                        id: btL
                        source: "bluetooth.qml"
                        visible: status === Loader.Ready && item.visible
                        onLoaded: {
                            item.fontFamily = root.fontFamily;
                            item.fontPixelSize = root.fontSize;
                        }
                        HoverArea {
                            onEntered: panel.hoverIn("bluetooth")
                            onExited: panel.hoverOut("bluetooth")
                        }
                    }
                }

                // session menu
                BarText {
                    id: sessT
                    text: "ПИТ"
                    color: panel.open === "session" ? root.cWarn : root.cRust
                    HoverArea {
                        onEntered: panel.hoverIn("session")
                        onExited: panel.hoverOut("session")
                    }
                }
            }

            // ================= POPUPS =================

            // ---- media panel: cover art, info, player switcher, seek bar, controls ----
            PopupWindow {
                id: mediaPopup
                anchor.window: panel
                anchor.rect.x: (panel.width - implicitWidth) / 2
                anchor.rect.y: panel.height
                implicitWidth: 720
                implicitHeight: 272
                visible: panel.open === "media"
                color: "transparent"

                // keeps the progress bar moving while the panel is open
                Timer {
                    interval: 1000
                    repeat: true
                    running: mediaPopup.visible && root.player !== null && root.player.isPlaying
                    onTriggered: if (root.player) root.player.positionChanged()
                }

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 18

                        // album cover (shows a note symbol when there is no art)
                        Rectangle {
                            Layout.preferredWidth: 224
                            Layout.preferredHeight: 224
                            Layout.alignment: Qt.AlignTop
                            color: "#262320"
                            border.width: 1
                            border.color: root.cBorder

                            Image {
                                id: cover
                                anchors.fill: parent
                                anchors.margins: 1
                                source: root.player ? (root.player.trackArtUrl || "") : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            BarText {
                                anchors.centerIn: parent
                                text: "♪"
                                color: root.cMuted
                                font.pixelSize: 56
                                visible: cover.status !== Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 6

                            // source switcher: one button per running player
                            RowLayout {
                                spacing: 6
                                Repeater {
                                    model: Mpris.players
                                    MenuBtn {
                                        required property var modelData
                                        label: modelData.identity
                                        active: modelData === root.player
                                        onActivated: root.pickedPlayer = modelData
                                    }
                                }
                            }

                            BarText {
                                Layout.fillWidth: true
                                text: root.player ? (root.player.trackTitle || "—") : "Ничего не играет"
                                font.pixelSize: 28
                                elide: Text.ElideRight
                            }
                            BarText {
                                Layout.fillWidth: true
                                text: root.player ? (root.player.trackArtist || "") : ""
                                color: root.cText
                                elide: Text.ElideRight
                            }
                            BarText {
                                Layout.fillWidth: true
                                text: root.player ? (root.player.trackAlbum || "") : ""
                                color: root.cMuted
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            // seek bar: click to jump
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                visible: root.player !== null && root.player.length > 0

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 14
                                    color: root.cBorder

                                    Rectangle {
                                        height: parent.height
                                        width: root.player && root.player.length > 0
                                            ? parent.width * Math.min(1, root.player.position / root.player.length)
                                            : 0
                                        color: root.cRust
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: m => {
                                            if (root.player && root.player.canSeek)
                                                root.player.position = (m.x / width) * root.player.length;
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.fillWidth: true
                                    BarText { text: root.player ? root.fmt(root.player.position) : ""; color: root.cMuted }
                                    Item { Layout.fillWidth: true }
                                    BarText { text: root.player ? root.fmt(root.player.length) : ""; color: root.cMuted }
                                }
                            }

                            // controls
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8

                                MenuBtn {
                                    visible: root.player !== null && root.player.shuffleSupported
                                    label: "ПЕРЕМ"
                                    active: root.player !== null && root.player.shuffle
                                    onActivated: root.player.shuffle = !root.player.shuffle
                                }
                                MenuBtn {
                                    label: "◄◄"
                                    onActivated: if (root.player) root.player.previous()
                                }
                                MenuBtn {
                                    label: root.player && root.player.isPlaying ? "║" : "►"
                                    onActivated: if (root.player) root.player.togglePlaying()
                                }
                                MenuBtn {
                                    label: "►►"
                                    onActivated: if (root.player) root.player.next()
                                }
                            }
                        }
                    }
                }
            }

            // ---- dashboard: clock, calendar, weather, resources ----
            PopupWindow {
                id: dashPopup
                anchor.window: panel
                anchor.rect.x: panel.width - implicitWidth - 10
                anchor.rect.y: panel.height
                implicitWidth: 780
                implicitHeight: 420
                visible: panel.open === "dash"
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    // scroll anywhere on the dashboard to change month (up = earlier)
                    WheelHandler {
                        onWheel: event => { root.monthOffset += event.angleDelta.y > 0 ? -1 : 1; }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 24

                        // left: clock, weather, resources
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            BarText {
                                text: Qt.formatTime(clock.date, "HH:mm")
                                color: root.cRust
                                font.pixelSize: 56   // 4 x 14: stays sharp
                            }
                            BarText { text: root.dayStr; color: root.cMuted }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.cBorder }

                            BarText {
                                Layout.fillWidth: true
                                visible: root.weatherEnabled
                                text: "ПОГОДА  " + root.weather
                                elide: Text.ElideRight
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: root.cBorder; visible: root.weatherEnabled }

                            Meter {
                                Layout.fillWidth: true
                                label: "ЦП"
                                value: root.cpu / 100
                                valueText: root.cpu + "%"
                                barColor: root.cpu > 85 ? root.cDanger : root.cRust
                            }
                            Meter {
                                Layout.fillWidth: true
                                label: "ОЗУ"
                                value: root.memTotal > 0 ? root.memUsed / root.memTotal : 0
                                valueText: root.memUsed + "/" + root.memTotal + "ГБ"
                                barColor: (root.memTotal > 0 && root.memUsed / root.memTotal > 0.9) ? root.cDanger : root.cRust
                            }
                            Meter {
                                Layout.fillWidth: true
                                visible: root.cpuTemp >= 0
                                label: "ТЕМП"
                                value: root.cpuTemp / 100
                                valueText: root.cpuTemp + "°"
                                barColor: root.cpuTemp > 85 ? root.cDanger : root.cRust
                            }
                            Meter {
                                Layout.fillWidth: true
                                visible: root.gpuTemp >= 0
                                label: "ГП"
                                value: root.gpuTemp / 100
                                valueText: root.gpuTemp + "°"
                                barColor: root.gpuTemp > 85 ? root.cDanger : root.cRust
                            }
                            Meter {
                                Layout.fillWidth: true
                                visible: root.battery >= 0
                                label: "БАТ"
                                value: root.battery / 100
                                valueText: root.battery + "%" + (root.charging ? "+" : "")
                                barColor: (root.battery <= 15 && !root.charging) ? root.cDanger : root.cRust
                            }

                            Item { Layout.fillHeight: true }
                        }

                        // right: calendar
                        ColumnLayout {
                            Layout.alignment: Qt.AlignTop
                            spacing: 6

                            // month header: ◄ previous, click the name to jump back to today, ► next
                            RowLayout {
                                Layout.fillWidth: true

                                BarText {
                                    text: "◄"
                                    HoverArea { onClicked: root.monthOffset -= 1 }
                                }
                                BarText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.monthStr
                                    color: root.monthOffset === 0 ? root.cRust : root.cWarn
                                    HoverArea { onClicked: root.monthOffset = 0 }
                                }
                                BarText {
                                    text: "►"
                                    HoverArea { onClicked: root.monthOffset += 1 }
                                }
                            }

                            GridLayout {
                                columns: 7
                                rowSpacing: 2
                                columnSpacing: 2

                                Repeater {
                                    model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
                                    BarText {
                                        required property string modelData
                                        text: modelData
                                        color: root.cMuted
                                        Layout.preferredWidth: 46
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }

                                Repeater {
                                    model: 42
                                    BarText {
                                        id: cell
                                        required property int index
                                        // Monday-first offset of the 1st, and length of the month
                                        readonly property int first: (root.viewDate.getDay() + 6) % 7
                                        readonly property int dim: new Date(root.viewDate.getFullYear(), root.viewDate.getMonth() + 1, 0).getDate()
                                        readonly property int day: index - first + 1
                                        readonly property bool today: root.monthOffset === 0 && day === clock.date.getDate()

                                        text: (day >= 1 && day <= dim) ? String(day) : ""
                                        color: today ? root.cBase : root.cText
                                        Layout.preferredWidth: 46
                                        Layout.preferredHeight: 34
                                        horizontalAlignment: Text.AlignHCenter

                                        Rectangle {
                                            anchors.fill: parent
                                            z: -1
                                            color: root.cRust
                                            visible: cell.today && cell.day >= 1 && cell.day <= cell.dim
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- control panel: toggles + volume ----
            PopupWindow {
                id: controlPopup
                anchor.window: panel
                anchor.rect.x: panel.width - implicitWidth - 10
                anchor.rect.y: panel.height
                implicitWidth: 560
                implicitHeight: 380
                visible: panel.open === "control"
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        BarText { text: "УПРАВЛЕНИЕ"; color: root.cRust }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            rowSpacing: 8
                            columnSpacing: 8

                            MenuBtn {
                                Layout.fillWidth: true
                                label: "WI-FI " + (root.wifi === "enabled" ? "ВКЛ" : (root.wifi === "disabled" ? "ВЫКЛ" : "--"))
                                active: root.wifi === "enabled"
                                onActivated: root.ctl("wifi")
                            }
                            MenuBtn {
                                Layout.fillWidth: true
                                label: "BT " + (root.bt === "yes" ? "ВКЛ" : (root.bt === "no" ? "ВЫКЛ" : "--"))
                                active: root.bt === "yes"
                                onActivated: root.ctl("bt")
                            }
                            MenuBtn {
                                Layout.fillWidth: true
                                label: "ВПН " + (root.vpnOn ? "ВКЛ" : "ВЫКЛ")
                                active: root.vpnOn
                                onActivated: root.ctl("vpn")
                            }
                            MenuBtn {
                                Layout.fillWidth: true
                                label: root.idleInhibit ? "БДИ" : "СОН"
                                active: root.idleInhibit
                                onActivated: root.idleInhibit = !root.idleInhibit
                            }
                            MenuBtn {
                                Layout.fillWidth: true
                                Layout.columnSpan: 2
                                label: "ПИТАНИЕ " + root.profile
                                onActivated: root.ctl("profile")
                            }
                            MenuBtn {
                                Layout.fillWidth: true
                                label: "СЕТИ ►"
                                onActivated: panel.open = "net"
                            }
                            MenuBtn {
                                Layout.fillWidth: true
                                label: "BT СПИСОК ►"
                                onActivated: panel.open = "bluetooth"
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: root.cBorder }

                        Slider {
                            Layout.fillWidth: true
                            label: "ГРМ"
                            value: root.sink?.audio ? root.sink.audio.volume : 0
                            onMoved: v => { if (root.sink?.audio) root.sink.audio.volume = v; }
                        }
                        Slider {
                            Layout.fillWidth: true
                            label: "МИК"
                            value: root.source?.audio ? root.source.audio.volume : 0
                            onMoved: v => { if (root.source?.audio) root.source.audio.volume = v; }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ---- Wi-Fi list (nmcli): hover the network label ----
            PopupWindow {
                id: netPopup
                anchor.window: panel
                anchor.rect.x: panel.width - implicitWidth - 10
                anchor.rect.y: panel.height
                implicitWidth: 520
                implicitHeight: 420
                visible: panel.open === "net"
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    Loader {
                        anchors.fill: parent
                        active: panel.open === "net"
                        source: "netpanel.qml"
                        onLoaded: {
                            item.fontFamily = root.fontFamily;
                            item.fontPixelSize = root.fontSize;
                        }
                    }
                }
            }

            // ---- Bluetooth devices: hover the BT label (own file, needs the Bluetooth module) ----
            PopupWindow {
                id: btPopup
                anchor.window: panel
                anchor.rect.x: panel.width - implicitWidth - 10
                anchor.rect.y: panel.height
                implicitWidth: 520
                implicitHeight: 420
                visible: panel.open === "bluetooth"
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    Loader {
                        anchors.fill: parent
                        active: panel.open === "bluetooth"
                        source: "btpanel.qml"
                        onLoaded: {
                            item.fontFamily = root.fontFamily;
                            item.fontPixelSize = root.fontSize;
                        }
                    }
                }
            }

            // ---- notification history: click an entry to remove it ----
            PopupWindow {
                id: notifPopup
                anchor.window: panel
                anchor.rect.x: panel.width - implicitWidth - 10
                anchor.rect.y: panel.height
                implicitWidth: 520
                implicitHeight: 420
                visible: panel.open === "notif"
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            BarText { text: "УВЕДОМЛЕНИЯ"; color: root.cRust }
                            Item { Layout.fillWidth: true }
                            MenuBtn {
                                label: "НЕ БЕСП"
                                active: root.dnd
                                onActivated: root.dnd = !root.dnd
                            }
                            MenuBtn {
                                label: "ОЧИСТИТЬ"
                                onActivated: history.clear()
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: root.cBorder }

                        BarText { visible: history.count === 0; text: "ПУСТО"; color: root.cMuted }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: history.count > 0
                            clip: true
                            spacing: 8
                            model: history

                            delegate: Rectangle {
                                id: entry
                                required property int index
                                required property string app
                                required property string summary
                                required property string body
                                required property bool critical
                                required property string time

                                width: ListView.view.width
                                implicitHeight: entryCol.implicitHeight + 16
                                color: eMa.containsMouse ? root.cHover : "transparent"
                                border.width: 1
                                border.color: entry.critical ? root.cDanger : root.cBorder

                                MouseArea {
                                    id: eMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: history.remove(entry.index)
                                }

                                ColumnLayout {
                                    id: entryCol
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 8
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        BarText { Layout.fillWidth: true; text: entry.app; color: root.cMuted; elide: Text.ElideRight }
                                        BarText { text: entry.time; color: root.cMuted }
                                    }
                                    BarText { Layout.fillWidth: true; text: entry.summary; elide: Text.ElideRight }
                                    BarText {
                                        Layout.fillWidth: true
                                        visible: text !== ""
                                        text: entry.body
                                        color: root.cMuted
                                        textFormat: Text.PlainText
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- battery details (only reachable on a machine with a battery) ----
            PopupWindow {
                id: batPopup
                anchor.window: panel
                anchor.rect.x: panel.width - implicitWidth - 10
                anchor.rect.y: panel.height
                implicitWidth: 460
                implicitHeight: 240
                visible: panel.open === "bat"
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        BarText { text: "БАТАРЕЯ"; color: root.cRust }

                        Meter {
                            Layout.fillWidth: true
                            label: "ЗАРЯД"
                            value: root.battery / 100
                            valueText: root.battery + "%" + (root.charging ? "+" : "")
                            barColor: (root.battery <= 15 && !root.charging) ? root.cDanger : root.cRust
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: root.cBorder }

                        InfoRow {
                            Layout.fillWidth: true
                            label: "СОСТОЯНИЕ"
                            value: root.charging ? "ЗАРЯДКА" : (root.battery >= 100 ? "ПОЛНАЯ" : "РАЗРЯД")
                        }
                        InfoRow {
                            Layout.fillWidth: true
                            visible: root.battMins >= 0
                            label: root.charging ? "ДО ПОЛНОЙ" : "ОСТАЛОСЬ"
                            value: Math.floor(root.battMins / 60) + ":" + ("0" + (root.battMins % 60)).slice(-2)
                        }
                        InfoRow {
                            Layout.fillWidth: true
                            visible: root.watts10 >= 0
                            label: "МОЩНОСТЬ"
                            value: (root.watts10 / 10).toFixed(1) + " Вт"
                        }
                        InfoRow {
                            Layout.fillWidth: true
                            visible: root.battHealth >= 0
                            label: "ЗДОРОВЬЕ"
                            value: root.battHealth + "%"
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ---- workspace preview (hover a workspace button) ----
            PopupWindow {
                id: wsPopup
                anchor.window: panel
                anchor.rect.x: Math.max(0, Math.min(panel.previewX, panel.width - implicitWidth - 10))
                anchor.rect.y: panel.height
                implicitWidth: 520
                implicitHeight: Math.round((implicitWidth - 20) * panel.screen.height / panel.screen.width) + 20
                visible: panel.open === "ws"
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    // separate file: if screen capture isn't available, only this fails
                    Loader {
                        id: pvLoader
                        anchors.fill: parent
                        anchors.margins: 10
                        source: "workspacepreview.qml"
                        onLoaded: {
                            item.fontFamily = root.fontFamily;
                            item.fontPixelSize = root.fontSize;
                        }
                    }
                    Binding { target: pvLoader.item; property: "wsId"; value: panel.previewWs; when: pvLoader.item !== null }
                    Binding { target: pvLoader.item; property: "screenObj"; value: panel.screen; when: pvLoader.item !== null }
                }
            }

            // ---- session menu ----
            PopupWindow {
                id: sessionPopup
                anchor.window: panel
                anchor.rect.x: panel.width - implicitWidth - 10
                anchor.rect.y: panel.height
                implicitWidth: 260
                implicitHeight: 330
                visible: panel.open === "session"
                color: "transparent"

                Rectangle {
                    anchors.fill: parent
                    color: root.cBase
                    border.width: 1
                    border.color: root.cBorder

                    HoverHandler { onHoveredChanged: panel.popupHover(hovered) }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        BarText { text: "СЕАНС"; color: root.cRust }

                        MenuBtn {
                            Layout.fillWidth: true
                            label: "БЛОК"
                            onActivated: { panel.open = ""; Quickshell.execDetached(["hyprlock"]); }
                        }
                        MenuBtn {
                            Layout.fillWidth: true
                            label: "ВЫХОД"
                            confirm: true
                            onActivated: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
                        }
                        MenuBtn {
                            Layout.fillWidth: true
                            label: "ГИБЕРНАЦИЯ"
                            onActivated: { panel.open = ""; Quickshell.execDetached(["sh", "-c", "sleep 1; systemctl hibernate"]); }
                        }
                        MenuBtn {
                            Layout.fillWidth: true
                            label: "ПЕРЕЗАГР"
                            confirm: true
                            onActivated: Quickshell.execDetached(["systemctl", "reboot"])
                        }
                        MenuBtn {
                            Layout.fillWidth: true
                            label: "ВЫКЛ"
                            confirm: true
                            onActivated: Quickshell.execDetached(["systemctl", "poweroff"])
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
