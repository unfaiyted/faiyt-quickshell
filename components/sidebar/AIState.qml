pragma Singleton
import QtQuick
import Quickshell
import "../../services"

Singleton {
    id: aiState

    // Tab State
    property int activeMainTab: 0       // 0=AI, 1=Tools
    property int activeProviderTab: 0   // 0=Claude, 1=Gemini, 2=GPT, 3=Ollama, 4=Settings

    // Conversation UI State
    property bool conversationSidebarOpen: false

    // Chat State
    property bool isProcessing: ClaudeService.isProcessing
    property string currentStreamingContent: ""
    property string currentStreamingMessageId: ""

    // Convenience accessors
    property var conversations: ConversationManager.conversations
    property var activeConversation: ConversationManager.activeConversation
    property string activeConversationId: ConversationManager.activeConversationId

    // Initialize
    Component.onCompleted: {
        // Ensure we have at least one conversation
        ConversationManager.conversationsLoaded.connect(() => {
            ConversationManager.ensureConversation()
        })
    }

    // Toggle conversation sidebar
    function toggleConversationSidebar() {
        conversationSidebarOpen = !conversationSidebarOpen
    }

    // Create a new conversation
    function createConversation(name) {
        return ConversationManager.createConversation(name)
    }

    // Switch to a conversation
    function switchConversation(id) {
        ConversationManager.switchConversation(id)
    }

    // Delete a conversation
    function deleteConversation(id) {
        ConversationManager.deleteConversation(id)
    }

    // Rename a conversation
    function renameConversation(id, newName) {
        ConversationManager.renameConversation(id, newName)
    }

    // Send a message
    function sendMessage(content) {
        if (!content || !content.trim()) return
        if (ClaudeService.isProcessing) return

        // Ensure we have an active conversation
        if (!ConversationManager.activeConversationId) {
            ConversationManager.createConversation()
        }

        const convId = ConversationManager.activeConversationId

        // Add user message
        const userMessage = {
            role: "user",
            content: content.trim(),
            timestamp: Date.now()
        }
        ConversationManager.addMessage(convId, userMessage)

        // Create assistant message placeholder
        const assistantMessage = {
            role: "assistant",
            content: "",
            timestamp: Date.now(),
            isStreaming: true
        }
        const assistantMsgId = ConversationManager.addMessage(convId, assistantMessage)
        currentStreamingMessageId = assistantMsgId
        currentStreamingContent = ""

        // Get messages for API call
        const messages = ConversationManager.getActiveMessages()

        // Get MCP tools if any
        const tools = MCPClient.getToolsForClaude()

        // Send to Claude
        ClaudeService.sendMessage(messages, tools.length > 0 ? tools : null)
    }

    // Handle streaming content
    Connections {
        target: ClaudeService

        function onContentDelta(requestId, delta) {
            currentStreamingContent += delta

            if (currentStreamingMessageId && ConversationManager.activeConversationId) {
                ConversationManager.updateMessage(
                    ConversationManager.activeConversationId,
                    currentStreamingMessageId,
                    { content: currentStreamingContent }
                )
            }
        }

        function onMessageFinished(requestId, fullContent) {
            if (currentStreamingMessageId && ConversationManager.activeConversationId) {
                ConversationManager.updateMessage(
                    ConversationManager.activeConversationId,
                    currentStreamingMessageId,
                    {
                        content: currentStreamingContent || fullContent,
                        isStreaming: false
                    }
                )
            }

            currentStreamingMessageId = ""
            currentStreamingContent = ""
        }

        function onToolUseRequested(requestId, toolId, toolName, toolInput) {
            // Execute the tool via MCP
            MCPClient.executeTool(toolName, toolInput).then(result => {
                // Get current messages
                const messages = ConversationManager.getActiveMessages()

                // Send tool result back to Claude
                ClaudeService.sendToolResult(messages, toolId, result, false)
            }).catch(error => {
                // Send error as tool result
                const messages = ConversationManager.getActiveMessages()
                ClaudeService.sendToolResult(messages, toolId, error.message, true)
            })
        }

        function onErrorOccurred(error) {
            console.log("AIState: Claude error:", error)

            // Update the streaming message with error
            if (currentStreamingMessageId && ConversationManager.activeConversationId) {
                ConversationManager.updateMessage(
                    ConversationManager.activeConversationId,
                    currentStreamingMessageId,
                    {
                        content: "Error: " + error,
                        isStreaming: false,
                        isError: true
                    }
                )
            }

            currentStreamingMessageId = ""
            currentStreamingContent = ""
        }
    }

    // Cancel current request
    function cancelRequest() {
        ClaudeService.cancel()

        if (currentStreamingMessageId && ConversationManager.activeConversationId) {
            ConversationManager.updateMessage(
                ConversationManager.activeConversationId,
                currentStreamingMessageId,
                {
                    content: currentStreamingContent + " [Cancelled]",
                    isStreaming: false
                }
            )
        }

        currentStreamingMessageId = ""
        currentStreamingContent = ""
    }

    // Clear current conversation
    function clearConversation() {
        ConversationManager.clearActiveConversation()
    }

    // Get messages for display
    function getMessages() {
        return ConversationManager.getActiveMessages()
    }

    // Check if API key is configured (from environment variable)
    function hasApiKey() {
        return ClaudeService.hasApiKey()
    }

    // API key must be set via ANTHROPIC_API_KEY environment variable for security
    function refreshApiKey() {
        ClaudeService.refreshApiKey()
    }

    // Get current model
    function getCurrentModel() {
        return ClaudeService.currentModel
    }

    // Set model
    function setModel(model) {
        ClaudeService.setModel(model)
    }

    // Get available models
    function getModels() {
        return ConfigService.aiModels
    }
}
