import QtQuick

QtObject {
    property string name: "date"

    // Common holidays (month-day format, uses current/next year)
    property var holidays: {
        "christmas": { month: 12, day: 25 },
        "xmas": { month: 12, day: 25 },
        "new year": { month: 1, day: 1 },
        "newyear": { month: 1, day: 1 },
        "new years": { month: 1, day: 1 },
        "valentines": { month: 2, day: 14 },
        "valentine": { month: 2, day: 14 },
        "halloween": { month: 10, day: 31 },
        "independence day": { month: 7, day: 4 },
        "july 4th": { month: 7, day: 4 },
        "st patricks": { month: 3, day: 17 },
        "easter": null  // Variable date, skip for now
    }

    // Time unit multipliers in days
    property var timeUnits: {
        "day": 1,
        "days": 1,
        "week": 7,
        "weeks": 7,
        "month": 30,
        "months": 30,
        "year": 365,
        "years": 365
    }

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern 1: "days until <date/holiday>" or "days till <date/holiday>"
        let untilMatch = trimmed.match(/^days?\s+(?:until|till)\s+(.+)$/)
        if (untilMatch) {
            return calculateDaysUntil(untilMatch[1])
        }

        // Pattern 2: "days since <date>"
        let sinceMatch = trimmed.match(/^days?\s+since\s+(.+)$/)
        if (sinceMatch) {
            return calculateDaysSince(sinceMatch[1])
        }

        // Pattern 3: "date + 2 weeks" or "today + 3 days"
        let addMatch = trimmed.match(/^(?:date|today)\s*\+\s*(\d+)\s*(day|days|week|weeks|month|months|year|years)$/)
        if (addMatch) {
            return calculateDateAdd(parseInt(addMatch[1]), addMatch[2])
        }

        // Pattern 4: "date - 2 weeks" or "today - 3 days"
        let subMatch = trimmed.match(/^(?:date|today)\s*-\s*(\d+)\s*(day|days|week|weeks|month|months|year|years)$/)
        if (subMatch) {
            return calculateDateAdd(-parseInt(subMatch[1]), subMatch[2])
        }

        // Pattern 5: Just "today" or "now"
        if (trimmed === "today" || trimmed === "now") {
            let today = new Date()
            let formatted = formatDate(today)
            return {
                value: "= " + formatted,
                hint: "Enter to copy",
                copyValue: formatted
            }
        }

        return null
    }

    function calculateDaysUntil(target) {
        let targetDate = parseDate(target)
        if (!targetDate) return null

        let today = new Date()
        today.setHours(0, 0, 0, 0)

        let diff = targetDate.getTime() - today.getTime()
        let days = Math.ceil(diff / (1000 * 60 * 60 * 24))

        let result
        if (days === 0) {
            result = "Today!"
        } else if (days === 1) {
            result = "Tomorrow (1 day)"
        } else if (days > 0) {
            result = days + " days"
        } else {
            result = Math.abs(days) + " days ago"
        }

        return {
            value: "= " + result,
            hint: "Enter to copy",
            copyValue: days.toString()
        }
    }

    function calculateDaysSince(target) {
        let targetDate = parseDate(target)
        if (!targetDate) return null

        let today = new Date()
        today.setHours(0, 0, 0, 0)

        let diff = today.getTime() - targetDate.getTime()
        let days = Math.floor(diff / (1000 * 60 * 60 * 24))

        let result
        if (days === 0) {
            result = "Today"
        } else if (days === 1) {
            result = "Yesterday (1 day ago)"
        } else if (days > 0) {
            result = days + " days ago"
        } else {
            result = "In " + Math.abs(days) + " days"
        }

        return {
            value: "= " + result,
            hint: "Enter to copy",
            copyValue: Math.abs(days).toString()
        }
    }

    function calculateDateAdd(amount, unit) {
        let today = new Date()
        let days = amount * (timeUnits[unit] || 1)

        let result = new Date(today.getTime() + days * 24 * 60 * 60 * 1000)
        let formatted = formatDate(result)

        return {
            value: "= " + formatted,
            hint: "Enter to copy",
            copyValue: formatted
        }
    }

    function parseDate(str) {
        str = str.trim().toLowerCase()

        // Check holidays first
        if (holidays[str] && holidays[str] !== null) {
            let h = holidays[str]
            let year = new Date().getFullYear()
            let date = new Date(year, h.month - 1, h.day)

            // If holiday has passed this year, use next year
            if (date < new Date()) {
                date = new Date(year + 1, h.month - 1, h.day)
            }
            return date
        }

        // Try parsing as date string
        // Common formats: "2025-12-25", "12/25/2025", "Dec 25", "December 25 2025"

        // ISO format: 2025-12-25
        let isoMatch = str.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/)
        if (isoMatch) {
            return new Date(parseInt(isoMatch[1]), parseInt(isoMatch[2]) - 1, parseInt(isoMatch[3]))
        }

        // US format: 12/25/2025 or 12/25
        let usMatch = str.match(/^(\d{1,2})\/(\d{1,2})(?:\/(\d{2,4}))?$/)
        if (usMatch) {
            let year = usMatch[3] ? parseInt(usMatch[3]) : new Date().getFullYear()
            if (year < 100) year += 2000
            return new Date(year, parseInt(usMatch[1]) - 1, parseInt(usMatch[2]))
        }

        // Month name: "Dec 25" or "December 25 2025"
        let monthNames = {
            "jan": 0, "january": 0,
            "feb": 1, "february": 1,
            "mar": 2, "march": 2,
            "apr": 3, "april": 3,
            "may": 4,
            "jun": 5, "june": 5,
            "jul": 6, "july": 6,
            "aug": 7, "august": 7,
            "sep": 8, "september": 8,
            "oct": 9, "october": 9,
            "nov": 10, "november": 10,
            "dec": 11, "december": 11
        }

        let monthMatch = str.match(/^([a-z]+)\s+(\d{1,2})(?:\s+(\d{4}))?$/)
        if (monthMatch && monthNames[monthMatch[1]] !== undefined) {
            let year = monthMatch[3] ? parseInt(monthMatch[3]) : new Date().getFullYear()
            return new Date(year, monthNames[monthMatch[1]], parseInt(monthMatch[2]))
        }

        return null
    }

    function formatDate(date) {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        return days[date.getDay()] + ", " + months[date.getMonth()] + " " + date.getDate() + ", " + date.getFullYear()
    }
}
