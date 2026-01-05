import QtQuick
import "../../services"

Item {
    id: hintTarget

    // The element to place the hint badge on
    property Item targetElement: parent

    // Function to call when this hint is selected (left-click behavior)
    property var action: null

    // Function to call when Shift+hint is pressed (right-click behavior)
    property var secondaryAction: null

    // Which overlay scope this belongs to (e.g., "sidebar-right")
    property string scope: ""

    // Whether this target should be registered
    property bool enabled: true

    // Internal registration ID (-1 means not registered)
    property int _registrationId: -1

    // Make this item invisible and non-interactive
    visible: false
    width: 0
    height: 0

    Component.onCompleted: {
        if (enabled && action && targetElement) {
            _registrationId = HintNavigationService.register(
                targetElement, action, scope, secondaryAction
            )
        }
    }

    Component.onDestruction: {
        if (_registrationId >= 0) {
            HintNavigationService.unregister(_registrationId)
        }
    }

    onEnabledChanged: {
        if (enabled && action && targetElement && _registrationId < 0) {
            _registrationId = HintNavigationService.register(
                targetElement, action, scope, secondaryAction
            )
        } else if (!enabled && _registrationId >= 0) {
            HintNavigationService.unregister(_registrationId)
            _registrationId = -1
        }
    }

    onTargetElementChanged: {
        // Re-register if target element changes
        if (_registrationId >= 0) {
            HintNavigationService.unregister(_registrationId)
            _registrationId = -1
        }
        if (enabled && action && targetElement) {
            _registrationId = HintNavigationService.register(
                targetElement, action, scope, secondaryAction
            )
        }
    }
}
