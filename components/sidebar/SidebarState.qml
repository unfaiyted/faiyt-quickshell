pragma Singleton
import QtQuick

QtObject {
    id: sidebarState

    property bool leftOpen: false
    property bool rightOpen: false

    function toggleLeft() {
        rightOpen = false  // Close other sidebar
        leftOpen = !leftOpen
    }

    function toggleRight() {
        leftOpen = false  // Close other sidebar
        rightOpen = !rightOpen
    }

    function closeAll() {
        leftOpen = false
        rightOpen = false
    }
}
