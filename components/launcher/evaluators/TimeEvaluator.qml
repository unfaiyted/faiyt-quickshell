import QtQuick

QtObject {
    property string name: "time"

    // Time units in seconds
    property var timeUnits: {
        "s": 1, "sec": 1, "second": 1, "seconds": 1,
        "m": 60, "min": 60, "minute": 60, "minutes": 60,
        "h": 3600, "hr": 3600, "hour": 3600, "hours": 3600,
        "d": 86400, "day": 86400, "days": 86400,
        "w": 604800, "wk": 604800, "week": 604800, "weeks": 604800,
        "mo": 2592000, "month": 2592000, "months": 2592000,
        "y": 31536000, "yr": 31536000, "year": 31536000, "years": 31536000
    }

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern: "Xh Ym Zs to unit" - compound time to single unit
        let compoundMatch = trimmed.match(/^((?:\d+(?:\.\d+)?\s*[a-z]+\s*)+)\s+(?:to|in|as)\s+([a-z]+)$/)
        if (compoundMatch) {
            let totalSeconds = parseCompoundTime(compoundMatch[1])
            if (totalSeconds === null) return null

            let targetUnit = compoundMatch[2]
            if (!timeUnits[targetUnit]) return null

            let result = totalSeconds / timeUnits[targetUnit]
            let formatted = formatNumber(result) + " " + targetUnit
            return {
                value: "= " + formatted,
                hint: "Enter to copy",
                copyValue: formatNumber(result)
            }
        }

        // Pattern: "X unit to unit"
        let simpleMatch = trimmed.match(/^(\d+(?:\.\d+)?)\s*([a-z]+)\s+(?:to|in|as)\s+([a-z]+)$/)
        if (simpleMatch) {
            let value = parseFloat(simpleMatch[1])
            let fromUnit = simpleMatch[2]
            let toUnit = simpleMatch[3]

            if (!timeUnits[fromUnit] || !timeUnits[toUnit]) return null

            let seconds = value * timeUnits[fromUnit]
            let result = seconds / timeUnits[toUnit]
            let formatted = formatNumber(result) + " " + toUnit
            return {
                value: "= " + formatted,
                hint: "Enter to copy",
                copyValue: formatNumber(result)
            }
        }

        // Pattern: "Xh Ym Zs" - compound time, show in readable format
        let compoundOnly = trimmed.match(/^(\d+(?:\.\d+)?\s*[a-z]+)(\s+\d+(?:\.\d+)?\s*[a-z]+)+$/)
        if (compoundOnly) {
            let totalSeconds = parseCompoundTime(trimmed)
            if (totalSeconds === null) return null

            // Convert to human readable
            let readable = formatDuration(totalSeconds)
            let totalMins = Math.round(totalSeconds / 60 * 100) / 100

            return {
                value: "= " + totalMins + " min",
                hint: "Enter to copy",
                copyValue: totalMins.toString()
            }
        }

        // Pattern: Unix timestamp
        let timestampMatch = trimmed.match(/^(\d{10,13})$/)
        if (timestampMatch) {
            let ts = parseInt(timestampMatch[1])
            // Convert milliseconds to seconds if needed
            if (ts > 9999999999) {
                ts = Math.floor(ts / 1000)
            }

            let date = new Date(ts * 1000)
            let formatted = date.toLocaleString()
            return {
                value: "= " + formatted,
                hint: "Unix timestamp",
                copyValue: formatted
            }
        }

        return null
    }

    function parseCompoundTime(str) {
        // Match all "number unit" pairs
        let regex = /(\d+(?:\.\d+)?)\s*([a-z]+)/g
        let match
        let totalSeconds = 0
        let foundAny = false

        while ((match = regex.exec(str)) !== null) {
            let value = parseFloat(match[1])
            let unit = match[2]

            if (!timeUnits[unit]) return null
            totalSeconds += value * timeUnits[unit]
            foundAny = true
        }

        return foundAny ? totalSeconds : null
    }

    function formatDuration(seconds) {
        let parts = []

        let days = Math.floor(seconds / 86400)
        if (days > 0) {
            parts.push(days + "d")
            seconds %= 86400
        }

        let hours = Math.floor(seconds / 3600)
        if (hours > 0) {
            parts.push(hours + "h")
            seconds %= 3600
        }

        let minutes = Math.floor(seconds / 60)
        if (minutes > 0) {
            parts.push(minutes + "m")
            seconds %= 60
        }

        if (seconds > 0 || parts.length === 0) {
            parts.push(Math.round(seconds) + "s")
        }

        return parts.join(" ")
    }

    function formatNumber(num) {
        let rounded = Math.round(num * 100) / 100
        if (Number.isInteger(rounded)) {
            return rounded.toString()
        }
        return rounded.toFixed(2).replace(/\.?0+$/, '')
    }
}
