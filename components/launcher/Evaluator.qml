import QtQuick
import "evaluators"

QtObject {
    id: evaluator

    // Individual evaluators
    property MathEvaluator mathEval: MathEvaluator {}
    property PercentageEvaluator percentageEval: PercentageEvaluator {}
    property UnitEvaluator unitEval: UnitEvaluator {}
    property BaseEvaluator baseEval: BaseEvaluator {}
    property TimeEvaluator timeEval: TimeEvaluator {}
    property ColorEvaluator colorEval: ColorEvaluator {}

    // List of evaluators in priority order
    property var evaluators: [
        colorEval,       // Color conversion (check early for hex patterns)
        percentageEval,  // Check percentage first (more specific patterns)
        timeEval,        // Time calculations
        unitEval,        // Unit conversions
        baseEval,        // Base conversions
        mathEval         // Math last (most general)
    ]

    // Current evaluation result
    property var currentResult: null

    // Evaluate input and return result
    function evaluate(input) {
        if (!input || input.trim().length === 0) {
            currentResult = null
            return null
        }

        // Try each evaluator in order
        for (let i = 0; i < evaluators.length; i++) {
            let ev = evaluators[i]
            try {
                let result = ev.evaluate(input)
                if (result) {
                    currentResult = result
                    return result
                }
            } catch (e) {
                // Skip failed evaluator
                console.log("Evaluator error:", ev.name, e)
            }
        }

        currentResult = null
        return null
    }

    // Get the copyable value from current result
    function getCopyValue() {
        if (currentResult && currentResult.copyValue) {
            return currentResult.copyValue
        }
        return null
    }
}
