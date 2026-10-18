import json
import os
import pprint
import sys
from dataclasses import dataclass, field
from pathlib import Path
import tempfile
from typing import Any, cast, override, reveal_type

import hydrus_api
from PySide6.QtCore import QUrl, Qt
from PySide6.QtGui import QDesktopServices, QPixmap, QResizeEvent
from PySide6.QtWidgets import (
    QApplication,
    QComboBox,
    QDialog,
    QDialogButtonBox,
    QFormLayout,
    QHBoxLayout,
    QLabel,
    QListWidget,
    QMainWindow,
    QPushButton,
    QSizePolicy,
    QSpinBox,
    QSplitter,
    QStackedWidget,
    QVBoxLayout,
    QWidget,
)


def fit_size(
    size: tuple[int, int], max_size: tuple[int, int] = (1920, 1080)
) -> tuple[int, int]:
    if size[0] <= max_size[0] and size[1] <= max_size[1]:
        return size
    scale = min(max_size[0] / size[0], max_size[1] / size[1])
    return round(size[0] * scale), round(size[1] * scale)


class ImageView(QLabel):
    def __init__(self):
        super().__init__()
        self.data: QPixmap = QPixmap()

        self.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.setMinimumSize(100, 100)
        self.setSizePolicy(
            QSizePolicy.Policy.Ignored,
            QSizePolicy.Policy.Ignored,
        )

    def set_image(self, pixmap: QPixmap):
        self.data = pixmap
        self._update_image()

    @override
    def resizeEvent(self, event: QResizeEvent):
        super().resizeEvent(event)
        self._update_image()

    def _update_image(self):
        if self.data.isNull():
            self.clear()
            return

        self.setPixmap(
            self.data.scaled(
                self.contentsRect().size(),
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation,
            )
        )


class IQDB(QWidget):
    def __init__(self, hydrus: hydrus_api.Client):
        super().__init__()
        self.hydrus: hydrus_api.Client = hydrus

        with tempfile.NamedTemporaryFile(
            suffix=".png",
            delete=False,
        ) as tmp:
            self.lookup_image_path: Path = Path(tmp.name)
        self.image_path: str | None = None

        self.img_size: tuple[int, int] = (0, 0)
        layout: QVBoxLayout = QVBoxLayout(self)
        self.list_widget: QListWidget = QListWidget()
        self.open_iqdb: QPushButton = QPushButton("open iqdb.org")
        self.copy_image_path: QPushButton = QPushButton("copy image path")
        self.copy_lookup_image_path: QPushButton = QPushButton("copy lookup image path")
        _ = self.open_iqdb.pressed.connect(
            lambda: QDesktopServices.openUrl(QUrl("https://iqdb.org/"))
        )
        _ = self.copy_image_path.pressed.connect(
            lambda: QApplication.clipboard().setText(str(self.image_path))
        )
        _ = self.copy_lookup_image_path.pressed.connect(
            lambda: QApplication.clipboard().setText(str(self.lookup_image_path))
        )
        layout.addWidget(self.list_widget)
        layout.addWidget(self.open_iqdb)
        layout.addWidget(self.copy_image_path)
        layout.addWidget(self.copy_lookup_image_path)

        _ = self.destroyed.connect(self.cleanup)

    def setup(self, metadata: dict[str, Any]):
        self.list_widget.clear()

        self.list_widget.addItems(cast(list[str], metadata["known_urls"]))
        self.img_size = (cast(int, metadata["width"]), cast(int, metadata["height"]))

        self.copy_image_path.setText(
            f"copy image path ({self.img_size[0]}x{self.img_size[1]})"
        )
        size = fit_size(self.img_size, (1024, 1024))
        self.copy_lookup_image_path.setText(
            f"copy lookup image path ({size[0]}x{size[1]})"
        )

        file_id = cast(int, metadata["file_id"])

        self.image_path = cast(str, self.hydrus.get_file_path(file_id)["path"])

        result = self.hydrus.get_render(
            file_id=file_id,
            width=size[0],
            height=size[1],
        ).content

        _ = self.lookup_image_path.write_bytes(result)

    def cleanup(self) -> None:
        self.lookup_image_path.unlink(missing_ok=True)


class TaggingWizard(QWidget):
    def __init__(self, hydrus: hydrus_api.Client):
        super().__init__()
        layout = QVBoxLayout(self)
        navigation = QHBoxLayout()

        self.iqdb: IQDB = IQDB(hydrus)

        self.name: QLabel = QLabel("iqdb")
        self.stack: QStackedWidget = QStackedWidget()

        _ = self.stack.addWidget(self.iqdb)

        layout.addWidget(self.name)
        layout.addWidget(self.stack)
        layout.addLayout(navigation)

        self.prev_button: QPushButton = QPushButton("prev")
        self.next_button: QPushButton = QPushButton("next")
        navigation.addWidget(self.prev_button)
        navigation.addWidget(self.next_button)
        # self.buttons_widget: QWidget = QWidget()
        #
        # self.button1: QPushButton = QPushButton("Left wins")
        # self.button2: QPushButton = QPushButton("Right wins")
        #
        # buttons_layout.addWidget(self.button1)
        # buttons_layout.addWidget(self.button2)
        # buttons_layout.addStretch()


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("hydrus-elo")
        self.resize(1280, 720)
        tags_action = self.menuBar().addAction("&tags")
        _ = tags_action.triggered.connect(self.tags)

        self.hydrus: hydrus_api.Client = hydrus_api.Client(
            os.getenv("HYDRUS_CLIENT_API")
        )

        # Three columns
        self.splitter: QSplitter = QSplitter(Qt.Orientation.Horizontal)
        self.setCentralWidget(self.splitter)

        # Column 1: List
        self.tags_list: QListWidget = QListWidget()
        self.splitter.addWidget(self.tags_list)

        # Column 2: Image
        self.image: ImageView = ImageView()
        self.splitter.addWidget(self.image)

        # Column 3
        self.tagging_wizard: TaggingWizard = TaggingWizard(self.hydrus)
        self.splitter.addWidget(self.tagging_wizard)

        self.splitter.setSizes([200, 600, 200])

    def tags(self):
        elo: int = 1100
        tag_count: int = 3
        files = cast(
            list[int],
            self.hydrus.search_files(
                [
                    f"system:count for elo more than {elo}",
                    f"system:number of tags < {tag_count}",
                ],
            )["file_ids"],
        )
        assert len(files) > 0
        file_metadata = self.hydrus.get_file_metadata(file_ids=[files[0]])
        all_known_tags_service_key: str | None = None
        services_v2 = cast(list[dict[str, str]], file_metadata["services_v2"])
        for item in services_v2:
            if item["name"] == "all known tags":
                all_known_tags_service_key = item["service_key"]
        assert isinstance(all_known_tags_service_key, str)
        metadata: dict[str, Any] = cast(dict[str, Any], file_metadata["metadata"][0])
        size = cast(int, metadata["width"]), cast(int, metadata["height"])
        self.tagging_wizard.iqdb.setup(metadata)
        tags = cast(
            list[str], metadata["tags"][all_known_tags_service_key]["display_tags"]["0"]
        )
        self.tags_list.clear()
        self.tags_list.addItems(tags)
        width, height = fit_size(size)

        result = self.hydrus.get_render(
            file_id=files[0],
            width=width,
            height=height,
        ).content
        image = QPixmap()
        if image.loadFromData(result):
            self.image.set_image(image)


def main() -> None:
    app = QApplication([])
    main_window = MainWindow()
    main_window.show()
    sys.exit(app.exec())
