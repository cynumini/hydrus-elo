from enum import Enum, StrEnum, auto
from typing import override

from PySide6.QtWidgets import (
    QButtonGroup,
    QComboBox,
    QRadioButton,
    QSpinBox,
    QVBoxLayout,
    QWizard,
    QWizardPage,
)

from hydrus_elo.league import League


class Command(StrEnum):
    RANKS = "Ranks"
    PROMOS = "Promos"
    SEASON = "Season"
    PLAYER = "Player"


class Page(Enum):
    COMMAND = auto()
    RANK = auto()


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
    def nextId(self) -> int:
        return Page.RANK.value

    @override
    def validatePage(self):
        button = self.group.checkedButton()
        if not button:
            return False
        _ = self.wizard().setProperty("command", button.text())
        return True


class RankPage(QWizardPage):
    def __init__(self, league: League):
        super().__init__()
        self.setTitle("Rank")

        layout = QVBoxLayout(self)

        self.league: QComboBox = QComboBox()
        self.league.addItems(list(league.data.keys()))

        self.games_per_rank: QSpinBox = QSpinBox(minimum=1, value=5)

        layout.addWidget(self.league)
        layout.addWidget(self.games_per_rank)

        self.registerField("league", self.league, "currentText")
        self.registerField("games_per_rank", self.games_per_rank)

    @override
    def nextId(self) -> int:
        return -1


class Wizard(QWizard):
    def __init__(self, league: League):
        super().__init__()
        self.setWindowTitle("hydrus-elo")

        self.setPage(Page.COMMAND.value, CommandPage())
        self.setPage(Page.RANK.value, RankPage(league))
