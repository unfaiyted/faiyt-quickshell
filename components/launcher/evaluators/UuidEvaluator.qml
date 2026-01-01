import QtQuick

QtObject {
    property string name: "uuid"

    // Cache the generated UUID so it doesn't change on every keystroke
    property string cachedUuid: ""
    property string lastInput: ""

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern: just "uuid"
        if (trimmed !== "uuid") return null

        // Generate new UUID only if input changed (i.e., user just typed "uuid")
        if (lastInput !== trimmed || !cachedUuid) {
            cachedUuid = generateUuid()
            lastInput = trimmed
        }

        return {
            value: "= " + cachedUuid,
            hint: "Enter to copy",
            copyValue: cachedUuid
        }
    }

    function generateUuid() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            let r = Math.random() * 16 | 0
            let v = c === 'x' ? r : (r & 0x3 | 0x8)
            return v.toString(16)
        })
    }

    // Reset cache when input clears (for fresh UUID next time)
    function reset() {
        cachedUuid = ""
        lastInput = ""
    }
}
