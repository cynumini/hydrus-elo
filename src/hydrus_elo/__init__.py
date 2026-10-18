import json
import logging
import os
import sys
from enum import StrEnum
from pathlib import Path
from typing import cast, override

import hydrus_api
from PySide6.QtWidgets import (
    QApplication,
    QButtonGroup,
    QMainWindow,
    QRadioButton,
    QVBoxLayout,
    QWizard,
    QWizardPage,
)

logger = logging.getLogger(__name__)


class League:
    def __init__(self, path: Path) -> None:
        if path.exists():
            logger.info("Load hydrus-elo.json")
            self.data: dict[str, list[str]] = cast(
                dict[str, list[str]], json.loads(path.read_text())
            )
        else:
            logger.info("Create hydrus-elo.json")
            self.data = {"all": ["system:filetype is image"]}
            _ = path.write_text(json.dumps(self.data))

    def get(self, key: str) -> list[str] | None:
        return self.data.get(key)


class Command(StrEnum):
    RANKS = "Ranks"
    PROMOS = "Promos"
    SEASON = "Season"
    PLAYER = "Player"


class CommandPage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Choose a command")

        layout = QVBoxLayout(self)
        self.group: QButtonGroup = QButtonGroup(self)

        tool_tips: list[str] = [
            "Random matches in all ranks",
            "Promotion matches between ranks",
            "Play as one player",
            "Run ranks + promos",
        ]

        for i, mode in enumerate(Command):
            button: QRadioButton = QRadioButton(mode.value)
            button.setToolTip(tool_tips[i])
            self.group.addButton(button, i)
            layout.addWidget(button)

        self.group.buttons()[0].setChecked(True)

    @override
    def nextId(self):
        return -1

    @override
    def validatePage(self):
        button = self.group.checkedButton()
        if not button:
            return False
        _ = self.wizard().setProperty("command", button.text())
        return True


class Wizard(QWizard):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("hydrus-elo")

        self.setPage(0, CommandPage())


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()


def main() -> None:
    league: League = League(Path("hydrus-elo.json"))
    access_key = os.getenv("HYDRUS_CLIENT_API")
    hydrus = hydrus_api.Client(access_key)
    assert isinstance(access_key, str)

    app = QApplication([])
    wizard = Wizard()

    if wizard.exec() == QWizard.DialogCode.Accepted:
        command = Command(cast(str, wizard.property("command")))
        print(command, type(command))

    main_window = MainWindow()
    main_window.show()
    sys.exit(app.exec())
