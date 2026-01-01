import QtQuick

QtObject {
    property string name: "password"

    // Character sets
    property string lowercase: "abcdefghijklmnopqrstuvwxyz"
    property string uppercase: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    property string numbers: "0123456789"
    property string symbols: "!@#$%^&*()_+-=[]{}|;:,.<>?"

    // Full charset
    property string charset: lowercase + uppercase + numbers + symbols

    // Cache the generated password
    property string cachedPassword: ""
    property string lastInput: ""

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern: "pass", "pass 16", "password", "password 20"
        let match = trimmed.match(/^pass(?:word)?\s*(\d+)?$/)
        if (!match) return null

        let length = match[1] ? parseInt(match[1]) : 16

        // Clamp length to reasonable bounds
        length = Math.max(4, Math.min(128, length))

        // Generate new password only if input changed
        if (lastInput !== trimmed || !cachedPassword) {
            cachedPassword = generatePassword(length)
            lastInput = trimmed
        }

        return {
            value: "= " + cachedPassword,
            hint: "Enter to copy (" + length + " chars)",
            copyValue: cachedPassword
        }
    }

    function generatePassword(length) {
        let password = ""

        // Ensure at least one of each type for strong passwords
        if (length >= 4) {
            password += lowercase[Math.floor(Math.random() * lowercase.length)]
            password += uppercase[Math.floor(Math.random() * uppercase.length)]
            password += numbers[Math.floor(Math.random() * numbers.length)]
            password += symbols[Math.floor(Math.random() * symbols.length)]
            length -= 4
        }

        // Fill remaining with random chars from full charset
        for (let i = 0; i < length; i++) {
            password += charset[Math.floor(Math.random() * charset.length)]
        }

        // Shuffle the password
        return shuffleString(password)
    }

    function shuffleString(str) {
        let arr = str.split('')
        for (let i = arr.length - 1; i > 0; i--) {
            let j = Math.floor(Math.random() * (i + 1))
            let temp = arr[i]
            arr[i] = arr[j]
            arr[j] = temp
        }
        return arr.join('')
    }

    function reset() {
        cachedPassword = ""
        lastInput = ""
    }
}
