import logging
from typing import override

from PySide6.QtCore import QThread
from PySide6.QtGui import QAction, QCloseEvent
from PySide6.QtWidgets import QApplication, QMainWindow

from hydrus_elo.elo import (
    Action,
    Elo,
    Match,
    Player,
    PlayerStrategy,
    PromosStrategy,
    Promotion,
    Rank,
    RanksStrategy,
    Strategy,
    UserInput,
)
from hydrus_elo.file import File
from hydrus_elo.hydrus import Hydrus
from hydrus_elo.league import League


class ImageThread(QThread):
    def __init__(
        self,
        files: list[File],
        max_size: tuple[int, int],
        hydrus: Hydrus,
        logger: logging.Logger,
    ):
        super().__init__()
        self.files: list[File] = files
        self.max_size: tuple[int, int] = max_size
        self.running: bool = True
        self.logger: logging.Logger = logger
        self.hydrus: Hydrus = hydrus

    def stop(self):
        self.running = False

    @override
    def run(self):
        for file in self.files:
            if self.running == False:
                break
            # self.logger.info(f"Start load {file}")
            file.load_image(self.max_size, self.hydrus)
            # self.logger.info(f"End load {file}")


class Play(QMainWindow):
    def __init__(
        self, league: League, league_name: str, hydrus: Hydrus, logger: logging.Logger
    ):
        super().__init__()
        self.league: League = league
        self.league_name: str = league_name
        self.hydrus: Hydrus = hydrus
        self.logger: logging.Logger = logger
        self.running: bool = True
        self.image_thread: ImageThread | None = None
        self.elo: Elo | None = None
        self.action: Action | None = None

        win_action = QAction("&win", self)
        lose_action = QAction("&lose", self)
        draw_action = QAction("&draw", self)
        undo_action = QAction("&undo", self)
        quit_action = QAction("&quit", self)
        _ = win_action.triggered.connect(lambda: self.act(UserInput.WIN))
        _ = lose_action.triggered.connect(lambda: self.act(UserInput.LOSE))
        _ = draw_action.triggered.connect(lambda: self.act(UserInput.DRAW))
        _ = undo_action.triggered.connect(lambda: self.act(UserInput.UNDO))
        _ = quit_action.triggered.connect(lambda: self.act(UserInput.QUIT))

        self.menuBar().addAction(win_action)
        self.menuBar().addAction(lose_action)
        self.menuBar().addAction(draw_action)
        self.menuBar().addAction(undo_action)
        self.menuBar().addAction(quit_action)

    def act(self, user_input: UserInput) -> None:
        assert self.elo
        assert self.action
        result = self.elo.act(user_input, self.action)
        print(result)

    def get_resource(self, files: list[File], id: int) -> File | None:
        for item in files:
            if item.id == id:
                return item
        return None

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
            case RanksStrategy():
                tags.append("system:limit is 1024")
                ids.extend(self.hydrus.search_files(tags))
            case PromosStrategy():
                assert False
            case PlayerStrategy():
                assert False

        self.logger.info("Unranked files = %d", len(ids) - ranked_ids_len)

        return self.hydrus.get_files(ids, self.league_name)

    def play(self, strategy: Strategy):
        files = self.get_files(strategy)

        players = [Player(file.id, file.elo, file.rank) for file in files]

        self.elo = Elo(players, strategy)

        self.elo.generate()

        self.elo.print_queue()

        resources: list[File] = []

        chosen_ids = self.elo.get_chosen_ids(False)

        for id in chosen_ids:
            resource = self.get_resource(files, id)
            assert resource
            resources.append(resource)

        size = QApplication.primaryScreen().size()
        max_width = size.width()
        max_height = size.height()

        self.image_thread = ImageThread(
            resources, (max_width, max_height), self.hydrus, self.logger
        )
        self.image_thread.start()

        self.action = self.elo.next()
        print(self.action)

        p1: File | None = None
        p2: File | None = None

        need_print = True

        print("a")
        while self.running and self.action != None:
            print("b")
            match self.action:
                case Match():
                    print("c")
                    p1 = self.get_resource(resources, self.action.player1)
                    assert p1
                    p1.elo = self.elo.get_elo(self.action.player1)
                    p2 = self.get_resource(resources, self.action.player2)
                    assert p2
                    p2.elo = self.elo.get_elo(self.action.player2)
                    if need_print:
                        self.logger.info(
                            "%d (%d) vs %d (%d)",
                            self.elo.get_id(self.action.player1),
                            self.elo.get_elo(self.action.player1),
                            self.elo.get_id(self.action.player2),
                            self.elo.get_elo(self.action.player2),
                        )
                        need_print = False
                case Rank():
                    print("d")
                    self.logger.info(self.action.name)
                    self.action = self.elo.next()
                    print(self.action)
                case Promotion():
                    assert False
            break
        print("e")

    @override
    def closeEvent(self, event: QCloseEvent):
        if self.image_thread:
            self.image_thread.stop()
            _ = self.image_thread.wait()
        event.accept()
