import QtQuick

QtObject {
    property string name: "unit"

    // Unit conversion factors (to base unit)
    property var units: {
        // Length (base: meters)
        "length": {
            "m": 1, "meter": 1, "meters": 1,
            "km": 1000, "kilometer": 1000, "kilometers": 1000,
            "cm": 0.01, "centimeter": 0.01, "centimeters": 0.01,
            "mm": 0.001, "millimeter": 0.001, "millimeters": 0.001,
            "mi": 1609.344, "mile": 1609.344, "miles": 1609.344,
            "yd": 0.9144, "yard": 0.9144, "yards": 0.9144,
            "ft": 0.3048, "foot": 0.3048, "feet": 0.3048,
            "in": 0.0254, "inch": 0.0254, "inches": 0.0254
        },
        // Weight (base: grams)
        "weight": {
            "g": 1, "gram": 1, "grams": 1,
            "kg": 1000, "kilogram": 1000, "kilograms": 1000,
            "mg": 0.001, "milligram": 0.001, "milligrams": 0.001,
            "lb": 453.592, "lbs": 453.592, "pound": 453.592, "pounds": 453.592,
            "oz": 28.3495, "ounce": 28.3495, "ounces": 28.3495
        },
        // Volume (base: liters)
        "volume": {
            "l": 1, "liter": 1, "liters": 1, "litre": 1, "litres": 1,
            "ml": 0.001, "milliliter": 0.001, "milliliters": 0.001,
            "gal": 3.78541, "gallon": 3.78541, "gallons": 3.78541,
            "qt": 0.946353, "quart": 0.946353, "quarts": 0.946353,
            "pt": 0.473176, "pint": 0.473176, "pints": 0.473176,
            "cup": 0.236588, "cups": 0.236588,
            "floz": 0.0295735, "fl oz": 0.0295735
        },
        // Data (base: bytes)
        "data": {
            "b": 1, "byte": 1, "bytes": 1,
            "kb": 1024, "kilobyte": 1024, "kilobytes": 1024,
            "mb": 1048576, "megabyte": 1048576, "megabytes": 1048576,
            "gb": 1073741824, "gigabyte": 1073741824, "gigabytes": 1073741824,
            "tb": 1099511627776, "terabyte": 1099511627776, "terabytes": 1099511627776
        }
    }

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern: "X unit to unit" or "X unit in unit"
        let match = trimmed.match(/^(-?\d+(?:\.\d+)?)\s*([a-z\s]+?)\s+(?:to|in|as)\s+([a-z\s]+)$/)
        if (!match) {
            // Try without "to/in" - just "X unit unit"
            match = trimmed.match(/^(-?\d+(?:\.\d+)?)\s*([a-z]+)\s+([a-z]+)$/)
        }
        if (!match) return null

        let value = parseFloat(match[1])
        let fromUnit = match[2].trim()
        let toUnit = match[3].trim()

        // Handle temperature separately
        let tempResult = convertTemperature(value, fromUnit, toUnit)
        if (tempResult !== null) {
            return {
                value: "= " + tempResult.formatted,
                hint: "Enter to copy",
                copyValue: tempResult.value
            }
        }

        // Find which category these units belong to
        for (let category in units) {
            let categoryUnits = units[category]
            if (categoryUnits[fromUnit] !== undefined && categoryUnits[toUnit] !== undefined) {
                // Convert to base, then to target
                let baseValue = value * categoryUnits[fromUnit]
                let result = baseValue / categoryUnits[toUnit]
                let formatted = formatNumber(result) + " " + toUnit
                return {
                    value: "= " + formatted,
                    hint: "Enter to copy",
                    copyValue: formatNumber(result)
                }
            }
        }

        return null
    }

    function convertTemperature(value, from, to) {
        // Normalize temperature unit names
        let fromNorm = normalizeTemp(from)
        let toNorm = normalizeTemp(to)

        if (!fromNorm || !toNorm || fromNorm === toNorm) return null

        let celsius
        // Convert to Celsius first
        switch (fromNorm) {
            case 'c': celsius = value; break
            case 'f': celsius = (value - 32) * 5/9; break
            case 'k': celsius = value - 273.15; break
            default: return null
        }

        // Convert from Celsius to target
        let result
        let symbol
        switch (toNorm) {
            case 'c': result = celsius; symbol = "°C"; break
            case 'f': result = (celsius * 9/5) + 32; symbol = "°F"; break
            case 'k': result = celsius + 273.15; symbol = "K"; break
            default: return null
        }

        return {
            value: formatNumber(result),
            formatted: formatNumber(result) + symbol
        }
    }

    function normalizeTemp(unit) {
        unit = unit.toLowerCase().replace('°', '')
        if (['c', 'celsius'].includes(unit)) return 'c'
        if (['f', 'fahrenheit'].includes(unit)) return 'f'
        if (['k', 'kelvin'].includes(unit)) return 'k'
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
