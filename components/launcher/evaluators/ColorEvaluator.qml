import QtQuick

QtObject {
    property string name: "color"

    // Named colors
    property var namedColors: {
        "red": "#FF0000",
        "green": "#008000",
        "blue": "#0000FF",
        "yellow": "#FFFF00",
        "cyan": "#00FFFF",
        "magenta": "#FF00FF",
        "black": "#000000",
        "white": "#FFFFFF",
        "gray": "#808080",
        "grey": "#808080",
        "orange": "#FFA500",
        "purple": "#800080",
        "brown": "#A52A2A",
        "pink": "#FFC0CB",
        "lime": "#00FF00",
        "navy": "#000080",
        "teal": "#008080",
        "silver": "#C0C0C0",
        "gold": "#FFD700",
        "indigo": "#4B0082",
        "violet": "#EE82EE"
    }

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern: "color to/as format" (e.g., "#FF5733 to rgb", "red as hex")
        let toMatch = trimmed.match(/^(.+?)\s+(to|as)\s+(hex|rgb|hsl)$/)
        if (toMatch) {
            let colorStr = toMatch[1].trim()
            let format = toMatch[3]
            let rgb = parseColor(colorStr)
            if (!rgb) return null

            let result = convertToFormat(rgb, format)
            let hexColor = rgbToHex(rgb)
            return {
                value: "= " + result,
                hint: "Enter to copy",
                copyValue: result,
                color: hexColor
            }
        }

        // Pattern: just a color - show all formats
        let rgb = parseColor(trimmed)
        if (rgb) {
            let hex = rgbToHex(rgb)
            let hsl = rgbToHsl(rgb)
            let result = hex + " | rgb(" + rgb.r + ", " + rgb.g + ", " + rgb.b + ") | hsl(" + hsl.h + ", " + hsl.s + "%, " + hsl.l + "%)"
            return {
                value: "= " + result,
                hint: "Enter to copy hex",
                copyValue: hex,
                color: hex
            }
        }

        return null
    }

    function parseColor(color) {
        // Named color
        if (namedColors[color]) {
            return hexToRgb(namedColors[color])
        }

        // Hex color (with or without #)
        let hexMatch = color.match(/^#?([0-9a-f]{3}|[0-9a-f]{6})$/i)
        if (hexMatch) {
            return hexToRgb("#" + hexMatch[1])
        }

        // RGB color: rgb(r, g, b)
        let rgbMatch = color.match(/^rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)$/)
        if (rgbMatch) {
            let r = parseInt(rgbMatch[1])
            let g = parseInt(rgbMatch[2])
            let b = parseInt(rgbMatch[3])
            if (r <= 255 && g <= 255 && b <= 255) {
                return { r: r, g: g, b: b }
            }
        }

        // HSL color: hsl(h, s%, l%)
        let hslMatch = color.match(/^hsl\s*\(\s*(\d+)\s*,\s*(\d+)%?\s*,\s*(\d+)%?\s*\)$/)
        if (hslMatch) {
            let hsl = {
                h: parseInt(hslMatch[1]),
                s: parseInt(hslMatch[2]),
                l: parseInt(hslMatch[3])
            }
            return hslToRgb(hsl)
        }

        return null
    }

    function convertToFormat(rgb, format) {
        switch (format) {
            case "hex":
                return rgbToHex(rgb)
            case "rgb":
                return "rgb(" + rgb.r + ", " + rgb.g + ", " + rgb.b + ")"
            case "hsl":
                let hsl = rgbToHsl(rgb)
                return "hsl(" + hsl.h + ", " + hsl.s + "%, " + hsl.l + "%)"
            default:
                return null
        }
    }

    function hexToRgb(hex) {
        hex = hex.replace(/^#/, "")

        // Handle 3-digit hex
        if (hex.length === 3) {
            hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2]
        }

        let result = /^([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : null
    }

    function toHex(n) {
        let hex = n.toString(16)
        return hex.length === 1 ? "0" + hex : hex
    }

    function rgbToHex(rgb) {
        return "#" + toHex(rgb.r).toUpperCase() + toHex(rgb.g).toUpperCase() + toHex(rgb.b).toUpperCase()
    }

    function rgbToHsl(rgb) {
        let r = rgb.r / 255
        let g = rgb.g / 255
        let b = rgb.b / 255

        let max = Math.max(r, g, b)
        let min = Math.min(r, g, b)
        let h = 0, s = 0, l = (max + min) / 2

        if (max !== min) {
            let d = max - min
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min)

            switch (max) {
                case r:
                    h = ((g - b) / d + (g < b ? 6 : 0)) / 6
                    break
                case g:
                    h = ((b - r) / d + 2) / 6
                    break
                case b:
                    h = ((r - g) / d + 4) / 6
                    break
            }
        }

        return {
            h: Math.round(h * 360),
            s: Math.round(s * 100),
            l: Math.round(l * 100)
        }
    }

    function hue2rgb(p, q, t) {
        if (t < 0) t += 1
        if (t > 1) t -= 1
        if (t < 1/6) return p + (q - p) * 6 * t
        if (t < 1/2) return q
        if (t < 2/3) return p + (q - p) * (2/3 - t) * 6
        return p
    }

    function hslToRgb(hsl) {
        let h = hsl.h / 360
        let s = hsl.s / 100
        let l = hsl.l / 100

        let r, g, b

        if (s === 0) {
            r = g = b = l
        } else {
            let q = l < 0.5 ? l * (1 + s) : l + s - l * s
            let p = 2 * l - q
            r = hue2rgb(p, q, h + 1/3)
            g = hue2rgb(p, q, h)
            b = hue2rgb(p, q, h - 1/3)
        }

        return {
            r: Math.round(r * 255),
            g: Math.round(g * 255),
            b: Math.round(b * 255)
        }
    }
}
