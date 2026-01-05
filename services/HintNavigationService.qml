pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: hintService

    // State
    property bool active: false
    property string inputBuffer: ""
    property var targets: []  // [{id, element, hint, action, scope}]
    property int _nextId: 0  // Counter for unique IDs

    // Active popup scope - when set, only hints from this scope are shown
    // This suppresses parent scope hints (e.g., bar) while popup is open
    property string activePopupScope: ""

    // Signal emitted when popup scope is cleared (for popup cleanup)
    signal popupScopeCleared(string scope)

    // Timer to delay hint reassignment after popup opens
    Timer {
        id: popupHintTimer
        interval: 50
        repeat: false
        onTriggered: hintService.reassignHints()
    }

    // Set the active popup scope (called when opening a popup via hints)
    function setPopupScope(scope: string): void {
        activePopupScope = scope
        inputBuffer = ""  // Reset input buffer for new scope
        reassignHints()
        // Also reassign after a short delay to catch dynamically registered targets
        popupHintTimer.restart()
    }

    // Clear the popup scope (called when popup closes)
    function clearPopupScope(): void {
        const previousScope = activePopupScope
        activePopupScope = ""
        reassignHints()
        if (previousScope !== "") {
            popupScopeCleared(previousScope)
        }
    }

    // Check if a popup scope is currently active
    function hasActivePopup(): bool {
        return activePopupScope !== ""
    }

    // Home-row priority hint characters
    readonly property var hintChars: [
        "a","s","d","f","g","h","j","k","l",  // Home row first
        "q","w","e","r","t","y","u","i","o","p",
        "z","x","c","v","b","n","m"
    ]

    // Timer to refresh hints while active (catches visibility changes, new elements, etc.)
    Timer {
        id: refreshTimer
        interval: 200
        running: hintService.active
        repeat: true
        onTriggered: hintService.reassignHints()
    }

    // IPC Handler for external triggering
    IpcHandler {
        target: "hints"

        function toggle(): string {
            hintService.toggle()
            return hintService.active ? "active" : "inactive"
        }

        function show(): string {
            hintService.activate()
            return "active"
        }

        function hide(): string {
            hintService.deactivate()
            return "inactive"
        }
    }

    // Generate hint for index (a, s, d, ..., aa, as, ad, ...)
    function generateHint(index: int): string {
        const chars = hintChars
        if (index < chars.length) {
            return chars[index]
        }
        const first = Math.floor((index - chars.length) / chars.length)
        const second = (index - chars.length) % chars.length
        if (first < chars.length) {
            return chars[first] + chars[second]
        }
        // Fallback for very large indices
        return chars[index % chars.length]
    }

    // Register a clickable target
    function register(element: Item, action: var, scope: string, secondaryAction: var): int {
        const id = _nextId++
        const newTargets = targets.slice()
        newTargets.push({
            id: id,
            element: element,
            action: action,
            secondaryAction: secondaryAction || null,
            scope: scope,
            hint: ""
        })
        targets = newTargets
        reassignHints()
        return id
    }

    // Unregister target
    function unregister(id: var): void {
        targets = targets.filter(t => t.id !== id)
        reassignHints()
    }

    // Reassign hints based on current visible targets, grouped by scope
    function reassignHints(): void {
        // Group targets by scope
        const scopeGroups = {}
        for (const t of targets) {
            if (!t.element || !t.element.visible) {
                t.hint = ""  // Clear hints for invisible targets
                continue
            }
            const scope = t.scope || ""
            if (!scopeGroups[scope]) {
                scopeGroups[scope] = []
            }
            scopeGroups[scope].push(t)
        }

        // Assign hints within each scope independently
        for (const scope in scopeGroups) {
            const scopeTargets = scopeGroups[scope]
            scopeTargets.forEach((t, i) => {
                t.hint = generateHint(i)
            })
        }

        targetsChanged()
    }

    // Get targets filtered by current input
    function getFilteredTargets(): var {
        if (!inputBuffer) {
            return targets.filter(t => t.element && t.element.visible)
        }
        return targets.filter(t =>
            t.element && t.element.visible && t.hint.startsWith(inputBuffer.toLowerCase())
        )
    }

    // Get targets for a specific scope
    function getTargetsForScope(scope: string): var {
        return targets.filter(t => t.scope === scope && t.element && t.element.visible)
    }

    // Handle key input - returns true if key was handled
    // Optional scope parameter to only match hints from that scope
    // Optional modifiers parameter to detect Shift for secondary action
    function handleKey(key, scope, modifiers): bool {
        scope = scope || ""
        modifiers = modifiers || 0
        if (key === "Escape") {
            deactivate()
            return true
        }
        if (key === "Backspace") {
            inputBuffer = inputBuffer.slice(0, -1)
            return true
        }

        const keyChar = key.toLowerCase()
        if (hintChars.includes(keyChar)) {
            inputBuffer += keyChar

            // Get matches - filter by scope if provided
            let matches = getFilteredTargets()
            if (scope) {
                matches = matches.filter(t => t.scope === scope)
            }

            // Check if there's an exact match
            const exact = matches.find(t => t.hint === inputBuffer)

            // Check if there are longer hints that start with current input
            const hasLongerMatches = matches.some(t => t.hint.length > inputBuffer.length)

            // Only activate if exact match AND no longer hints exist
            // (This prevents "a" from activating when "aa", "ab" etc. exist)
            if (exact && !hasLongerMatches) {
                const isShiftPressed = (modifiers & Qt.ShiftModifier)
                const previousPopupScope = activePopupScope

                // Shift+key triggers secondary action (right-click behavior)
                if (isShiftPressed && typeof exact.secondaryAction === 'function') {
                    exact.secondaryAction()
                } else if (typeof exact.action === 'function') {
                    exact.action()
                }

                // If action opened a popup (set activePopupScope), stay active
                // Otherwise, deactivate hints
                if (activePopupScope === previousPopupScope) {
                    deactivate()
                } else {
                    // Popup was opened, just reset input buffer
                    inputBuffer = ""
                }
                return true
            }

            // No matches at all - reset buffer
            if (matches.length === 0) {
                inputBuffer = ""
            }
            return true
        }
        return false
    }

    function activate(): void {
        reassignHints()
        inputBuffer = ""
        active = true
    }

    function deactivate(): void {
        active = false
        inputBuffer = ""
        activePopupScope = ""
    }

    function toggle(): void {
        if (active) {
            deactivate()
        } else {
            activate()
        }
    }
}
