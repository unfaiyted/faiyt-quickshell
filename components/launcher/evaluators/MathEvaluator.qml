import QtQuick

QtObject {
    property string name: "math"

    // Evaluate mathematical expressions
    function evaluate(input) {
        let trimmed = input.trim()
        if (!trimmed) return null

        // Must contain at least one math operator or be a number with operations
        let hasMathOps = /[\+\-\*\/\^%\(\)]/.test(trimmed)
        if (!hasMathOps) return null

        // Don't evaluate if it looks like a prefix search
        if (/^[a-z]+:/.test(trimmed)) return null

        try {
            // Sanitize and prepare expression
            let expr = trimmed
                // Replace ^ with ** for exponentiation
                .replace(/\^/g, '**')
                // Remove any characters that aren't math-related
                .replace(/[^0-9\+\-\*\/\.\(\)\s%]/g, '')

            // Don't evaluate if expression is too simple or invalid
            if (!expr || expr === trimmed.replace(/[^0-9]/g, '')) return null

            // Evaluate - QML supports eval for simple math
            let result = eval(expr)

            // Check if result is valid
            if (typeof result !== 'number' || !isFinite(result)) return null

            // Format result
            let formatted = formatNumber(result)

            // Don't show if result equals input (e.g., just "5")
            if (formatted === trimmed) return null

            return {
                value: "= " + formatted,
                hint: "Enter to copy",
                copyValue: formatted
            }
        } catch (e) {
            return null
        }
    }

    function formatNumber(num) {
        // Handle very small decimals
        if (Math.abs(num) < 0.0001 && num !== 0) {
            return num.toExponential(4)
        }

        // Round to avoid floating point issues
        let rounded = Math.round(num * 1000000) / 1000000

        // Format with appropriate decimal places
        if (Number.isInteger(rounded)) {
            return rounded.toString()
        } else {
            // Limit decimal places
            let str = rounded.toString()
            let parts = str.split('.')
            if (parts[1] && parts[1].length > 6) {
                return rounded.toFixed(6).replace(/\.?0+$/, '')
            }
            return str
        }
    }
}
