import logging
from enum import Enum, auto

import hydrus_api
from PySide6.QtWidgets import QMainWindow

from hydrus_elo.elo import Strategy
from hydrus_elo.hydrus import Hydrus
from hydrus_elo.league import League
from hydrus_elo.wizard import Command


class Play(QMainWindow):
    def __init__(
        self, league: League, league_name: str, hydrus: Hydrus, logger: logging.Logger
    ):
        super().__init__()
        self.league: League = league
        self.league_name: str = league_name
        self.hydrus: Hydrus = hydrus
        self.logger: logging.Logger = logger

    def get_files(self, strategy: Strategy):
        ids: list[int] = []

        ranked_ids_len: int = 0

        # ranked - start
        tag = f"system:has rating for league.{self.league_name}"
        ranked_ids = self.hydrus.search_files([tag])
        ranked_ids_len = len(ranked_ids)
        ids.extend(ranked_ids)
        self.logger.info("Ranked files = %d", ranked_ids_len)
        # ranked - end

        tags = self.league.get(self.league_name)
        no_rating_tag = f"system:no rating for league.{self.league_name}"
        tags.append(no_rating_tag)

        match strategy:
            case Strategy.RANKS:
                tags.append("system:limit is 1024")
                ids.extend(self.hydrus.search_files(tags))
            case Strategy.PROMOS:
                assert False
            case Strategy.PLAYER:
                assert False

        self.logger.info("Unranked files = %d", len(ids) - ranked_ids_len)

        return self.hydrus.get_files(ids, self.league_name)

    def play(self, strategy: Strategy, games_per_rank: int):
        files = self.get_files(strategy)
        print(files, games_per_rank)
        # TODO: here
