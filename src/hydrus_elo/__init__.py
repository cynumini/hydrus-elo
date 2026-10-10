import json
import os
import sys
from typing import reveal_type
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, cast, override

import hydrus_api
from PySide6.QtCore import Qt
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
    QVBoxLayout,
    QWidget,
)


def fit_size(
    width: int, height: int, max_width: int = 1920, max_height: int = 1080
) -> tuple[int, int]:
    if width <= max_width and height <= max_height:
        return width, height
    scale = min(max_width / width, max_height / height)
    return round(width * scale), round(height * scale)


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


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("hydrus-elo")
        self.resize(1280, 720)
        tags_action = self.menuBar().addAction("&tags")
        _ = tags_action.triggered.connect(self.tags)

        # Three columns
        self.splitter: QSplitter = QSplitter(Qt.Orientation.Horizontal)
        self.setCentralWidget(self.splitter)

        # Column 1: List
        self.tags_list: QListWidget = QListWidget()
        self.splitter.addWidget(self.tags_list)

        # Column 2: Image
        self.image: ImageView = ImageView()
        self.splitter.addWidget(self.image)

        # Column 3: Two buttons
        self.buttons_widget: QWidget = QWidget()
        buttons_layout = QVBoxLayout(self.buttons_widget)

        self.button1: QPushButton = QPushButton("Left wins")
        self.button2: QPushButton = QPushButton("Right wins")

        buttons_layout.addWidget(self.button1)
        buttons_layout.addWidget(self.button2)
        buttons_layout.addStretch()

        self.splitter.addWidget(self.buttons_widget)

        self.splitter.setSizes([200, 600, 200])

        # logic
        self.hydrus: hydrus_api.Client = hydrus_api.Client(
            os.getenv("HYDRUS_CLIENT_API")
        )

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
        tags = cast(
            list[str], metadata["tags"][all_known_tags_service_key]["display_tags"]["0"]
        )
        self.tags_list.clear()
        self.tags_list.addItems(tags)
        width, height = fit_size(
            cast(int, metadata["width"]), cast(int, metadata["height"])
        )
        
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
