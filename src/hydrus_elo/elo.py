import math
import random
from dataclasses import dataclass
from enum import Enum, IntEnum, auto
from typing import ClassVar, cast


@dataclass
class RanksStrategy:
    count: int


@dataclass
class PromosStrategy:
    pass


@dataclass
class PlayerStrategy:
    id: int
    count: int


Strategy = RanksStrategy | PromosStrategy | PlayerStrategy


class Rank(IntEnum):
    UNRANKED = 0
    WOOD = 1
    STONE = 2
    IRON = 3
    GOLD = 4
    DIAMOND = 5
    WINNER = 6

    MaxLeagueLen: ClassVar[int]


    def max(self):
        match self:
            case Rank.UNRANKED:
                return 0
            case Rank.WOOD:
                return 128
            case Rank.STONE:
                return 64
            case Rank.IRON:
                return 32
            case Rank.GOLD:
                return 16
            case Rank.DIAMOND:
                return 8
            case Rank.WINNER:
                return 1

Rank.MaxLeagueLen = sum(
    rank.max() for rank in Rank if rank != Rank.UNRANKED
)


@dataclass
class Player:
    id: int
    elo: int
    rank: Rank


@dataclass
class Data:
    elo: int
    rank: Rank


class Score(Enum):
    WIN = 1.0
    DRAW = 0.5
    LOSE = 0.0


class UserInput(Enum):
    WIN = auto()
    LOSE = auto()
    DRAW = auto()
    UNDO = auto()
    QUIT = auto()

    def get_score(self):
        match self:
            case UserInput.WIN:
                return Score.WIN
            case UserInput.DRAW:
                return Score.DRAW
            case UserInput.LOSE:
                return Score.LOSE
            case _:
                raise ValueError(f"{self.name} has no score")


def play(rating1: float, rating2: float, score: Score, k: float) -> tuple[float, float]:
    probability1 = 1.0 / (1.0 + 10 ** ((rating2 - rating1) / 400.0))
    probability2 = 1.0 - probability1
    score_value = score.value

    return (
        rating1 + k * (score_value - probability1),
        rating2 + k * ((1.0 - score_value) - probability2),
    )


def play_int(rating1: int, rating2: int, score: Score, k: float) -> tuple[int, int]:
    r = play(rating1, rating2, score, k)
    return round(r[0]), round(r[1])


@dataclass
class Match:
    player1: int
    player2: int
    score: Score | None = None
    p1_elo: int | None = None
    p2_elo: int | None = None


@dataclass
class Promotion:
    player: int
    from_rank: Rank
    to_rank: Rank


type Action = Rank | Match | Promotion


class Elo:
    def __init__(self, players: list[Player], strategy: Strategy):
        self.players: list[Player] = players
        self.actions: list[Action] = []
        self.current_data: list[Data] = [
            Data(player.elo, player.rank) for player in players
        ]
        self.result: dict[int, Data] = {}
        self.position: int = 0
        self.strategy: Strategy = strategy

    def get_id(self, index: int):
        return self.players[index].id

    def get_elo(self, index: int):
        return self.current_data[index].elo

    def get_rank(self, index: int) -> Rank:
        return self.current_data[index].rank

    def get_stronger(self, player_id: int, possible_players: list[int]) -> int | None:
        candidates = [
            opponent_id
            for opponent_id in possible_players
            if self.players[opponent_id].elo > self.players[player_id].elo
            and self.players[opponent_id].id != self.players[player_id].id
        ]
        candidates.sort(key=lambda x: self.players[x].elo)
        candidates = candidates[:5]
        random.shuffle(candidates)
        return candidates[0] if candidates else None

    def get_weaker(self, player_id: int, possible_players: list[int]) -> int | None:
        candidates = [
            opponent_id
            for opponent_id in possible_players
            if self.players[opponent_id].elo <= self.players[player_id].elo
            and self.players[opponent_id].id != self.players[player_id].id
        ]
        candidates.sort(key=lambda x: self.players[x].elo, reverse=True)
        candidates = candidates[:5]
        random.shuffle(candidates)
        return candidates[0] if candidates else None

    def generate_rank(self, games_per_rank: int):
        for rank in Rank:
            if rank == Rank.WINNER:
                break

            possible_players = [
                id for id, player in enumerate(self.players) if player.rank == rank
            ]

            random.shuffle(possible_players)

            games_count = min(games_per_rank, len(possible_players))

            if games_count > 0 and len(possible_players) > 2:
                self.actions.append(rank)

                for i in range(games_count):
                    player = possible_players[i]

                    stronger = self.get_stronger(player, possible_players)
                    weaker = self.get_weaker(player, possible_players)
                    assert stronger or weaker
                    if stronger and weaker:
                        opponent = random.choice([stronger, weaker])
                    if stronger and not weaker:
                        opponent = stronger
                    else:
                        opponent = weaker
                    assert opponent
                    self.actions.append(Match(player1=player, player2=opponent))

    def generate(self):
        match self.strategy:
            case RanksStrategy():
                self.generate_rank(self.strategy.count)
            case PromosStrategy():
                assert False
            case PlayerStrategy():
                assert False

    def next(self) -> Action | None:
        if self.position == len(self.actions):
            return None

        action = self.actions[self.position]

        if isinstance(action, (Rank, Promotion)):
            self.position += 1

        return action

    def set_elo(self, index: int, value: int):
        id = self.get_id(index)
        self.current_data[index].elo = value
        self.result[id] = self.current_data[index]

    def set_rank(self, index: int, value: Rank):
        id = self.get_id(index)
        self.current_data[index].rank = value
        self.result[id] = self.current_data[index]

    def get_action(self):
        return self.actions[self.position]

    def act(self, user_input: UserInput, action: Action) -> tuple[int, int] | None:
        match user_input:
            case UserInput.WIN | UserInput.LOSE | UserInput.DRAW:
                assert isinstance(action, Match)
                action.p1_elo = self.get_elo(action.player1)
                action.p2_elo = self.get_elo(action.player2)
                action.score = user_input.get_score()
                r = play_int(action.p1_elo, action.p2_elo, action.score, 32)
                self.set_elo(action.player1, r[0])
                self.set_elo(action.player2, r[1])
                if action.score == Score.LOSE and isinstance(
                    self.strategy, PromosStrategy
                ):
                    rank1 = self.get_rank(action.player1)
                    rank2 = self.get_rank(action.player1)
                    self.set_rank(action.player1, rank2)
                    self.set_rank(action.player2, rank1)
                self.position += 1
                return r
            case UserInput.QUIT:
                self.position = len(self.actions)
            case UserInput.UNDO:
                while True:
                    if self.position > 0:
                        self.position -= 1
                        a: Action = self.get_action()
                        if not a:
                            break
                        if isinstance(a, Match):
                            self.set_elo(a.player1, cast(int, a.p1_elo))
                            self.set_elo(a.player2, cast(int, a.p2_elo))
                        else:
                            continue
                        break
                    break
        return None

    def get_chosen_ids(self, include_promos: bool) -> list[int]:
        result: list[int] = []
        for action in self.actions:
            match action:
                case Rank():
                    pass
                case Match():
                    for player in (action.player1, action.player2):
                        id = self.get_id(player)
                        if id not in result:
                            result.append(id)
                case Promotion():
                    if include_promos:
                        id = self.get_id(action.player)
                        if id not in result:
                            result.append(id)

        return result

    def print_queue(self):
        for action in self.actions:
            match action:
                case Rank():
                    print(action.name)
                case Match():
                    print(
                        f"{self.players[action.player1]} vs {self.players[action.player2]}"
                    )
                case Promotion():
                    assert False
