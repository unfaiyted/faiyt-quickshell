import QtQuick
import Quickshell
import Quickshell.Io
import "../../../services"

Item {
    id: appResults
    visible: false

    property string typeName: "app"
    property var prefixes: ["app:", "apps:", "a:"]
    property int maxResults: 10

    // Cached applications
    property var applications: []
    property bool isLoaded: false

    // Home directory
    property string homeDir: Quickshell.env("HOME") || "/home"

    // Desktop file directories
    property var desktopDirs: [
        "/usr/share/applications",
        "/usr/local/share/applications",
        homeDir + "/.local/share/applications"
    ]

    // Find .desktop files
    Process {
        id: findProcess
        command: ["bash", "-c",
            "find /usr/share/applications /usr/local/share/applications " +
            homeDir + "/.local/share/applications " +
            "-maxdepth 2 -name '*.desktop' -type f 2>/dev/null"
        ]

        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                if (data.trim()) {
                    findProcess.output += data.trim() + "\n"
                }
            }
        }

        onRunningChanged: {
            if (!running && findProcess.output) {
                parseDesktopFiles(findProcess.output.trim().split("\n"))
                findProcess.output = ""
            }
        }
    }

    // Read individual .desktop file
    Process {
        id: catProcess
        property string currentFile: ""
        property var pendingFiles: []
        property var parsedApps: []
        property string output: ""

        command: ["cat", currentFile]

        stdout: SplitParser {
            onRead: data => {
                catProcess.output += data + "\n"
            }
        }

        onRunningChanged: {
            if (!running) {
                if (output.trim()) {
                    let app = parseDesktopEntry(output, currentFile)
                    if (app) {
                        parsedApps.push(app)
                    }
                }
                output = ""
                processNextFile()
            }
        }

        function processNextFile() {
            if (pendingFiles.length > 0) {
                currentFile = pendingFiles.shift()
                running = true
            } else {
                // All files processed
                appResults.applications = parsedApps.sort((a, b) => a.name.localeCompare(b.name))
                appResults.isLoaded = true
                parsedApps = []
            }
        }
    }

    function parseDesktopFiles(files) {
        catProcess.pendingFiles = files.filter(f => f && f.endsWith(".desktop"))
        catProcess.parsedApps = []
        catProcess.processNextFile()
    }

    function parseDesktopEntry(content, filePath) {
        let lines = content.split("\n")
        let inDesktopEntry = false
        let entry = {
            name: "",
            genericName: "",
            exec: "",
            icon: "",
            comment: "",
            categories: "",
            terminal: false,
            noDisplay: false,
            hidden: false,
            filePath: filePath
        }

        for (let line of lines) {
            line = line.trim()

            if (line === "[Desktop Entry]") {
                inDesktopEntry = true
                continue
            }
            if (line.startsWith("[") && line !== "[Desktop Entry]") {
                inDesktopEntry = false
                continue
            }

            if (!inDesktopEntry) continue

            let [key, ...valueParts] = line.split("=")
            let value = valueParts.join("=")

            // Handle localized keys (use default or english)
            if (key.includes("[")) {
                let baseKey = key.split("[")[0]
                key = baseKey
            }

            switch (key) {
                case "Name":
                    if (!entry.name) entry.name = value
                    break
                case "GenericName":
                    if (!entry.genericName) entry.genericName = value
                    break
                case "Exec":
                    entry.exec = value
                    break
                case "Icon":
                    entry.icon = value
                    break
                case "Comment":
                    if (!entry.comment) entry.comment = value
                    break
                case "Categories":
                    entry.categories = value
                    break
                case "Terminal":
                    entry.terminal = (value.toLowerCase() === "true")
                    break
                case "NoDisplay":
                    entry.noDisplay = (value.toLowerCase() === "true")
                    break
                case "Hidden":
                    entry.hidden = (value.toLowerCase() === "true")
                    break
            }
        }

        // Skip hidden/noDisplay apps
        if (entry.noDisplay || entry.hidden || !entry.name || !entry.exec) {
            return null
        }

        return entry
    }

    // Search applications
    function search(query, isPrefixSearch) {
        if (!isLoaded) {
            // Trigger load if not loaded
            if (!findProcess.running) {
                findProcess.running = true
            }
            return []
        }

        let queryLower = query.toLowerCase().trim()

        // If no query and prefix search, show all apps
        // Otherwise, filter by query
        let filtered = applications.filter(app => {
            if (!queryLower) return isPrefixSearch

            let searchText = (app.name + " " + app.genericName + " " + app.comment + " " + app.categories).toLowerCase()
            return searchText.includes(queryLower)
        })

        // Sort by relevance (name starts with query first)
        filtered.sort((a, b) => {
            let aStarts = a.name.toLowerCase().startsWith(queryLower)
            let bStarts = b.name.toLowerCase().startsWith(queryLower)
            if (aStarts && !bStarts) return -1
            if (!aStarts && bStarts) return 1
            return a.name.localeCompare(b.name)
        })

        return filtered.slice(0, maxResults).map((app, index) => ({
            type: "app",
            title: app.name,
            description: app.genericName || app.comment || "",
            icon: IconService.getIcon(app.icon),
            data: app,
            action: function() {
                launchApp(app)
            }
        }))
    }

    // Launch process
    Process {
        id: launchProcess
        property string cmd: ""
        command: ["bash", "-c", cmd]
    }

    function launchApp(app) {
        // Clean up exec command (remove %u, %U, %f, %F, etc.)
        let cmd = app.exec
            .replace(/%[uUfFdDnNickvm]/g, "")
            .replace(/\s+/g, " ")
            .trim()

        if (app.terminal) {
            // Launch in terminal
            launchProcess.cmd = "kitty -e " + cmd
        } else {
            launchProcess.cmd = cmd
        }
        launchProcess.running = true
    }

    // Load apps on creation
    Component.onCompleted: {
        findProcess.running = true
    }
}
