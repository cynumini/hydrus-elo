import json
import logging
import os
import sys
from pathlib import Path
from typing import cast

import hydrus_api
from PySide6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWizard,
)

from hydrus_elo.elo import RanksStrategy
from hydrus_elo.hydrus import Hydrus
from hydrus_elo.league import League
from hydrus_elo.play import Play, Strategy
from hydrus_elo.wizard import Command, Wizard

logger = logging.getLogger("hydrus-elo")
logging.basicConfig(level=logging.INFO)


def main() -> None:
    league: League = League(Path("hydrus-elo.json"), logger)
    access_key = os.getenv("HYDRUS_CLIENT_API")
    assert isinstance(access_key, str)
    hydrus: Hydrus = Hydrus(access_key)

    app = QApplication([])
    wizard = Wizard(league)

    # print(league.data.keys())

    if wizard.exec() == QWizard.DialogCode.Accepted:
        command = Command(cast(str, wizard.property("command")))
        league_name = cast(str, wizard.field("league"))
        games_per_rank = cast(int, wizard.field("games_per_rank"))

        play: Play = Play(league, league_name, hydrus, logger)
        play.show()

        match command:
            case Command.RANKS:
                play.play(RanksStrategy(games_per_rank))
            case command.PROMOS:
                assert(False)
            case command.SEASON:
                assert(False)
            case command.PLAYER:
                assert(False)

        sys.exit(app.exec())
    else:
        sys.exit(0)
