import QtQuick

QtObject {
    property string name: "base"

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern: "X to hex/bin/dec/oct"
        let toMatch = trimmed.match(/^(0x[0-9a-f]+|0b[01]+|0o[0-7]+|\d+)\s+to\s+(hex|bin|dec|oct|binary|decimal|octal|hexadecimal)$/)
        if (toMatch) {
            let value = parseValue(toMatch[1])
            if (value === null) return null

            let targetBase = normalizeBase(toMatch[2])
            let result = convertToBase(value, targetBase)
            return {
                value: "= " + result,
                hint: "Enter to copy",
                copyValue: result
            }
        }

        // Pattern: "0xFF" or "0b1010" - auto convert to decimal and show other bases
        let prefixMatch = trimmed.match(/^(0x[0-9a-f]+|0b[01]+|0o[0-7]+)$/)
        if (prefixMatch) {
            let value = parseValue(prefixMatch[1])
            if (value === null) return null

            // Detect which base it was and show decimal
            if (trimmed.startsWith('0x')) {
                return {
                    value: "= " + value + " (dec)",
                    hint: "Enter to copy",
                    copyValue: value.toString()
                }
            } else if (trimmed.startsWith('0b')) {
                return {
                    value: "= " + value + " (dec) | 0x" + value.toString(16).toUpperCase(),
                    hint: "Enter to copy",
                    copyValue: value.toString()
                }
            } else if (trimmed.startsWith('0o')) {
                return {
                    value: "= " + value + " (dec)",
                    hint: "Enter to copy",
                    copyValue: value.toString()
                }
            }
        }

        // Pattern: just a number - show hex and binary
        let numMatch = trimmed.match(/^(\d+)$/)
        if (numMatch) {
            let value = parseInt(numMatch[1], 10)
            if (isNaN(value) || value < 0) return null

            // Only show for reasonable numbers that look like they might be intentional
            // Skip single digits and very large numbers
            if (value < 10 || value > 4294967295) return null

            let hex = "0x" + value.toString(16).toUpperCase()
            let bin = "0b" + value.toString(2)

            // For small numbers also show binary
            if (value <= 65535) {
                return {
                    value: "= " + hex + " | " + bin,
                    hint: "Enter to copy hex",
                    copyValue: hex
                }
            }
            return {
                value: "= " + hex,
                hint: "Enter to copy",
                copyValue: hex
            }
        }

        return null
    }

    function parseValue(str) {
        str = str.toLowerCase()
        try {
            if (str.startsWith('0x')) {
                return parseInt(str.slice(2), 16)
            } else if (str.startsWith('0b')) {
                return parseInt(str.slice(2), 2)
            } else if (str.startsWith('0o')) {
                return parseInt(str.slice(2), 8)
            } else {
                return parseInt(str, 10)
            }
        } catch (e) {
            return null
        }
    }

    function normalizeBase(base) {
        switch (base) {
            case 'hex':
            case 'hexadecimal':
                return 16
            case 'bin':
            case 'binary':
                return 2
            case 'dec':
            case 'decimal':
                return 10
            case 'oct':
            case 'octal':
                return 8
            default:
                return null
        }
    }

    function convertToBase(value, base) {
        if (base === null) return null

        switch (base) {
            case 16:
                return "0x" + value.toString(16).toUpperCase()
            case 2:
                return "0b" + value.toString(2)
            case 8:
                return "0o" + value.toString(8)
            case 10:
                return value.toString()
            default:
                return null
        }
    }
}
