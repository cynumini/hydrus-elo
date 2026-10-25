import json
import logging
from pathlib import Path
from typing import cast


class League:
    def __init__(self,  path: Path, logger: logging.Logger) -> None:
        if path.exists():
            logger.info("Load hydrus-elo.json")
            self.data: dict[str, list[str]] = cast(
                dict[str, list[str]], json.loads(path.read_text())
            )
        else:
            logger.info("Create hydrus-elo.json")
            self.data = {"all": ["system:filetype is image"]}
            _ = path.write_text(json.dumps(self.data))

    def get(self, key: str) -> list[str]:
        tags = self.data.get(key)
        assert(tags)
        return tags
