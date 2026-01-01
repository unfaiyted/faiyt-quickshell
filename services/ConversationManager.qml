pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: conversationManager

    // Paths - use XDG_DATA_HOME for user data (not config)
    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/faiyt-qs"
    readonly property string conversationsFile: dataDir + "/conversations.json"

    // State
    property var conversations: []
    property string activeConversationId: ""
    property var activeConversation: null
    property bool isLoading: false
    property bool isSaving: false

    // Signals
    signal conversationChanged(string id)
    signal conversationsLoaded()
    signal messageAdded(string conversationId, var message)
    signal messageUpdated(string conversationId, string messageId)

    // Initialize
    Component.onCompleted: {
        ensureDataDir()
    }

    // Ensure data directory exists
    function ensureDataDir() {
        mkdirProcess.running = true
    }

    Process {
        id: mkdirProcess
        command: ["mkdir", "-p", conversationManager.dataDir]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                conversationManager.loadConversations()
            }
        }
    }

    // Generate UUID
    function generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0
            const v = c === 'x' ? r : (r & 0x3 | 0x8)
            return v.toString(16)
        })
    }

    // Helper to clone an object
    function cloneObject(obj) {
        return JSON.parse(JSON.stringify(obj))
    }

    // Load conversations from file
    function loadConversations() {
        isLoading = true
        loadProcess.buffer = ""
        loadProcess.running = true
    }

    Process {
        id: loadProcess
        command: ["cat", conversationManager.conversationsFile]
        property string buffer: ""

        stdout: SplitParser {
            splitMarker: ""  // Read all data
            onRead: data => {
                loadProcess.buffer += data
            }
        }

        onExited: (exitCode, exitStatus) => {
            conversationManager.isLoading = false

            if (exitCode === 0 && loadProcess.buffer.trim()) {
                try {
                    const data = JSON.parse(loadProcess.buffer)
                    conversationManager.conversations = data.conversations || []
                    conversationManager.activeConversationId = data.activeId || ""
                    conversationManager.updateActiveConversation()
                    conversationManager.conversationsLoaded()
                } catch (e) {
                    console.log("ConversationManager: Parse error, starting fresh")
                    conversationManager.conversations = []
                    conversationManager.activeConversationId = ""
                }
            } else {
                // No file or empty, start fresh
                conversationManager.conversations = []
                conversationManager.activeConversationId = ""
            }

            loadProcess.buffer = ""
        }
    }

    // Debounced save
    Timer {
        id: saveDebounce
        interval: 500
        repeat: false
        onTriggered: {
            conversationManager.executeSave()
        }
    }

    function queueSave() {
        saveDebounce.restart()
    }

    function executeSave() {
        if (isSaving) {
            // Re-queue if already saving
            queueSave()
            return
        }

        const data = {
            conversations: conversations,
            activeId: activeConversationId,
            savedAt: Date.now()
        }

        const jsonStr = JSON.stringify(data, null, 2)
        // Escape for shell
        const escaped = jsonStr.replace(/'/g, "'\\''")

        saveProcess.command = ["bash", "-c", "echo '" + escaped + "' > '" + conversationsFile + "'"]
        isSaving = true
        saveProcess.running = true
    }

    Process {
        id: saveProcess
        property string errorOutput: ""
        stderr: SplitParser {
            onRead: data => saveProcess.errorOutput += data
        }
        onExited: (exitCode, exitStatus) => {
            conversationManager.isSaving = false
            if (exitCode !== 0) {
                console.log("ConversationManager: Save failed -", errorOutput || "exit code " + exitCode)
            }
            errorOutput = ""
        }
    }

    // Update active conversation reference
    function updateActiveConversation() {
        activeConversation = conversations.find(c => c.id === activeConversationId) || null
    }

    // Create a new conversation
    function createConversation(name) {
        const conv = {
            id: generateUUID(),
            name: name || "New Conversation",
            createdAt: Date.now(),
            updatedAt: Date.now(),
            messages: [],
            systemPrompt: ConfigService.aiSystemPrompt || ""
        }

        let newList = conversations.slice()
        newList.unshift(conv)  // Add to beginning
        conversations = newList

        activeConversationId = conv.id
        updateActiveConversation()
        queueSave()

        conversationChanged(conv.id)
        return conv.id
    }

    // Delete a conversation
    function deleteConversation(id) {
        conversations = conversations.filter(c => c.id !== id)

        if (activeConversationId === id) {
            activeConversationId = conversations.length > 0 ? conversations[0].id : ""
            updateActiveConversation()
            if (activeConversationId) {
                conversationChanged(activeConversationId)
            }
        }

        queueSave()
    }

    // Rename a conversation
    function renameConversation(id, newName) {
        const idx = conversations.findIndex(c => c.id === id)
        if (idx >= 0) {
            let newList = conversations.slice()
            let conv = cloneObject(newList[idx])
            conv.name = newName
            conv.updatedAt = Date.now()
            newList[idx] = conv
            conversations = newList

            if (id === activeConversationId) {
                updateActiveConversation()
            }

            queueSave()
        }
    }

    // Switch to a conversation
    function switchConversation(id) {
        if (conversations.some(c => c.id === id)) {
            activeConversationId = id
            updateActiveConversation()
            queueSave()
            conversationChanged(id)
        }
    }

    // Add a message to a conversation
    function addMessage(conversationId, message) {
        const idx = conversations.findIndex(c => c.id === conversationId)
        if (idx >= 0) {
            // Ensure message has an id
            if (!message.id) {
                message.id = generateUUID()
            }

            let newList = conversations.slice()
            let conv = cloneObject(newList[idx])
            conv.messages = conv.messages.slice()
            conv.messages.push(message)
            conv.updatedAt = Date.now()

            // Auto-generate name from first user message if still default
            if (conv.name === "New Conversation" && message.role === "user") {
                const content = typeof message.content === "string" ? message.content : (message.content[0] ? message.content[0].text : "") || ""
                if (content) {
                    conv.name = content.substring(0, 30) + (content.length > 30 ? "..." : "")
                }
            }

            newList[idx] = conv
            conversations = newList

            if (conversationId === activeConversationId) {
                updateActiveConversation()
            }

            messageAdded(conversationId, message)
            queueSave()

            return message.id
        }
        return null
    }

    // Update a message in a conversation
    function updateMessage(conversationId, messageId, updates) {
        const convIdx = conversations.findIndex(c => c.id === conversationId)
        if (convIdx >= 0) {
            let newList = conversations.slice()
            let conv = cloneObject(newList[convIdx])
            const msgIdx = conv.messages.findIndex(m => m.id === messageId)

            if (msgIdx >= 0) {
                conv.messages = conv.messages.slice()
                let msg = cloneObject(conv.messages[msgIdx])
                // Apply updates
                for (let key in updates) {
                    msg[key] = updates[key]
                }
                conv.messages[msgIdx] = msg
                conv.updatedAt = Date.now()
                newList[convIdx] = conv
                conversations = newList

                if (conversationId === activeConversationId) {
                    updateActiveConversation()
                }

                messageUpdated(conversationId, messageId)
                queueSave()
            }
        }
    }

    // Get messages for the active conversation
    function getActiveMessages() {
        if (activeConversation) {
            return activeConversation.messages
        }
        return []
    }

    // Clear messages in the active conversation
    function clearActiveConversation() {
        if (activeConversationId) {
            const idx = conversations.findIndex(c => c.id === activeConversationId)
            if (idx >= 0) {
                let newList = conversations.slice()
                let conv = cloneObject(newList[idx])
                conv.messages = []
                conv.updatedAt = Date.now()
                newList[idx] = conv
                conversations = newList
                updateActiveConversation()
                queueSave()
            }
        }
    }

    // Ensure there's at least one conversation
    function ensureConversation() {
        if (conversations.length === 0) {
            createConversation("New Conversation")
        } else if (!activeConversationId) {
            activeConversationId = conversations[0].id
            updateActiveConversation()
            conversationChanged(activeConversationId)
        }
    }
}
