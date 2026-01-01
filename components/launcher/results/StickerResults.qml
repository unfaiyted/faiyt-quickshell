import QtQuick
import Quickshell.Io
import "../../../services"
import ".."

Item {
    id: stickerResults
    visible: false

    property string typeName: "sticker"
    property int maxResults: 48  // 6 columns x 8 rows

    // Search stickers
    function search(query, isPrefixSearch) {
        if (!ConfigService.stickersEnabled) return []

        let queryLower = query.toLowerCase().trim()

        // Handle "add <url>" command
        if (queryLower.startsWith("add ")) {
            const url = query.substring(4).trim()
            return handleAddCommand(url)
        }

        // Get stickers (filtered by selected pack if any)
        let stickers
        if (!queryLower && isPrefixSearch) {
            // No query - show all stickers or pack stickers
            if (StickerService.selectedPackId) {
                stickers = StickerService.getPackStickers(StickerService.selectedPackId)
            } else {
                stickers = StickerService.getAllStickers()
            }

            if (stickers.length === 0) {
                return [{
                    type: "sticker-info",
                    title: "No Sticker Packs Yet",
                    description: "Add your favorite Signal sticker packs to use them anywhere!",
                    icon: "view-media-symbolic",
                    action: function() {}
                }]
            }
            return stickers.slice(0, maxResults).map(createResult)
        }

        if (!queryLower) return []

        // Search stickers by emoji or keywords
        stickers = StickerService.searchStickers(queryLower)

        // Filter by selected pack if any
        if (StickerService.selectedPackId) {
            stickers = stickers.filter(s => s.packId === StickerService.selectedPackId)
        }

        return stickers.slice(0, maxResults).map(createResult)
    }

    // Handle add pack command
    function handleAddCommand(url) {
        if (!url) {
            return [{
                type: "sticker-info",
                title: "Add a Sticker Pack",
                description: "Paste a Signal sticker URL after 'add' to install a pack",
                icon: "list-add-symbolic",
                action: function() {}
            }]
        }

        // Check if it's a valid Signal URL
        if (!url.includes("signal.art") && !url.includes("pack_id=")) {
            return [{
                type: "sticker-info",
                title: "Invalid Sticker URL",
                description: "That doesn't look like a Signal sticker URL. Try copying the full URL from signalstickers.org",
                icon: "dialog-error-symbolic",
                action: function() {}
            }]
        }

        // Return action to add the pack
        return [{
            type: "sticker-add",
            title: "Add Sticker Pack",
            description: "Click below to download and install this sticker pack",
            icon: "list-add-symbolic",
            url: url,
            action: function() {
                addStickerPack(url)
            }
        }]
    }

    // Add a sticker pack from URL
    function addStickerPack(url) {
        const result = StickerService.addPackFromUrl(url)
        if (result) {
            if (result.exists) {
                console.log("StickerResults: Pack already exists:", result.id)
            } else {
                // Read directly from config object (not convenience property) to get latest state
                const currentPacks = (ConfigService.config?.stickers?.packs || []).slice()
                const alreadyInConfig = currentPacks.some(p => p.id === result.id)

                console.log("StickerResults: Current packs in config:", currentPacks.length, currentPacks.map(p => p.id))

                if (!alreadyInConfig) {
                    currentPacks.push({
                        id: result.id,
                        key: result.key,
                        name: result.name
                    })
                    ConfigService.setValue("stickers.packs", currentPacks)
                    ConfigService.saveConfig()
                    console.log("StickerResults: Added sticker pack:", result.id, "- total packs:", currentPacks.length)
                } else {
                    console.log("StickerResults: Pack already in config:", result.id)
                }
            }

            // Reset search to just the prefix to show stickers
            LauncherState.searchText = "s: "
        }
    }

    // Create result object for a sticker
    function createResult(sticker) {
        return {
            type: "sticker",
            sticker: sticker,
            emoji: sticker.emoji,
            title: sticker.emoji,
            description: sticker.packTitle,
            imagePath: sticker.imagePath,
            action: function() {
                StickerService.copySticker(sticker)
            }
        }
    }
}
