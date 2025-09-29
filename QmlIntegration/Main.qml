import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

import io.qt.textproperties

ApplicationWindow {
    id: page
    width: 800
    height: 400
    visible: true // must be true to window to be seen
    Material.theme: Material.Dark
    Material.accent: Material.Red

    Bridge {
        id: bridge
    }

    Rectangle {
        id: main
        width: 200
        height: 200
        color: "green"

        Text {
            text: bridge.getColor("red")
            anchors.centerIn: main
        }
    }
}
