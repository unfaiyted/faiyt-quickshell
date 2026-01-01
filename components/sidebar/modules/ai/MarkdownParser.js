// MarkdownParser.js - Parse markdown content into blocks and convert to Qt RichText

/**
 * Parse content into an array of blocks (text or code)
 * @param {string} content - Raw markdown content
 * @returns {Array<{type: 'text'|'code', content: string, lang?: string}>}
 */
function parseContent(content) {
    if (!content) return []

    const blocks = []
    const codeBlockRegex = /```(\w*)\n?([\s\S]*?)```/g
    let lastIndex = 0
    let match

    while ((match = codeBlockRegex.exec(content)) !== null) {
        // Add text before code block
        if (match.index > lastIndex) {
            const textContent = content.slice(lastIndex, match.index)
            if (textContent.trim()) {
                blocks.push({ type: 'text', content: textContent.trim() })
            }
        }

        // Add code block
        const lang = match[1] || 'text'
        const code = match[2] ? match[2].trim() : ''
        if (code) {
            blocks.push({ type: 'code', content: code, lang: lang })
        }

        lastIndex = match.index + match[0].length
    }

    // Add remaining text
    if (lastIndex < content.length) {
        const remainingText = content.slice(lastIndex)
        if (remainingText.trim()) {
            blocks.push({ type: 'text', content: remainingText.trim() })
        }
    }

    // If no blocks were created, treat entire content as text
    if (blocks.length === 0 && content.trim()) {
        blocks.push({ type: 'text', content: content.trim() })
    }

    return blocks
}

/**
 * Convert markdown text to Qt RichText (HTML subset)
 * @param {string} text - Markdown text
 * @param {object} colors - Color values from theme
 * @returns {string} HTML string for Qt Text with textFormat: Text.RichText
 */
function markdownToRichText(text, colors) {
    if (!text) return ''

    let formatted = escapeHtml(text)

    // Headers (process from h6 to h1 to avoid conflicts)
    formatted = formatted.replace(/^###### (.*?)$/gm, '<h6 style="font-size: 10px; font-weight: bold; margin: 4px 0;">$1</h6>')
    formatted = formatted.replace(/^##### (.*?)$/gm, '<h5 style="font-size: 11px; font-weight: bold; margin: 4px 0;">$1</h5>')
    formatted = formatted.replace(/^#### (.*?)$/gm, '<h4 style="font-size: 12px; font-weight: bold; margin: 4px 0;">$1</h4>')
    formatted = formatted.replace(/^### (.*?)$/gm, '<h3 style="font-size: 13px; font-weight: bold; margin: 6px 0;">$1</h3>')
    formatted = formatted.replace(/^## (.*?)$/gm, '<h2 style="font-size: 14px; font-weight: bold; margin: 6px 0;">$1</h2>')
    formatted = formatted.replace(/^# (.*?)$/gm, '<h1 style="font-size: 16px; font-weight: bold; margin: 8px 0;">$1</h1>')

    // Horizontal rules
    formatted = formatted.replace(/^(---|\*\*\*|___)\s*$/gm, '<hr style="border: none; border-top: 1px solid ' + (colors?.border || '#6e6a86') + '; margin: 8px 0;">')

    // Blockquotes
    formatted = formatted.replace(/^&gt; (.*?)$/gm, '<blockquote style="border-left: 3px solid ' + (colors?.primary || '#c4a7e7') + '; padding-left: 8px; margin: 4px 0; color: ' + (colors?.foregroundMuted || '#908caa') + '; font-style: italic;">$1</blockquote>')

    // Links [text](url)
    formatted = formatted.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, '<a href="$2" style="color: ' + (colors?.primary || '#c4a7e7') + '; text-decoration: underline;">$1</a>')

    // Strikethrough ~~text~~
    formatted = formatted.replace(/~~(.*?)~~/g, '<s>$1</s>')

    // Bold **text** and __text__
    formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>')
    formatted = formatted.replace(/__(.*?)__/g, '<b>$1</b>')

    // Italic *text* and _text_ (avoid matching list items)
    formatted = formatted.replace(/(?<![*_\w])\*([^*\n]+)\*(?![*\w])/g, '<i>$1</i>')
    formatted = formatted.replace(/(?<![*_\w])_([^_\n]+)_(?![_\w])/g, '<i>$1</i>')

    // Inline code `code`
    formatted = formatted.replace(/`([^`]+)`/g, '<code style="background-color: ' + (colors?.backgroundAlt || '#26233a') + '; color: ' + (colors?.accent || '#ebbcba') + '; padding: 1px 4px; border-radius: 3px; font-family: monospace;">$1</code>')

    // Task lists
    formatted = formatted.replace(/^- \[x\] (.*?)$/gm, '<span style="color: ' + (colors?.success || '#9ccfd8') + ';">✓</span> <s>$1</s>')
    formatted = formatted.replace(/^- \[ \] (.*?)$/gm, '<span style="color: ' + (colors?.foregroundMuted || '#6e6a86') + ';">☐</span> $1')

    // Unordered lists (- item and * item)
    formatted = formatted.replace(/^(\s*)[-*] (.*?)$/gm, function(match, indent, text) {
        const level = Math.floor(indent.length / 2)
        const padding = '  '.repeat(level)
        return padding + '<span style="color: ' + (colors?.primary || '#eb6f92') + ';">•</span> ' + text
    })

    // Ordered lists (1. item)
    formatted = formatted.replace(/^(\s*)(\d+)\. (.*?)$/gm, function(match, indent, num, text) {
        const level = Math.floor(indent.length / 2)
        const padding = '  '.repeat(level)
        return padding + '<span style="color: ' + (colors?.accent || '#f6c177') + ';">' + num + '.</span> ' + text
    })

    // Convert newlines to <br> for proper line breaks
    formatted = formatted.replace(/\n/g, '<br>')

    return formatted
}

/**
 * Escape HTML special characters
 */
function escapeHtml(text) {
    return text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;')
}

/**
 * Check if content contains incomplete code block (streaming)
 */
function hasIncompleteCodeBlock(content) {
    const openCount = (content.match(/```/g) || []).length
    return openCount % 2 !== 0
}
