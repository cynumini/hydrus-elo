import logging
from typing import override

from PySide6.QtCore import QThread, Signal
from PySide6.QtGui import QAction, QCloseEvent, QImage, QPixmap, QResizeEvent, Qt
from PySide6.QtWidgets import (
    QApplication,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QSizePolicy,
    QSplitter,
    QVBoxLayout,
    QWidget,
)

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
    image_loaded: Signal = Signal()

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
            file.load_image(self.max_size, self.hydrus)
            self.image_loaded.emit()


class ImageLabel(QLabel):
    def __init__(self):
        super().__init__()
        self.original_pixmap: QPixmap | QImage = QPixmap()
        self.setAlignment(Qt.AlignmentFlag.AlignCenter)

    @override
    def setPixmap(self, pixmap: QPixmap | QImage):
        self.original_pixmap = pixmap
        self.update_image()

    @override
    def resizeEvent(self, event: QResizeEvent):
        super().resizeEvent(event)
        self.update_image()

    def update_image(self):
        if self.original_pixmap.isNull():
            return

        super().setPixmap(
            self.original_pixmap.scaled(
                self.size(),
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation,
            )
        )


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
        self.need_print: bool = True
        self.resources: list[File] = []
        self.p1: File | None = None
        self.p2: File | None = None

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

        central = QWidget(self)
        self.splitter: QSplitter = QSplitter(Qt.Orientation.Horizontal, central)

        self.left_label: ImageLabel = ImageLabel()
        self.right_label: ImageLabel = ImageLabel()

        self.left_label.setMinimumSize(1, 1)
        self.right_label.setMinimumSize(1, 1)

        self.left_label.setSizePolicy(
            QSizePolicy.Policy.Ignored,
            QSizePolicy.Policy.Ignored,
        )
        self.right_label.setSizePolicy(
            QSizePolicy.Policy.Ignored,
            QSizePolicy.Policy.Ignored,
        )

        self.splitter.addWidget(self.left_label)
        self.splitter.addWidget(self.right_label)

        self.setCentralWidget(self.splitter)

    def update_image(self):
        if self.p1 and self.p1.image:
            self.left_label.setPixmap(self.p1.image)
        if self.p2 and self.p2.image:
            self.right_label.setPixmap(self.p2.image)
        if self.p1 and self.p1.image and self.p2 and self.p2.image:
            total = (
                self.p1.size[0] / self.p1.size[1] + self.p2.size[0] / self.p2.size[1]
            )
            width = self.splitter.width()
            self.splitter.setSizes(
                [
                    round(width * (self.p1.size[0] / self.p1.size[1]) / total),
                    round(width * (self.p2.size[0] / self.p2.size[1]) / total),
                ]
            )

    def act(self, user_input: UserInput) -> None:
        assert self.elo
        assert self.action
        result = self.elo.act(user_input, self.action)
        if result:
            self.logger.info(f"{result[0]} - {result[1]}")
        self.advance()

    def advance(self):
        assert self.elo
        if isinstance(self.action, Match):
            self.need_print = True

        self.action = self.elo.next()

        while self.action != None:
            match self.action:
                case Match():
                    self.p1 = self.get_resource(
                        self.resources, self.elo.get_id(self.action.player1)
                    )
                    assert self.p1
                    self.p1.elo = self.elo.get_elo(self.action.player1)
                    self.p2 = self.get_resource(
                        self.resources, self.elo.get_id(self.action.player2)
                    )
                    assert self.p2
                    self.p2.elo = self.elo.get_elo(self.action.player2)
                    if self.need_print:
                        self.logger.info(
                            "%d (%d) vs %d (%d)",
                            self.elo.get_id(self.action.player1),
                            self.elo.get_elo(self.action.player1),
                            self.elo.get_id(self.action.player2),
                            self.elo.get_elo(self.action.player2),
                        )
                        self.need_print = False
                    break
                case Rank():
                    self.logger.info(self.action.name)
                    self.action = self.elo.next()
                case Promotion():
                    assert False
        else:
            print(self.elo.result)
            _ = self.close()
            for id, data in self.elo.result.items():
                self.hydrus.set_elo(id, data.elo)
                self.hydrus.set_league(id, self.league_name, data.rank)
            return
        self.update_image()

    def get_resource(self, files: list[File], id: int) -> File | None:
        for item in files:
            if item.id == id:
                return item
        return None

    def find_best_elo(self, max_ids: int, tags: list[str]) -> int:
        best_elo = 0
        elo = 0

        ids = self.hydrus.search_files(tags)
        self.logger.info("With no elo, count = %d", len(ids))

        print(max_ids)

        while len(ids) >= max_ids:
            best_elo = elo
            if len(ids) == max_ids:
                return best_elo
            elo += 100
            tmp_tags = tags.copy()
            elo_tag = f"system:count for elo more than {elo}"
            tmp_tags.append(elo_tag)
            ids = self.hydrus.search_files(tmp_tags)
            self.logger.info("With elo = %d, count = %d", elo, len(ids))

        return best_elo

    def get_files(self, strategy: Strategy):
        ids: list[int] = []

        ranked_ids_len: int = 0

        # ranked - start
        tag = f"system:has rating for league.{self.league_name}"
        ranked_ids = self.hydrus.search_files([tag])
        ranked_ids_len = len(ranked_ids)
        print(ranked_ids_len)
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
                print(Rank.MaxLeagueLen)
                elo = self.find_best_elo(Rank.MaxLeagueLen - ranked_ids_len + 1, tags)
                elo_tag = f"system:count for elo more than {elo}"
                tags.append(elo_tag)
                unranked_ids = self.hydrus.search_files(tags)
                ids.extend(unranked_ids)
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

        chosen_ids = self.elo.get_chosen_ids(False)

        for id in chosen_ids:
            resource = self.get_resource(files, id)
            assert resource
            self.resources.append(resource)

        size = QApplication.primaryScreen().size()
        max_width = size.width()
        max_height = size.height()

        self.image_thread = ImageThread(
            self.resources, (max_width, max_height), self.hydrus, self.logger
        )
        _ = self.image_thread.image_loaded.connect(self.update_image)
        self.image_thread.start()

        self.advance()

    @override
    def closeEvent(self, event: QCloseEvent):
        if self.image_thread:
            self.image_thread.stop()
            _ = self.image_thread.wait()
        event.accept()
