from enum import Enum, IntEnum, auto


class Strategy(Enum):
    RANKS = auto()
    PROMOS = auto()
    PLAYER = auto()


class Rank(IntEnum):
    UNRANKED = 0
    WOOD = 1
    STONE = 2
    IRON = 3
    GOLD = 4
    DIAMOND = 5
    WINNER = 6
