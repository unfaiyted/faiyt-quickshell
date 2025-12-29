pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: bluetoothService

    // State
    property var adapters: []
    property int selectedAdapterIndex: 0
    property var devices: []  // Paired/connected devices
    property var discoveredDevices: []  // Unpaired discovered devices
    property bool scanning: false
    property string connectingMac: ""

    // Current adapter
    property var currentAdapter: adapters.length > 0 ? adapters[selectedAdapterIndex] : null
    property bool powered: currentAdapter ? currentAdapter.powered : false

    // Get adapters list
    Process {
        id: listAdaptersProcess
        command: ["bluetoothctl", "list"]
        running: true

        property var tempAdapters: []

        stdout: SplitParser {
            onRead: data => {
                const match = data.match(/Controller\s+([0-9A-Fa-f:]+)\s+(.+?)(\s+\[default\])?$/)
                if (match) {
                    listAdaptersProcess.tempAdapters.push({
                        mac: match[1],
                        name: match[2].trim(),
                        isDefault: !!match[3],
                        powered: false
                    })
                }
            }
        }

        onRunningChanged: {
            if (!running && tempAdapters.length > 0) {
                adapterIndex = 0
                checkAdapterPower()
            }
        }
    }

    property int adapterIndex: 0

    function checkAdapterPower() {
        if (adapterIndex < listAdaptersProcess.tempAdapters.length) {
            adapterPowerProcess.adapterMac = listAdaptersProcess.tempAdapters[adapterIndex].mac
            adapterPowerProcess.running = true
        } else {
            bluetoothService.adapters = listAdaptersProcess.tempAdapters
            listAdaptersProcess.tempAdapters = []
            refreshDevices()
        }
    }

    Process {
        id: adapterPowerProcess
        property string adapterMac: ""
        command: ["bluetoothctl", "show", adapterMac]

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("Powered: yes")) {
                    listAdaptersProcess.tempAdapters[bluetoothService.adapterIndex].powered = true
                }
                if (data.includes("Discovering: yes")) {
                    bluetoothService.scanning = true
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                bluetoothService.adapterIndex++
                checkAdapterPower()
            }
        }
    }

    // Get devices via DBus
    Process {
        id: getDevicesProcess
        property string adapterMac: currentAdapter ? currentAdapter.mac : ""
        command: ["bash", "-c",
            "hci_name=''; " +
            "for i in 0 1 2 3; do " +
            "  mac=$(busctl --system get-property org.bluez /org/bluez/hci$i org.bluez.Adapter1 Address 2>/dev/null | grep -oE '[0-9A-F:]+'); " +
            "  if [ \"$mac\" = \"" + adapterMac + "\" ]; then hci_name=\"hci$i\"; break; fi; " +
            "done; " +
            "if [ -n \"$hci_name\" ]; then " +
            "  busctl --system call org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null | " +
            "  grep -oE \"/org/bluez/$hci_name/dev_[A-F0-9_]+\" | sed 's|.*/dev_||' | tr '_' ':' | sort -u; " +
            "fi"
        ]

        property var deviceMacs: []

        stdout: SplitParser {
            onRead: data => {
                const mac = data.trim()
                if (mac && mac.match(/^[0-9A-Fa-f:]+$/)) {
                    getDevicesProcess.deviceMacs.push(mac)
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                if (deviceMacs.length > 0) {
                    bluetoothService.pendingDevices = []
                    bluetoothService.pendingDiscovered = []
                    bluetoothService.deviceIndex = 0
                    bluetoothService.deviceMacsToCheck = deviceMacs
                    findHciProcess.running = true
                    deviceMacs = []
                } else {
                    bluetoothService.devices = []
                    bluetoothService.discoveredDevices = []
                }
            }
        }
    }

    Process {
        id: findHciProcess
        property string adapterMac: currentAdapter ? currentAdapter.mac : ""
        command: ["bash", "-c",
            "for i in 0 1 2 3; do " +
            "  mac=$(busctl --system get-property org.bluez /org/bluez/hci$i org.bluez.Adapter1 Address 2>/dev/null | grep -oE '[0-9A-F:]+'); " +
            "  if [ \"$mac\" = \"" + adapterMac + "\" ]; then echo \"hci$i\"; break; fi; " +
            "done"
        ]

        stdout: SplitParser {
            onRead: data => {
                bluetoothService.currentHci = data.trim()
            }
        }

        onRunningChanged: {
            if (!running) {
                checkNextDevice()
            }
        }
    }

    property var pendingDevices: []
    property var pendingDiscovered: []
    property var deviceMacsToCheck: []
    property int deviceIndex: 0
    property string currentHci: ""

    function checkNextDevice() {
        if (deviceIndex < deviceMacsToCheck.length) {
            let mac = deviceMacsToCheck[deviceIndex]
            let macUnderscore = mac.replace(/:/g, "_")
            deviceInfoProcess.devicePath = "/org/bluez/" + currentHci + "/dev_" + macUnderscore
            deviceInfoProcess.mac = mac
            deviceInfoProcess.running = true
        } else {
            pendingDevices.sort((a, b) => (b.connected ? 1 : 0) - (a.connected ? 1 : 0))
            bluetoothService.devices = pendingDevices
            bluetoothService.discoveredDevices = pendingDiscovered
            pendingDevices = []
            pendingDiscovered = []
            deviceMacsToCheck = []
        }
    }

    Process {
        id: deviceInfoProcess
        property string mac: ""
        property string devicePath: ""
        command: ["bash", "-c",
            "path='" + devicePath + "'; " +
            "name=$(busctl --system get-property org.bluez $path org.bluez.Device1 Alias 2>/dev/null | sed \"s/s //\" | tr -d '\"'); " +
            "paired=$(busctl --system get-property org.bluez $path org.bluez.Device1 Paired 2>/dev/null | grep -c 'true'); " +
            "connected=$(busctl --system get-property org.bluez $path org.bluez.Device1 Connected 2>/dev/null | grep -c 'true'); " +
            "icon=$(busctl --system get-property org.bluez $path org.bluez.Device1 Icon 2>/dev/null | sed \"s/s //\" | tr -d '\"'); " +
            "battery=$(busctl --system get-property org.bluez $path org.bluez.Battery1 Percentage 2>/dev/null | grep -oE '[0-9]+' || echo '-1'); " +
            "echo \"$name|$paired|$connected|$icon|$battery\""
        ]

        stdout: SplitParser {
            onRead: data => {
                let parts = data.split("|")
                if (parts.length >= 5) {
                    let name = parts[0] || deviceInfoProcess.mac
                    let paired = parts[1] === "1"
                    let connected = parts[2] === "1"
                    let icon = parts[3] || ""
                    let battery = parseInt(parts[4]) || -1

                    let deviceInfo = {
                        mac: deviceInfoProcess.mac,
                        name: name,
                        paired: paired,
                        connected: connected,
                        icon: icon,
                        battery: battery
                    }

                    if (paired || connected) {
                        bluetoothService.pendingDevices.push(deviceInfo)
                    } else if (name && name !== deviceInfoProcess.mac) {
                        bluetoothService.pendingDiscovered.push(deviceInfo)
                    }
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                bluetoothService.deviceIndex++
                checkNextDevice()
            }
        }
    }

    // Power toggle
    Process {
        id: powerProcess
        property string adapterMac: ""
        property bool powerOn: false
        command: ["bash", "-c", "bluetoothctl select " + adapterMac + " && bluetoothctl power " + (powerOn ? "on" : "off")]
        onRunningChanged: {
            if (!running) refresh()
        }
    }

    // Persistent bluetoothctl process for scanning
    Process {
        id: scannerProcess
        command: ["bluetoothctl"]
        running: true
        stdinEnabled: true

        stdout: SplitParser {
            onRead: data => {
                const newMatch = data.match(/\[NEW\] Device ([0-9A-Fa-f:]+) (.+)/)
                if (newMatch) {
                    const mac = newMatch[1]
                    const name = newMatch[2]
                    const existsInDevices = bluetoothService.devices.some(d => d.mac === mac)
                    const existsInDiscovered = bluetoothService.discoveredDevices.some(d => d.mac === mac)
                    if (!existsInDevices && !existsInDiscovered) {
                        let newList = bluetoothService.discoveredDevices.slice()
                        newList.push({
                            mac: mac,
                            name: name,
                            paired: false,
                            connected: false,
                            icon: "",
                            battery: -1
                        })
                        bluetoothService.discoveredDevices = newList
                    }
                    return
                }

                const chgMatch = data.match(/\[CHG\] Device ([0-9A-Fa-f:]+) (\w+): (.+)/)
                if (chgMatch) {
                    const mac = chgMatch[1]
                    const prop = chgMatch[2]
                    const value = chgMatch[3]

                    let idx = bluetoothService.discoveredDevices.findIndex(d => d.mac === mac)
                    if (idx >= 0) {
                        let newList = bluetoothService.discoveredDevices.slice()
                        if (prop === "Name" || prop === "Alias") {
                            newList[idx].name = value
                        } else if (prop === "Icon") {
                            newList[idx].icon = value
                        }
                        bluetoothService.discoveredDevices = newList
                    }
                    return
                }

                const delMatch = data.match(/\[DEL\] Device ([0-9A-Fa-f:]+)/)
                if (delMatch) {
                    const mac = delMatch[1]
                    bluetoothService.discoveredDevices = bluetoothService.discoveredDevices.filter(d => d.mac !== mac)
                    return
                }

                if (data.includes("Discovery started")) {
                    bluetoothService.scanning = true
                } else if (data.includes("Discovery stopped")) {
                    bluetoothService.scanning = false
                }
            }
        }

        function selectAdapter(mac) {
            write("select " + mac + "\n")
        }

        function startScan() {
            if (bluetoothService.currentAdapter) {
                write("select " + bluetoothService.currentAdapter.mac + "\n")
            }
            bluetoothService.discoveredDevices = []
            write("scan on\n")
        }

        function stopScan() {
            write("scan off\n")
        }
    }

    // Connect/Disconnect
    Process {
        id: connectProcess
        property string mac: ""
        command: ["bluetoothctl", "connect", mac]
        onRunningChanged: {
            if (!running) {
                bluetoothService.connectingMac = ""
                refreshDevices()
            }
        }
    }

    Process {
        id: disconnectProcess
        property string mac: ""
        command: ["bluetoothctl", "disconnect", mac]
        onRunningChanged: {
            if (!running) {
                bluetoothService.connectingMac = ""
                refreshDevices()
            }
        }
    }

    function refresh() {
        listAdaptersProcess.tempAdapters = []
        listAdaptersProcess.running = true
    }

    function refreshDevices() {
        getDevicesProcess.deviceMacs = []
        pendingDevices = []
        pendingDiscovered = []
        getDevicesProcess.running = true
    }

    function selectAdapter(index) {
        // Stop any ongoing scan first
        const wasScanning = scanning
        if (scanning) {
            scannerProcess.stopScan()
        }

        selectedAdapterIndex = index
        discoveredDevices = []

        if (currentAdapter) {
            scannerProcess.selectAdapter(currentAdapter.mac)
            // Restart scan on new adapter if was scanning
            if (wasScanning) {
                scannerProcess.startScan()
            }
        }

        refreshDevices()
    }

    function togglePower() {
        if (!currentAdapter) return
        powerProcess.adapterMac = currentAdapter.mac
        powerProcess.powerOn = !powered
        powerProcess.running = true
    }

    function toggleScanning() {
        if (!currentAdapter) return
        if (scanning) {
            scannerProcess.stopScan()
        } else {
            scannerProcess.startScan()
        }
    }

    function connectDevice(mac) {
        connectingMac = mac
        connectProcess.mac = mac
        connectProcess.running = true
    }

    function disconnectDevice(mac) {
        connectingMac = mac
        disconnectProcess.mac = mac
        disconnectProcess.running = true
    }

    onCurrentAdapterChanged: {
        if (currentAdapter && scannerProcess.running) {
            scannerProcess.selectAdapter(currentAdapter.mac)
        }
    }

    // Refresh periodically
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: refresh()
    }
}
