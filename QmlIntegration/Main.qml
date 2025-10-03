import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

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

    GridLayout {
        id: grid
        columns: 2
        rows: 3

        ColumnLayout {
            spacing: 2
            Layout.columnSpan: 1
            Layout.preferredWidth: 400
        }
    }

    // Rectangle {
    //     id: main
    //     width: 200
    //     height: 200
    //     color: "green"
    //
    //     Text {
    //         text: bridge.getColor("red")
    //         anchors.centerIn: main
    //     }
    // }
}
