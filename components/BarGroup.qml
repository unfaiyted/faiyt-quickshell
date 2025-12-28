import QtQuick
import "../theme"

Rectangle {
    id: barGroup

    color: Colors.backgroundElevated
    radius: 12

    // Default property allows children to be added directly
    default property alias content: container.data

    Item {
        id: container
        anchors.fill: parent
    }
}
