import QtQuick

QtObject {
    property string name: "percentage"

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern: "X% of Y" - calculate percentage of value
        let ofMatch = trimmed.match(/^(\d+(?:\.\d+)?)\s*%\s*of\s+(\d+(?:\.\d+)?)$/)
        if (ofMatch) {
            let percent = parseFloat(ofMatch[1])
            let value = parseFloat(ofMatch[2])
            let result = (percent / 100) * value
            return {
                value: "= " + formatNumber(result),
                hint: "Enter to copy",
                copyValue: formatNumber(result)
            }
        }

        // Pattern: "X% off Y" - calculate discount
        let offMatch = trimmed.match(/^(\d+(?:\.\d+)?)\s*%\s*off\s+(\d+(?:\.\d+)?)$/)
        if (offMatch) {
            let percent = parseFloat(offMatch[1])
            let value = parseFloat(offMatch[2])
            let discount = (percent / 100) * value
            let result = value - discount
            return {
                value: "= " + formatNumber(result) + " (-" + formatNumber(discount) + ")",
                hint: "Enter to copy",
                copyValue: formatNumber(result)
            }
        }

        // Pattern: "X is what % of Y" or "X of Y %"
        let whatPercentMatch = trimmed.match(/^(\d+(?:\.\d+)?)\s+(?:is\s+)?(?:what\s+)?%?\s*of\s+(\d+(?:\.\d+)?)\s*%?$/)
        if (whatPercentMatch) {
            let part = parseFloat(whatPercentMatch[1])
            let whole = parseFloat(whatPercentMatch[2])
            if (whole !== 0) {
                let result = (part / whole) * 100
                return {
                    value: "= " + formatNumber(result) + "%",
                    hint: "Enter to copy",
                    copyValue: formatNumber(result) + "%"
                }
            }
        }

        // Pattern: "X + Y%" - add percentage
        let addMatch = trimmed.match(/^(\d+(?:\.\d+)?)\s*\+\s*(\d+(?:\.\d+)?)\s*%$/)
        if (addMatch) {
            let value = parseFloat(addMatch[1])
            let percent = parseFloat(addMatch[2])
            let increase = (percent / 100) * value
            let result = value + increase
            return {
                value: "= " + formatNumber(result),
                hint: "Enter to copy",
                copyValue: formatNumber(result)
            }
        }

        // Pattern: "X - Y%" - subtract percentage
        let subMatch = trimmed.match(/^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*%$/)
        if (subMatch) {
            let value = parseFloat(subMatch[1])
            let percent = parseFloat(subMatch[2])
            let decrease = (percent / 100) * value
            let result = value - decrease
            return {
                value: "= " + formatNumber(result),
                hint: "Enter to copy",
                copyValue: formatNumber(result)
            }
        }

        return null
    }

    function formatNumber(num) {
        let rounded = Math.round(num * 100) / 100
        if (Number.isInteger(rounded)) {
            return rounded.toString()
        }
        return rounded.toFixed(2).replace(/\.?0+$/, '')
    }
}
