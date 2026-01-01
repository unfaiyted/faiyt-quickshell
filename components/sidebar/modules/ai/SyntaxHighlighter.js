// SyntaxHighlighter.js - Syntax highlighting for code blocks

// Rose Pine inspired colors for syntax highlighting
const defaultColors = {
    keyword: '#c4a7e7',      // iris - purple
    string: '#f6c177',       // gold - yellow/orange
    comment: '#6e6a86',      // muted
    number: '#ebbcba',       // rose
    function: '#9ccfd8',     // foam - cyan
    operator: '#eb6f92',     // love - pink
    property: '#31748f',     // pine - teal
    type: '#c4a7e7',         // iris
    variable: '#e0def4',     // text
    punctuation: '#908caa',  // subtle
    default: '#e0def4'       // text
}

// Language definitions with regex patterns
const languages = {
    javascript: {
        aliases: ['js', 'jsx', 'typescript', 'ts', 'tsx'],
        keywords: /\b(const|let|var|function|return|if|else|for|while|do|switch|case|break|continue|new|this|class|extends|import|export|from|default|async|await|try|catch|finally|throw|typeof|instanceof|in|of|true|false|null|undefined|void)\b/g,
        strings: /(["'`])(?:(?!\1)[^\\]|\\.)*\1/g,
        comments: /(\/\/.*$|\/\*[\s\S]*?\*\/)/gm,
        numbers: /\b(\d+\.?\d*|0x[a-fA-F0-9]+)\b/g,
        functions: /\b([a-zA-Z_$][a-zA-Z0-9_$]*)\s*(?=\()/g,
        operators: /([+\-*/%=!<>&|^~?:]|=>|\.\.\.)/g
    },
    python: {
        aliases: ['py', 'python3'],
        keywords: /\b(def|class|if|elif|else|for|while|try|except|finally|with|as|import|from|return|yield|raise|pass|break|continue|and|or|not|in|is|True|False|None|lambda|global|nonlocal|async|await)\b/g,
        strings: /("""[\s\S]*?"""|'''[\s\S]*?'''|"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/g,
        comments: /(#.*$)/gm,
        numbers: /\b(\d+\.?\d*|0x[a-fA-F0-9]+|0b[01]+|0o[0-7]+)\b/g,
        functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
        decorators: /(@[a-zA-Z_][a-zA-Z0-9_]*)/g
    },
    bash: {
        aliases: ['sh', 'shell', 'zsh'],
        keywords: /\b(if|then|else|elif|fi|for|while|do|done|case|esac|function|return|exit|export|source|alias|unset|local|readonly|declare)\b/g,
        strings: /(["'])(?:(?!\1)[^\\]|\\.)*\1/g,
        comments: /(#.*$)/gm,
        numbers: /\b(\d+)\b/g,
        variables: /(\$[a-zA-Z_][a-zA-Z0-9_]*|\$\{[^}]+\}|\$\([^)]+\))/g,
        operators: /([|&;<>()]|>>|<<|\|\||\&\&)/g
    },
    json: {
        aliases: [],
        strings: /("(?:[^"\\]|\\.)*")\s*:/g,
        values: /:\s*("(?:[^"\\]|\\.)*")/g,
        numbers: /:\s*(-?\d+\.?\d*)/g,
        booleans: /:\s*(true|false|null)\b/g,
        punctuation: /([{}[\]:,])/g
    },
    qml: {
        aliases: [],
        keywords: /\b(import|property|signal|function|Component|Item|Rectangle|Text|Row|Column|Repeater|ListView|MouseArea|Timer|Connections|Binding|alias|readonly|required|default|on[A-Z][a-zA-Z]*)\b/g,
        types: /\b(int|real|double|string|bool|var|list|url|color|font|date|point|size|rect|vector2d|vector3d|vector4d|quaternion|matrix4x4)\b/g,
        strings: /(["'])(?:(?!\1)[^\\]|\\.)*\1/g,
        comments: /(\/\/.*$|\/\*[\s\S]*?\*\/)/gm,
        numbers: /\b(\d+\.?\d*)\b/g,
        properties: /([a-zA-Z][a-zA-Z0-9_]*)\s*:/g,
        ids: /\bid\s*:\s*([a-zA-Z_][a-zA-Z0-9_]*)/g
    },
    css: {
        aliases: ['scss', 'sass', 'less'],
        selectors: /([.#]?[a-zA-Z_-][a-zA-Z0-9_-]*)\s*\{/g,
        properties: /([a-zA-Z-]+)\s*:/g,
        values: /:\s*([^;{}]+)/g,
        strings: /(["'])(?:(?!\1)[^\\]|\\.)*\1/g,
        comments: /(\/\*[\s\S]*?\*\/)/gm,
        numbers: /\b(\d+\.?\d*(px|em|rem|%|vh|vw|deg|s|ms)?)\b/g,
        colors: /(#[a-fA-F0-9]{3,8}|rgba?\([^)]+\)|hsla?\([^)]+\))/g
    },
    rust: {
        aliases: ['rs'],
        keywords: /\b(fn|let|mut|const|static|if|else|match|for|while|loop|break|continue|return|struct|enum|impl|trait|pub|mod|use|crate|self|super|where|async|await|move|ref|type|unsafe|extern|dyn|macro_rules)\b/g,
        types: /\b(i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize|f32|f64|bool|char|str|String|Vec|Option|Result|Box|Rc|Arc|Self)\b/g,
        strings: /(r#*"[\s\S]*?"#*|"(?:[^"\\]|\\.)*")/g,
        comments: /(\/\/.*$|\/\*[\s\S]*?\*\/)/gm,
        numbers: /\b(\d+\.?\d*(_\d+)*(f32|f64|i32|u32|usize)?)\b/g,
        macros: /\b([a-zA-Z_][a-zA-Z0-9_]*!)/g,
        lifetimes: /('[a-zA-Z_][a-zA-Z0-9_]*)/g
    },
    go: {
        aliases: ['golang'],
        keywords: /\b(func|return|if|else|for|range|switch|case|default|break|continue|goto|fallthrough|defer|go|select|chan|map|struct|interface|type|package|import|const|var|nil|true|false|iota)\b/g,
        types: /\b(int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|uintptr|float32|float64|complex64|complex128|byte|rune|string|bool|error)\b/g,
        strings: /(["'`])(?:(?!\1)[^\\]|\\.)*\1/g,
        comments: /(\/\/.*$|\/\*[\s\S]*?\*\/)/gm,
        numbers: /\b(\d+\.?\d*)\b/g,
        functions: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g
    },
    cpp: {
        aliases: ['c', 'c++', 'cxx', 'h', 'hpp'],
        keywords: /\b(auto|break|case|catch|class|const|continue|default|delete|do|else|enum|explicit|export|extern|false|for|friend|goto|if|inline|mutable|namespace|new|noexcept|nullptr|operator|private|protected|public|register|return|sizeof|static|struct|switch|template|this|throw|true|try|typedef|typeid|typename|union|using|virtual|volatile|while|override|final)\b/g,
        types: /\b(void|bool|char|short|int|long|float|double|signed|unsigned|wchar_t|size_t|int8_t|int16_t|int32_t|int64_t|uint8_t|uint16_t|uint32_t|uint64_t|string|vector|map|set|list|array|unique_ptr|shared_ptr)\b/g,
        preprocessor: /(#\s*(include|define|undef|ifdef|ifndef|if|else|elif|endif|pragma|error|warning).*$)/gm,
        strings: /(["'])(?:(?!\1)[^\\]|\\.)*\1/g,
        comments: /(\/\/.*$|\/\*[\s\S]*?\*\/)/gm,
        numbers: /\b(\d+\.?\d*[fFlLuU]*|0x[a-fA-F0-9]+[uUlL]*)\b/g
    }
}

/**
 * Get language definition by name or alias
 */
function getLanguage(lang) {
    const normalized = lang.toLowerCase().trim()

    // Direct match
    if (languages[normalized]) {
        return languages[normalized]
    }

    // Check aliases
    for (const [name, def] of Object.entries(languages)) {
        if (def.aliases && def.aliases.includes(normalized)) {
            return def
        }
    }

    return null
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
}

/**
 * Highlight code with syntax colors
 * @param {string} code - Source code to highlight
 * @param {string} language - Language name
 * @param {object} colors - Optional custom colors
 * @returns {string} HTML with syntax highlighting spans
 */
function highlight(code, language, colors) {
    if (!code) return ''

    const c = colors || defaultColors
    const lang = getLanguage(language)

    // If language not recognized, return escaped code with line breaks
    if (!lang) {
        return escapeHtml(code).replace(/\n/g, '<br>')
    }

    // Tokenize and highlight
    let result = escapeHtml(code)

    // Track positions to avoid overlapping replacements
    const replacements = []

    // Helper to find matches and queue replacements
    function findMatches(regex, colorKey, groupIndex = 0) {
        const pattern = new RegExp(regex.source, regex.flags)
        let match
        while ((match = pattern.exec(code)) !== null) {
            const text = match[groupIndex] || match[0]
            const start = match.index + (groupIndex > 0 ? match[0].indexOf(text) : 0)
            replacements.push({
                start,
                end: start + text.length,
                text,
                color: c[colorKey] || c.default
            })
        }
    }

    // Process patterns in order (comments and strings first to avoid conflicts)
    if (lang.comments) findMatches(lang.comments, 'comment')
    if (lang.strings) findMatches(lang.strings, 'string')
    if (lang.preprocessor) findMatches(lang.preprocessor, 'keyword')
    if (lang.keywords) findMatches(lang.keywords, 'keyword')
    if (lang.types) findMatches(lang.types, 'type')
    if (lang.numbers) findMatches(lang.numbers, 'number')
    if (lang.functions) findMatches(lang.functions, 'function', 1)
    if (lang.variables) findMatches(lang.variables, 'variable')
    if (lang.operators) findMatches(lang.operators, 'operator')
    if (lang.decorators) findMatches(lang.decorators, 'function')
    if (lang.macros) findMatches(lang.macros, 'function')
    if (lang.lifetimes) findMatches(lang.lifetimes, 'type')
    if (lang.booleans) findMatches(lang.booleans, 'keyword', 1)
    if (lang.properties) findMatches(lang.properties, 'property', 1)
    if (lang.selectors) findMatches(lang.selectors, 'function', 1)
    if (lang.colors) findMatches(lang.colors, 'string')
    if (lang.ids) findMatches(lang.ids, 'variable', 1)
    if (lang.punctuation) findMatches(lang.punctuation, 'punctuation')

    // Sort by start position, longer matches first for same position
    replacements.sort((a, b) => {
        if (a.start !== b.start) return a.start - b.start
        return b.end - a.end
    })

    // Remove overlapping replacements (keep first/longer)
    const filtered = []
    let lastEnd = -1
    for (const r of replacements) {
        if (r.start >= lastEnd) {
            filtered.push(r)
            lastEnd = r.end
        }
    }

    // Apply replacements from end to start to preserve positions
    filtered.reverse()
    for (const r of filtered) {
        const before = result.slice(0, getEscapedIndex(code, result, r.start))
        const after = result.slice(getEscapedIndex(code, result, r.end))
        const highlighted = '<span style="color: ' + r.color + ';">' + escapeHtml(r.text) + '</span>'
        result = before + highlighted + after
    }

    // Convert newlines to <br> for proper line breaks in RichText
    result = result.replace(/\n/g, '<br>')

    return result
}

/**
 * Map original code index to escaped HTML index
 */
function getEscapedIndex(original, escaped, index) {
    let origI = 0
    let escI = 0

    while (origI < index && escI < escaped.length) {
        const char = original[origI]
        if (char === '&') escI += 5  // &amp;
        else if (char === '<') escI += 4  // &lt;
        else if (char === '>') escI += 4  // &gt;
        else if (char === '"') escI += 6  // &quot;
        else escI++
        origI++
    }

    return escI
}

/**
 * Get supported language names
 */
function getSupportedLanguages() {
    const langs = Object.keys(languages)
    for (const def of Object.values(languages)) {
        if (def.aliases) {
            langs.push(...def.aliases)
        }
    }
    return langs.sort()
}
