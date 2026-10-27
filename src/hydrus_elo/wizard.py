from enum import Enum, IntEnum, StrEnum, auto
from typing import override

from PySide6.QtWidgets import (
    QButtonGroup,
    QComboBox,
    QLabel,
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


class Page(IntEnum):
    COMMAND = auto()
    RANKS_AND_SEASON = auto()
    PLAYER = auto()
    FINISH = auto()


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
        button = self.group.checkedButton()
        assert button

        match Command(button.text()):
            case Command.RANKS:
                return Page.RANKS_AND_SEASON.value
            case Command.SEASON:
                return Page.RANKS_AND_SEASON.value
            case Command.PROMOS:
                return Page.FINISH.value
            case Command.PLAYER:
                return Page.PLAYER.value

    @override
    def validatePage(self) -> bool:
        button = self.group.checkedButton()
        if not button:
            return False
        _ = self.wizard().setProperty("command", button.text())
        return True


class RankAndSeasonPage(QWizardPage):
    def __init__(self, league: League):
        super().__init__()

        layout = QVBoxLayout(self)

        self.league: QComboBox = QComboBox()
        self.league.addItems(list(league.data.keys()))

        self.games_per_rank: QSpinBox = QSpinBox(minimum=1, value=5)

        layout.addWidget(self.league)
        layout.addWidget(self.games_per_rank)

        self.registerField("league", self.league, "currentText")
        self.registerField("games_per_rank", self.games_per_rank)

    @override
    def initializePage(self):
        match Command(self.wizard().property("command")):
            case Command.RANKS:
                self.setTitle("Ranks")
            case Command.SEASON:
                self.setTitle("Season")
            case _:
                pass

    @override
    def nextId(self) -> int:
        return Page.FINISH.value


class PlayerPage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Player")

        layout = QVBoxLayout(self)

        self.id: QSpinBox = QSpinBox(maximum=1_000_000_000)
        self.count: QSpinBox = QSpinBox(minimum=1, value=5)

        layout.addWidget(self.id)
        layout.addWidget(self.count)

        self.registerField("id", self.id)
        self.registerField("count", self.count)

    @override
    def nextId(self) -> int:
        return Page.FINISH.value


class FinishPage(QWizardPage):
    def __init__(self):
        super().__init__()
        self.setTitle("Done")
        layout = QVBoxLayout(self)
        layout.addWidget(QLabel("You're all set!"))


class Wizard(QWizard):
    def __init__(self, league: League):
        super().__init__()
        self.setWindowTitle("hydrus-elo")

        self.setPage(Page.COMMAND.value, CommandPage())
        self.setPage(Page.RANKS_AND_SEASON.value, RankAndSeasonPage(league))
        self.setPage(Page.FINISH.value, FinishPage())
        self.setPage(Page.PLAYER.value, PlayerPage())
