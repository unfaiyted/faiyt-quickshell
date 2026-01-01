pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: mcpClient

    // Connection states
    readonly property int stateDisconnected: 0
    readonly property int stateConnecting: 1
    readonly property int stateConnected: 2
    readonly property int stateError: 3

    // State
    property var servers: []           // Configured servers from config
    property var connectedServers: ({}) // serverId -> { process, state }
    property var availableTools: []     // All tools from all connected servers
    property var serverStates: ({})     // serverId -> state enum
    property int nextRequestId: 1
    property var pendingRequests: ({})  // id -> { resolve, reject, serverId }

    // Signals
    signal serverConnected(string serverId)
    signal serverDisconnected(string serverId)
    signal serverError(string serverId, string error)
    signal toolsUpdated()

    // Initialize from config
    Component.onCompleted: {
        loadServersFromConfig()
    }

    function loadServersFromConfig() {
        servers = ConfigService.aiMcpServers || []
        // Auto-connect enabled servers
        for (let i = 0; i < servers.length; i++) {
            if (servers[i].enabled) {
                connectServer(servers[i])
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

    // Dynamic component for MCP server processes
    Component {
        id: mcpServerComponent

        Process {
            property string serverId: ""
            property string inputBuffer: ""

            stdinEnabled: true

            stdout: SplitParser {
                splitMarker: "\n"
                onRead: data => {
                    if (data.trim()) {
                        mcpClient.handleServerMessage(serverId, data)
                    }
                }
            }

            stderr: SplitParser {
                onRead: data => {
                    console.log("MCP Server", serverId, "stderr:", data)
                }
            }

            onExited: (exitCode, exitStatus) => {
                mcpClient.handleServerDisconnect(serverId, exitCode)
            }
        }
    }

    // Connect to an MCP server
    function connectServer(serverConfig) {
        const serverId = serverConfig.id

        if (connectedServers[serverId]) {
            console.log("MCPClient: Server already connected:", serverId)
            return
        }

        // Update state
        let newStates = cloneObject(serverStates)
        newStates[serverId] = stateConnecting
        serverStates = newStates

        // Create Process for this server
        const proc = mcpServerComponent.createObject(mcpClient, {
            serverId: serverId,
            command: serverConfig.command || []
        })

        if (!proc) {
            console.log("MCPClient: Failed to create process for server:", serverId)
            newStates[serverId] = stateError
            serverStates = newStates
            return
        }

        let newConnected = cloneObject(connectedServers)
        newConnected[serverId] = { process: proc, config: serverConfig }
        connectedServers = newConnected

        proc.running = true

        // Send initialization after a brief delay to ensure process is ready
        initTimer.serverId = serverId
        initTimer.start()
    }

    Timer {
        id: initTimer
        property string serverId: ""
        interval: 100
        repeat: false
        onTriggered: {
            mcpClient.initializeServer(serverId)
        }
    }

    function initializeServer(serverId) {
        sendRequest(serverId, "initialize", {
            protocolVersion: "2024-11-05",
            capabilities: {
                roots: { listChanged: false },
                sampling: {}
            },
            clientInfo: {
                name: "faiyt-qs",
                version: "1.0.0"
            }
        }).then(function(result) {
            // Send initialized notification
            sendNotification(serverId, "notifications/initialized", {})

            // Discover tools
            return discoverTools(serverId)
        }).then(function() {
            let newStates = cloneObject(serverStates)
            newStates[serverId] = stateConnected
            serverStates = newStates
            serverConnected(serverId)
        }).catch(function(error) {
            console.log("MCPClient: Init failed for", serverId, error)
            let newStates = cloneObject(serverStates)
            newStates[serverId] = stateError
            serverStates = newStates
            serverError(serverId, error.message || String(error))
        })
    }

    // Send JSON-RPC request
    function sendRequest(serverId, method, params) {
        return new Promise(function(resolve, reject) {
            const serverInfo = connectedServers[serverId]
            if (!serverInfo || !serverInfo.process || !serverInfo.process.running) {
                reject(new Error("Server not connected"))
                return
            }

            const id = nextRequestId++
            const request = {
                jsonrpc: "2.0",
                id: id,
                method: method,
                params: params || {}
            }

            // Store pending request
            let newPending = cloneObject(pendingRequests)
            newPending[id] = {
                resolve: resolve,
                reject: reject,
                serverId: serverId,
                method: method
            }
            pendingRequests = newPending

            // Set timeout
            const timeoutId = setTimeout(function() {
                const pending = pendingRequests[id]
                if (pending) {
                    let np = cloneObject(pendingRequests)
                    delete np[id]
                    pendingRequests = np
                    pending.reject(new Error("Request timeout"))
                }
            }, 30000)

            // Store timeout ID for cleanup
            pendingRequests[id].timeoutId = timeoutId

            // Send via stdin
            serverInfo.process.write(JSON.stringify(request) + "\n")
        })
    }

    // Send JSON-RPC notification (no response expected)
    function sendNotification(serverId, method, params) {
        const serverInfo = connectedServers[serverId]
        if (!serverInfo || !serverInfo.process || !serverInfo.process.running) return

        const notification = {
            jsonrpc: "2.0",
            method: method,
            params: params || {}
        }

        serverInfo.process.write(JSON.stringify(notification) + "\n")
    }

    // Handle incoming message from server
    function handleServerMessage(serverId, data) {
        try {
            const message = JSON.parse(data)

            if (message.id !== undefined) {
                // Response to our request
                const pending = pendingRequests[message.id]
                if (pending) {
                    // Clear timeout
                    if (pending.timeoutId) {
                        clearTimeout(pending.timeoutId)
                    }

                    let newPending = cloneObject(pendingRequests)
                    delete newPending[message.id]
                    pendingRequests = newPending

                    if (message.error) {
                        pending.reject(new Error(message.error.message || "Unknown error"))
                    } else {
                        pending.resolve(message.result)
                    }
                }
            } else if (message.method) {
                // Server-initiated request or notification
                handleServerRequest(serverId, message)
            }
        } catch (e) {
            console.log("MCPClient: Failed to parse message from", serverId, e)
        }
    }

    // Handle server-initiated requests
    function handleServerRequest(serverId, message) {
        // Handle notifications from server
        switch (message.method) {
        case "notifications/tools/list_changed":
            // Re-discover tools
            discoverTools(serverId)
            break
        default:
            console.log("MCPClient: Unhandled server request:", message.method)
        }
    }

    // Discover available tools from a server
    function discoverTools(serverId) {
        return sendRequest(serverId, "tools/list", {}).then(function(result) {
            const serverTools = result.tools || []
            const tools = []
            for (let i = 0; i < serverTools.length; i++) {
                let tool = cloneObject(serverTools[i])
                tool.serverId = serverId
                tools.push(tool)
            }

            // Merge with existing tools (remove old from same server)
            let newTools = availableTools.filter(function(t) { return t.serverId !== serverId })
            newTools = newTools.concat(tools)
            availableTools = newTools

            toolsUpdated()
            return tools
        })
    }

    // Execute a tool
    function executeTool(toolName, toolInput) {
        // Find which server has this tool
        const tool = availableTools.find(function(t) { return t.name === toolName })
        if (!tool) {
            return Promise.reject(new Error("Tool not found: " + toolName))
        }

        return sendRequest(tool.serverId, "tools/call", {
            name: toolName,
            arguments: toolInput
        }).then(function(result) {
            return result.content || result
        })
    }

    // Convert MCP tools to Claude API format
    function getToolsForClaude() {
        const result = []
        for (let i = 0; i < availableTools.length; i++) {
            const tool = availableTools[i]
            result.push({
                name: tool.name,
                description: tool.description,
                input_schema: tool.inputSchema
            })
        }
        return result
    }

    // Disconnect a server
    function disconnectServer(serverId) {
        const serverInfo = connectedServers[serverId]
        if (serverInfo && serverInfo.process) {
            serverInfo.process.running = false

            let newConnected = cloneObject(connectedServers)
            delete newConnected[serverId]
            connectedServers = newConnected

            // Remove tools from this server
            availableTools = availableTools.filter(function(t) { return t.serverId !== serverId })
            toolsUpdated()
        }

        let newStates = cloneObject(serverStates)
        newStates[serverId] = stateDisconnected
        serverStates = newStates

        serverDisconnected(serverId)
    }

    // Handle server disconnect (process exited)
    function handleServerDisconnect(serverId, exitCode) {
        console.log("MCPClient: Server disconnected:", serverId, "exit:", exitCode)

        let newConnected = cloneObject(connectedServers)
        delete newConnected[serverId]
        connectedServers = newConnected

        availableTools = availableTools.filter(function(t) { return t.serverId !== serverId })
        toolsUpdated()

        let newStates = cloneObject(serverStates)
        newStates[serverId] = stateDisconnected
        serverStates = newStates

        serverDisconnected(serverId)
    }

    // Disconnect all servers
    function disconnectAll() {
        const serverIds = Object.keys(connectedServers)
        for (let i = 0; i < serverIds.length; i++) {
            disconnectServer(serverIds[i])
        }
    }

    // Get server state
    function getServerState(serverId) {
        return serverStates[serverId] || stateDisconnected
    }

    // Add a new MCP server to config
    function addServer(name, command, env) {
        const server = {
            id: generateUUID(),
            name: name,
            command: command,
            env: env || {},
            enabled: true
        }

        let newServers = servers.slice()
        newServers.push(server)
        servers = newServers

        // Save to config
        ConfigService.setValue("ai.mcpServers", servers)
        ConfigService.saveConfig()

        // Connect immediately
        connectServer(server)

        return server.id
    }

    // Remove an MCP server
    function removeServer(serverId) {
        // Disconnect first
        disconnectServer(serverId)

        // Remove from list
        servers = servers.filter(function(s) { return s.id !== serverId })

        // Save to config
        ConfigService.setValue("ai.mcpServers", servers)
        ConfigService.saveConfig()
    }

    // Toggle server enabled state
    function toggleServer(serverId) {
        const idx = servers.findIndex(function(s) { return s.id === serverId })
        if (idx >= 0) {
            let newServers = servers.slice()
            let server = cloneObject(newServers[idx])
            server.enabled = !server.enabled
            newServers[idx] = server
            servers = newServers

            // Save to config
            ConfigService.setValue("ai.mcpServers", servers)
            ConfigService.saveConfig()

            // Connect or disconnect based on new state
            if (server.enabled) {
                connectServer(server)
            } else {
                disconnectServer(serverId)
            }
        }
    }

    // Cleanup on destruction
    Component.onDestruction: {
        disconnectAll()
    }
}
