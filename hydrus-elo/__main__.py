import sys
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView


def main() -> int:
    app = QGuiApplication()
    view = QQuickView()
    view.engine().addImportPath(sys.path[0])
    view.loadFromModule("App", "Main")
    view.show()
    ex = app.exec()
    del view
    return ex


if __name__ == "__main__":
    sys.exit(main())
