import QtQuick
import "../../../../theme"
import "../../../../services"
import "../.."

Item {
    id: aiPanel

    Column {
        anchors.fill: parent
        spacing: 0

        // Provider sub-tabs
        AITabBar {
            id: providerTabs
            width: parent.width
            tabData: [
                { icon: "󰧑", label: "Claude" },
                { icon: "󰟷", label: "Gemini" },
                { icon: "󰭹", label: "GPT" },
                { icon: "󱙺", label: "Ollama" },
                { icon: "󰒓", label: "Settings" }
            ]
            currentIndex: AIState.activeProviderTab
            onTabClicked: index => AIState.activeProviderTab = index
        }

        // Provider content
        Loader {
            width: parent.width
            height: parent.height - providerTabs.height
            sourceComponent: {
                switch(AIState.activeProviderTab) {
                case 0: return claudeComponent
                case 1: return geminiComponent
                case 2: return gptComponent
                case 3: return ollamaComponent
                case 4: return settingsComponent
                default: return claudeComponent
                }
            }
        }

        Component {
            id: claudeComponent
            ChatContainer {
                provider: "claude"
                stubMode: false
            }
        }

        Component {
            id: geminiComponent
            ChatContainer {
                provider: "gemini"
                stubMode: true
            }
        }

        Component {
            id: gptComponent
            ChatContainer {
                provider: "gpt"
                stubMode: true
            }
        }

        Component {
            id: ollamaComponent
            ChatContainer {
                provider: "ollama"
                stubMode: true
            }
        }

        Component {
            id: settingsComponent
            AISettings {}
        }
    }
}
