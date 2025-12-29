pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var monitors: []

    function updateWindowList() {
        getClients.running = true
    }

    function updateMonitors() {
        getMonitors.running = true
    }

    function updateAll() {
        updateWindowList()
        updateMonitors()
    }

    Component.onCompleted: {
        updateAll()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            updateAll()
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        property string output: ""

        stdout: SplitParser {
            onRead: data => { getClients.output += data }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && getClients.output) {
                try {
                    root.windowList = JSON.parse(getClients.output)
                    let tempWinByAddress = {}
                    for (var i = 0; i < root.windowList.length; ++i) {
                        var win = root.windowList[i]
                        tempWinByAddress[win.address] = win
                    }
                    root.windowByAddress = tempWinByAddress
                    root.addresses = root.windowList.map(win => win.address)
                } catch (e) {
                    console.log("Failed to parse clients:", e)
                }
            }
            getClients.output = ""
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        property string output: ""

        stdout: SplitParser {
            onRead: data => { getMonitors.output += data }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode === 0 && getMonitors.output) {
                try {
                    root.monitors = JSON.parse(getMonitors.output)
                } catch (e) {
                    console.log("Failed to parse monitors:", e)
                }
            }
            getMonitors.output = ""
        }
    }
}
