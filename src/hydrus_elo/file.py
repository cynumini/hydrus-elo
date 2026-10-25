from dataclasses import dataclass

from hydrus_elo.elo import Rank


@dataclass
class File:
    id: int
    elo: int
    rank: Rank
    size: tuple[int, int]
    # image: ?rl.Image = null
    # texture: ?rl.Texture = null
