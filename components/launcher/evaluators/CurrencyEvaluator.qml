import QtQuick
import Quickshell.Io

QtObject {
    id: currencyEvaluator
    property string name: "currency"

    // Signal emitted when async result is ready
    signal resultReady()

    // Supported fiat currencies
    property var currencies: [
        "USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "INR", "MXN",
        "BRL", "KRW", "SGD", "HKD", "NOK", "SEK", "DKK", "NZD", "ZAR", "RUB",
        "TRY", "PLN", "THB", "IDR", "MYR", "PHP", "CZK", "ILS", "CLP", "AED"
    ]

    // Supported cryptocurrencies with CoinGecko IDs
    property var cryptoCurrencies: {
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "SOL": "solana",
        "DOGE": "dogecoin",
        "XRP": "ripple",
        "ADA": "cardano",
        "DOT": "polkadot",
        "MATIC": "matic-network",
        "LTC": "litecoin",
        "AVAX": "avalanche-2",
        "LINK": "chainlink",
        "UNI": "uniswap",
        "ATOM": "cosmos",
        "XLM": "stellar"
    }

    // Cache for API results
    property var cache: ({})
    property string lastQuery: ""
    property var lastResult: null
    property bool isLoading: false

    // Process for API calls
    property var fetchProcess: Process {
        id: fetchProcess
        property string output: ""
        property string pendingCacheKey: ""
        property string pendingTo: ""
        property string pendingFrom: ""
        property real pendingAmount: 0
        property bool pendingIsCrypto: false

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

        // Check if currencies are valid (fiat or crypto)
        let fromIsCrypto = cryptoCurrencies.hasOwnProperty(fromCurrency)
        let toIsCrypto = cryptoCurrencies.hasOwnProperty(toCurrency)
        let fromIsFiat = currencies.includes(fromCurrency)
        let toIsFiat = currencies.includes(toCurrency)

        // Validate currencies
        if ((!fromIsFiat && !fromIsCrypto) || (!toIsFiat && !toIsCrypto)) {
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

        // Determine if this is a crypto conversion
        let isCryptoConversion = fromIsCrypto || toIsCrypto

        // If we have a cached result for this query, return it while fetching new
        if (lastQuery === cacheKey && lastResult) {
            // Trigger background refresh
            queueRequest(amount, fromCurrency, toCurrency, cacheKey, isCryptoConversion)
            return lastResult
        }

        // Queue the API request
        queueRequest(amount, fromCurrency, toCurrency, cacheKey, isCryptoConversion)

        // Return loading state
        return {
            value: "= Converting...",
            hint: "Fetching live rates",
            copyValue: ""
        }
    }

    function queueRequest(amount, from, to, cacheKey, isCrypto) {
        pendingRequest = { amount: amount, from: from, to: to, cacheKey: cacheKey, isCrypto: isCrypto }
        debounceTimer.restart()
    }

    function executeRequest(req) {
        if (isLoading) return

        isLoading = true
        let url

        if (req.isCrypto) {
            // Use CoinGecko API for crypto conversions
            url = buildCryptoUrl(req.amount, req.from, req.to)
        } else {
            // Use Frankfurter API for fiat conversions
            url = "https://api.frankfurter.app/latest?amount=" + req.amount + "&from=" + req.from + "&to=" + req.to
        }

        fetchProcess.command = ["curl", "-s", url]
        fetchProcess.output = ""

        // Store pending info
        fetchProcess.pendingCacheKey = req.cacheKey
        fetchProcess.pendingTo = req.to
        fetchProcess.pendingFrom = req.from
        fetchProcess.pendingAmount = req.amount
        fetchProcess.pendingIsCrypto = req.isCrypto

        fetchProcess.running = true
    }

    function buildCryptoUrl(amount, from, to) {
        // Determine which is crypto and which is fiat
        let fromIsCrypto = cryptoCurrencies.hasOwnProperty(from)
        let toIsCrypto = cryptoCurrencies.hasOwnProperty(to)

        if (fromIsCrypto && !toIsCrypto) {
            // Crypto to fiat (e.g., BTC to USD)
            let cryptoId = cryptoCurrencies[from]
            let fiatLower = to.toLowerCase()
            return "https://api.coingecko.com/api/v3/simple/price?ids=" + cryptoId + "&vs_currencies=" + fiatLower
        } else if (!fromIsCrypto && toIsCrypto) {
            // Fiat to crypto (e.g., USD to BTC) - get crypto price in fiat, then invert
            let cryptoId = cryptoCurrencies[to]
            let fiatLower = from.toLowerCase()
            return "https://api.coingecko.com/api/v3/simple/price?ids=" + cryptoId + "&vs_currencies=" + fiatLower
        } else {
            // Crypto to crypto - get both in USD and convert
            let fromId = cryptoCurrencies[from]
            let toId = cryptoCurrencies[to]
            return "https://api.coingecko.com/api/v3/simple/price?ids=" + fromId + "," + toId + "&vs_currencies=usd"
        }
    }

    function parseResponse(response) {
        isLoading = false

        try {
            let data = JSON.parse(response)
            let cacheKey = fetchProcess.pendingCacheKey
            let toCurrency = fetchProcess.pendingTo
            let fromCurrency = fetchProcess.pendingFrom
            let amount = fetchProcess.pendingAmount
            let convertedAmount

            if (fetchProcess.pendingIsCrypto) {
                // Parse CoinGecko response
                convertedAmount = parseCryptoResponse(data, amount, fromCurrency, toCurrency)
            } else if (data.rates) {
                // Parse Frankfurter response
                convertedAmount = data.rates[toCurrency]
            }

            if (convertedAmount !== undefined && convertedAmount !== null) {
                // Use more decimal places for small crypto amounts
                let decimalPlaces = convertedAmount < 0.01 ? 8 : (convertedAmount < 1 ? 6 : 2)
                let result = {
                    value: "= " + formatNumberWithDecimals(convertedAmount, decimalPlaces) + " " + toCurrency,
                    hint: "Enter to copy (live rate)",
                    copyValue: convertedAmount.toFixed(decimalPlaces)
                }

                // Cache the result
                cache[cacheKey] = {
                    result: result,
                    timestamp: Date.now()
                }

                lastQuery = cacheKey
                lastResult = result

                // Notify that result is ready
                currencyEvaluator.resultReady()
            }
        } catch (e) {
            console.log("CurrencyEvaluator: Failed to parse response:", e)
        }
    }

    function parseCryptoResponse(data, amount, from, to) {
        let fromIsCrypto = cryptoCurrencies.hasOwnProperty(from)
        let toIsCrypto = cryptoCurrencies.hasOwnProperty(to)

        if (fromIsCrypto && !toIsCrypto) {
            // Crypto to fiat (e.g., 1 BTC to USD)
            let cryptoId = cryptoCurrencies[from]
            let fiatLower = to.toLowerCase()
            if (data[cryptoId] && data[cryptoId][fiatLower] !== undefined) {
                return amount * data[cryptoId][fiatLower]
            }
        } else if (!fromIsCrypto && toIsCrypto) {
            // Fiat to crypto (e.g., 100 USD to BTC)
            let cryptoId = cryptoCurrencies[to]
            let fiatLower = from.toLowerCase()
            if (data[cryptoId] && data[cryptoId][fiatLower] !== undefined) {
                let cryptoPrice = data[cryptoId][fiatLower]
                return amount / cryptoPrice
            }
        } else if (fromIsCrypto && toIsCrypto) {
            // Crypto to crypto (e.g., 1 BTC to ETH)
            let fromId = cryptoCurrencies[from]
            let toId = cryptoCurrencies[to]
            if (data[fromId] && data[fromId].usd && data[toId] && data[toId].usd) {
                let fromUsd = data[fromId].usd
                let toUsd = data[toId].usd
                return (amount * fromUsd) / toUsd
            }
        }
        return null
    }

    function formatNumberWithDecimals(num, decimals) {
        return num.toLocaleString(undefined, { minimumFractionDigits: decimals, maximumFractionDigits: decimals })
    }

    function formatNumber(num) {
        // Format with 2 decimal places and thousands separators
        return num.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    }
}
