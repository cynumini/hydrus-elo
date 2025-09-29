import sys
from PySide6.QtCore import QObject, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, QmlElement
from PySide6.QtQuickControls2 import QQuickStyle

# import rc_style # TODO: check it in the end

QML_IMPORT_NAME = "io.qt.textproperties"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class Bridge(QObject):
    @Slot(str, result=str)
    def getColor(self, s: str) -> str:
        match s.lower():
            case "red":
                return "#ef9a9a"
            case "green":
                return "#a5d6a7"
            case "blue":
                return "#90caf9"
            case _:
                return "white"

    @Slot(float, result=int)
    def getSize(self, s: float) -> int:
        return max(1, int(s * 34))

    @Slot(str, result=bool)
    def getItalic(self, s: str) -> bool:
        return s.lower() == "italic"

    @Slot(str, result=bool)
    def getBold(self, s: str) -> bool:
        return s.lower() == "bold"

    @Slot(str, result=bool)
    def getUnderline(self, s: str) -> bool:
        return s.lower() == "underline"


def main() -> int:
    engine: QQmlApplicationEngine | None = None
    try:
        app = QGuiApplication(sys.argv)
        QQuickStyle.setStyle("Material")
        engine = QQmlApplicationEngine()
        engine.addImportPath(sys.path[0])
        engine.loadFromModule("QmlIntegration", "Main")

        assert engine.rootObjects()

        return app.exec()
    finally:
        del engine


if __name__ == "__main__":
    sys.exit(main())
