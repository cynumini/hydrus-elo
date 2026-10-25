from dataclasses import dataclass
from typing import TYPE_CHECKING

from hydrus_api import RenderFormat
from PySide6.QtGui import QPixmap

from hydrus_elo.elo import Rank

if TYPE_CHECKING:
    from hydrus_elo.hydrus import Hydrus


@dataclass
class File:
    id: int
    elo: int
    rank: Rank
    size: tuple[int, int]
    image: QPixmap | None = None

    def scale_to(self, size: tuple[float, float], max_size: tuple[float, float]) -> tuple[int, int]:
        aspect = size[0] / size[1]

        if max_size[0] / max_size[1] > aspect:
            return int(max_size[1] * aspect), int(max_size[1])
        else:
            return int(max_size[0]), int(max_size[0] / aspect)

    def load_image(self, max_size: tuple[int, int], hydrus: Hydrus):
        if self.size[0] > max_size[0] or self.size[1] > max_size[1]:
            self.size = self.scale_to(self.size, max_size);
        self.image = QPixmap()
        _ = self.image.loadFromData(hydrus.render(self.id, RenderFormat.JPEG, self.size), format="JPEG")
