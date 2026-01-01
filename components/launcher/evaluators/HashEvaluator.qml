import QtQuick
import Quickshell.Io

QtObject {
    property string name: "hash"

    // Supported hash algorithms and their commands
    property var algorithms: {
        "md5": "md5sum",
        "sha1": "sha1sum",
        "sha256": "sha256sum",
        "sha512": "sha512sum"
    }

    // Cache for hash results
    property var cache: ({})
    property string lastQuery: ""
    property var lastResult: null

    // Process for hash computation
    property var hashProcess: Process {
        id: hashProcess
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                hashProcess.output += data
            }
        }

        onRunningChanged: {
            if (!running && output) {
                parseResult(output)
                output = ""
            }
        }
    }

    // Debounce timer
    property var debounceTimer: Timer {
        interval: 100
        onTriggered: {
            if (pendingRequest) {
                executeHash(pendingRequest)
                pendingRequest = null
            }
        }
    }

    property var pendingRequest: null

    function evaluate(input) {
        let trimmed = input.trim()
        if (!trimmed) return null

        // Pattern: "md5 hello" or "sha256 my text here"
        let match = trimmed.match(/^(md5|sha1|sha256|sha512)\s+(.+)$/i)
        if (!match) return null

        let algo = match[1].toLowerCase()
        let text = match[2]

        let cacheKey = algo + "_" + text

        // Check cache
        if (cache[cacheKey]) {
            return cache[cacheKey]
        }

        // If we have a result for this query, return it
        if (lastQuery === cacheKey && lastResult) {
            return lastResult
        }

        // Queue the hash request
        pendingRequest = { algo: algo, text: text, cacheKey: cacheKey }
        debounceTimer.restart()

        // Return loading state
        return {
            value: "= Hashing...",
            hint: "Computing " + algo.toUpperCase(),
            copyValue: ""
        }
    }

    function executeHash(req) {
        let cmd = algorithms[req.algo]
        if (!cmd) return

        // Use printf to avoid trailing newline issues with echo
        hashProcess.command = ["bash", "-c", "printf '%s' " + escapeForShell(req.text) + " | " + cmd]
        hashProcess.output = ""
        hashProcess.pendingCacheKey = req.cacheKey
        hashProcess.pendingAlgo = req.algo

        hashProcess.running = true
    }

    function parseResult(output) {
        // Output format: "hash  -" or "hash  filename"
        let hash = output.trim().split(/\s+/)[0]
        let cacheKey = hashProcess.pendingCacheKey
        let algo = hashProcess.pendingAlgo

        if (hash && hash.length > 0) {
            let result = {
                value: "= " + hash,
                hint: "Enter to copy " + algo.toUpperCase(),
                copyValue: hash
            }

            cache[cacheKey] = result
            lastQuery = cacheKey
            lastResult = result
        }
    }

    function escapeForShell(str) {
        // Escape single quotes for shell
        return "'" + str.replace(/'/g, "'\\''") + "'"
    }
}
