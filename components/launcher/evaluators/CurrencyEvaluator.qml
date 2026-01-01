import QtQuick
import Quickshell.Io

QtObject {
    property string name: "currency"

    // Supported currencies
    property var currencies: [
        "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "MXN",
        "BRL", "KRW", "SGD", "HKD", "NOK", "SEK", "DKK", "NZD", "ZAR", "RUB",
        "TRY", "PLN", "THB", "IDR", "MYR", "PHP", "CZK", "ILS", "CLP", "AED"
    ]

    // Cache for API results
    property var cache: ({})
    property string lastQuery: ""
    property var lastResult: null
    property bool isLoading: false

    // Process for API calls
    property var fetchProcess: Process {
        id: fetchProcess
        property string output: ""

        stdout: SplitParser {
            onRead: data => {
                fetchProcess.output += data
            }
        }

        onRunningChanged: {
            if (!running && output) {
                parseResponse(output)
                output = ""
            }
        }
    }

    // Debounce timer for API calls
    property var debounceTimer: Timer {
        interval: 300
        onTriggered: {
            if (pendingRequest) {
                executeRequest(pendingRequest)
                pendingRequest = null
            }
        }
    }

    property var pendingRequest: null

    function evaluate(input) {
        let trimmed = input.trim().toLowerCase()
        if (!trimmed) return null

        // Pattern: "100 USD to EUR" or "100 usd in eur"
        let match = trimmed.match(/^(\d+(?:\.\d+)?)\s*([a-z]{3})\s+(?:to|in)\s+([a-z]{3})$/)
        if (!match) return null

        let amount = parseFloat(match[1])
        let fromCurrency = match[2].toUpperCase()
        let toCurrency = match[3].toUpperCase()

        // Validate currencies
        if (!currencies.includes(fromCurrency) || !currencies.includes(toCurrency)) {
            return null
        }

        // Same currency
        if (fromCurrency === toCurrency) {
            return {
                value: "= " + formatNumber(amount) + " " + toCurrency,
                hint: "Same currency",
                copyValue: amount.toString()
            }
        }

        let cacheKey = fromCurrency + "_" + toCurrency + "_" + amount

        // Check cache (valid for 5 minutes)
        if (cache[cacheKey] && (Date.now() - cache[cacheKey].timestamp) < 300000) {
            return cache[cacheKey].result
        }

        // If we have a cached result for this query, return it while fetching new
        if (lastQuery === cacheKey && lastResult) {
            // Trigger background refresh
            queueRequest(amount, fromCurrency, toCurrency, cacheKey)
            return lastResult
        }

        // Queue the API request
        queueRequest(amount, fromCurrency, toCurrency, cacheKey)

        // Return loading state
        return {
            value: "= Converting...",
            hint: "Fetching live rates",
            copyValue: ""
        }
    }

    function queueRequest(amount, from, to, cacheKey) {
        pendingRequest = { amount: amount, from: from, to: to, cacheKey: cacheKey }
        debounceTimer.restart()
    }

    function executeRequest(req) {
        if (isLoading) return

        isLoading = true
        let url = "https://api.frankfurter.dev/latest?amount=" + req.amount + "&from=" + req.from + "&to=" + req.to

        fetchProcess.command = ["curl", "-s", url]
        fetchProcess.output = ""

        // Store pending info
        fetchProcess.pendingCacheKey = req.cacheKey
        fetchProcess.pendingTo = req.to
        fetchProcess.pendingAmount = req.amount

        fetchProcess.running = true
    }

    function parseResponse(response) {
        isLoading = false

        try {
            let data = JSON.parse(response)

            if (data.rates) {
                let toCurrency = fetchProcess.pendingTo
                let convertedAmount = data.rates[toCurrency]
                let cacheKey = fetchProcess.pendingCacheKey

                if (convertedAmount !== undefined) {
                    let result = {
                        value: "= " + formatNumber(convertedAmount) + " " + toCurrency,
                        hint: "Enter to copy (live rate)",
                        copyValue: convertedAmount.toFixed(2)
                    }

                    // Cache the result
                    cache[cacheKey] = {
                        result: result,
                        timestamp: Date.now()
                    }

                    lastQuery = cacheKey
                    lastResult = result
                }
            }
        } catch (e) {
            console.log("CurrencyEvaluator: Failed to parse response:", e)
        }
    }

    function formatNumber(num) {
        // Format with 2 decimal places and thousands separators
        return num.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    }
}
