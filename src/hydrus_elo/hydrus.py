from typing import Any, cast

import hydrus_api

from hydrus_elo.elo import Rank
from hydrus_elo.file import File


class Hydrus:
    def __init__(self, access_key: str):
        self.client: hydrus_api.Client = hydrus_api.Client(access_key)
        self.elo_service_key: str | None = None
        self.league_service_keys: dict[str, str] = {}

    def search_files(self, tags: list[str]) -> list[int]:
        response = self.client.search_files(
            tags, file_sort_type=hydrus_api.FileSortType.RANDOM
        )
        return cast(list[int], response["file_ids"])

    def load_service_key(self):
        services = cast(
            dict[str, dict[str, str]], self.client.get_services()["services"]
        )

        for key, value in services.items():
            name = value["name"]
            if name == "elo":
                self.elo_service_key = key
            elif name.startswith("league."):
                self.league_service_keys[name[7:]] = key

        assert self.get_elo_service_key

    def get_elo_service_key(self):
        if not self.elo_service_key:
            self.load_service_key()
        return self.elo_service_key

    def get_files(self, ids: list[int], league_name: str) -> list[File]:
        elo_service_key = self.get_elo_service_key()
        league_service_key = self.league_service_keys[league_name]

        response = cast(
            list[dict[str, Any]],
            self.client.get_file_metadata(file_ids=ids)["metadata"],
        )

        files: list[File] = []

        for metadata in response:
            rank = cast(int | None, metadata["ratings"][league_service_key])
            rank = file = File(
                cast(int, metadata["file_id"]),
                cast(int, metadata["ratings"][elo_service_key]),
                Rank(rank) if rank else Rank.UNRANKED,
                (cast(int, metadata["width"]), cast(int, metadata["height"])),
            )

            if file.elo == 0:
                file.elo = 1000

            files.append(file)

        return files
