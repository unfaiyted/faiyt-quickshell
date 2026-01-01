pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: claudeService

    // API Configuration
    property string apiKey: ""
    property string currentModel: ConfigService.aiDefaultModel
    property int maxTokens: ConfigService.aiMaxTokens
    property real temperature: ConfigService.aiTemperature

    // State
    property bool isProcessing: false
    property string lastError: ""
    property string currentRequestId: ""

    // Retry configuration
    property int retryCount: 0
    property int maxRetries: 3
    property int retryDelayMs: 1000

    // Signals for UI
    signal messageStarted(string requestId)
    signal contentDelta(string requestId, string delta)
    signal messageFinished(string requestId, string fullContent)
    signal toolUseRequested(string requestId, string toolId, string toolName, var toolInput)
    signal errorOccurred(string error)

    // Initialize API key
    Component.onCompleted: {
        refreshApiKey()
    }

    // Get API key from environment variable (never stored in config for security)
    function refreshApiKey() {
        envProcess.running = true
    }

    Process {
        id: envProcess
        command: ["bash", "-c", "echo $ANTHROPIC_API_KEY"]
        stdout: SplitParser {
            onRead: data => {
                const key = data.trim()
                if (key) {
                    claudeService.apiKey = key
                }
            }
        }
    }

    // Generate UUID for request tracking
    function generateUUID() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0
            const v = c === 'x' ? r : (r & 0x3 | 0x8)
            return v.toString(16)
        })
    }

    // Main API process
    Process {
        id: apiProcess

        property string requestId: ""
        property string eventType: ""
        property string fullContent: ""
        property string currentToolId: ""
        property string currentToolName: ""
        property string toolInputBuffer: ""
        property bool receivedAnyData: false

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                apiProcess.receivedAnyData = true
                const line = data.trim()
                if (!line) return  // Skip empty lines

                if (line.startsWith("event: ")) {
                    apiProcess.eventType = line.slice(7).trim()
                } else if (line.startsWith("data: ")) {
                    const jsonStr = line.slice(6).trim()
                    if (jsonStr && jsonStr !== "[DONE]") {
                        claudeService.handleSSEData(apiProcess.eventType, jsonStr)
                    }
                } else if (line.startsWith("{")) {
                    // Handle plain JSON error responses (non-SSE)
                    try {
                        const errorData = JSON.parse(line)
                        if (errorData.type === "error" && errorData.error) {
                            claudeService.lastError = errorData.error.message || "API error"
                            claudeService.errorOccurred(claudeService.lastError)
                        }
                    } catch (e) {
                        // Not valid JSON, ignore
                    }
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                // Ignore curl progress output
                if (!data.includes("%") && data.trim()) {
                    claudeService.lastError = data
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            console.log("ClaudeService: curl exited with code", exitCode, "receivedData:", apiProcess.receivedAnyData)
            claudeService.isProcessing = false

            if (exitCode !== 0 && claudeService.lastError) {
                console.log("ClaudeService: Error:", claudeService.lastError)
                claudeService.errorOccurred(claudeService.lastError)

                // Retry logic
                if (claudeService.shouldRetry(exitCode)) {
                    claudeService.retryCount++
                    retryTimer.interval = claudeService.retryDelayMs * Math.pow(2, claudeService.retryCount - 1)
                    retryTimer.start()
                    return
                }
            }

            if (apiProcess.fullContent) {
                console.log("ClaudeService: Response received, length:", apiProcess.fullContent.length)
                claudeService.messageFinished(apiProcess.requestId, apiProcess.fullContent)
            } else {
                console.log("ClaudeService: No content received")
                if (!apiProcess.receivedAnyData) {
                    claudeService.errorOccurred("No response from API - check your network connection")
                }
            }

            // Reset state
            apiProcess.fullContent = ""
            apiProcess.currentToolId = ""
            apiProcess.currentToolName = ""
            apiProcess.toolInputBuffer = ""
            apiProcess.receivedAnyData = false
            claudeService.retryCount = 0
        }
    }

    Timer {
        id: retryTimer
        repeat: false
        onTriggered: {
            if (lastRequestBody) {
                sendRequestInternal(lastRequestBody)
            }
        }
    }

    property var lastRequestBody: null

    function shouldRetry(exitCode) {
        // Retry on network errors or rate limits
        return retryCount < maxRetries && exitCode !== 0
    }

    function handleSSEData(eventType, jsonStr) {
        try {
            const data = JSON.parse(jsonStr)

            switch (eventType) {
            case "message_start":
                messageStarted(apiProcess.requestId)
                break

            case "content_block_start":
                if (data.content_block?.type === "tool_use") {
                    apiProcess.currentToolId = data.content_block.id
                    apiProcess.currentToolName = data.content_block.name
                    apiProcess.toolInputBuffer = ""
                }
                break

            case "content_block_delta":
                if (data.delta?.type === "text_delta") {
                    const text = data.delta.text
                    apiProcess.fullContent += text
                    contentDelta(apiProcess.requestId, text)
                } else if (data.delta?.type === "input_json_delta") {
                    apiProcess.toolInputBuffer += data.delta.partial_json
                }
                break

            case "content_block_stop":
                if (apiProcess.currentToolId) {
                    try {
                        const toolInput = JSON.parse(apiProcess.toolInputBuffer)
                        toolUseRequested(
                            apiProcess.requestId,
                            apiProcess.currentToolId,
                            apiProcess.currentToolName,
                            toolInput
                        )
                    } catch (e) {
                        console.log("ClaudeService: Failed to parse tool input:", e)
                    }
                    apiProcess.currentToolId = ""
                    apiProcess.currentToolName = ""
                    apiProcess.toolInputBuffer = ""
                }
                break

            case "message_stop":
                // Handled in onExited
                break

            case "error":
                const errorMsg = data.error?.message || "Unknown API error"
                lastError = errorMsg
                errorOccurred(errorMsg)
                break
            }
        } catch (e) {
            console.log("ClaudeService: Failed to parse SSE data:", e, jsonStr)
        }
    }

    // Send a message to Claude
    function sendMessage(messages, tools) {
        if (isProcessing) {
            console.log("ClaudeService: Already processing a request")
            return null
        }

        if (!apiKey) {
            errorOccurred("No API key configured. Set ANTHROPIC_API_KEY or add key in settings.")
            return null
        }

        const requestId = generateUUID()
        currentRequestId = requestId
        apiProcess.requestId = requestId
        apiProcess.fullContent = ""

        // Build request body
        const body = {
            model: currentModel,
            max_tokens: maxTokens,
            stream: true,
            messages: messages.map(m => ({
                role: m.role,
                content: m.content
            }))
        }

        // Add system prompt if configured
        if (ConfigService.aiSystemPrompt) {
            body.system = ConfigService.aiSystemPrompt
        }

        // Add tools if provided
        if (tools && tools.length > 0) {
            body.tools = tools
        }

        lastRequestBody = body
        retryCount = 0
        sendRequestInternal(body)

        return requestId
    }

    function sendRequestInternal(body) {
        const bodyJson = JSON.stringify(body)

        console.log("ClaudeService: Sending request to API...")
        console.log("ClaudeService: Model:", body.model, "Messages:", body.messages.length)

        // Build curl command for streaming SSE
        apiProcess.command = [
            "curl", "-sS", "-N",
            "-X", "POST",
            "https://api.anthropic.com/v1/messages",
            "-H", "Content-Type: application/json",
            "-H", "anthropic-version: 2023-06-01",
            "-H", "x-api-key: " + apiKey,
            "-d", bodyJson
        ]

        isProcessing = true
        lastError = ""
        apiProcess.running = true
        console.log("ClaudeService: curl process started")
    }

    // Continue conversation with tool result
    function sendToolResult(messages, toolUseId, toolResult, isError) {
        const toolResultMessage = {
            role: "user",
            content: [{
                type: "tool_result",
                tool_use_id: toolUseId,
                content: typeof toolResult === "string" ? toolResult : JSON.stringify(toolResult),
                is_error: isError || false
            }]
        }

        const allMessages = messages.concat([toolResultMessage])
        return sendMessage(allMessages, [])  // Tools already known from previous call
    }

    // Cancel current request
    function cancel() {
        if (isProcessing && apiProcess.running) {
            apiProcess.running = false
            isProcessing = false
            retryTimer.stop()
        }
    }

    // Check if API key is available
    function hasApiKey() {
        return apiKey && apiKey.length > 0
    }

    // Set model
    function setModel(model) {
        currentModel = model
        ConfigService.setValue("ai.defaultModel", model)
        ConfigService.saveConfig()
    }
}
