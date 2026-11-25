from __future__ import annotations

import uvicorn

from .config import BotConfig
from .server import create_app


def main() -> None:
    cfg = BotConfig.from_env()
    app = create_app(cfg)
    uvicorn.run(app, host=cfg.host, port=cfg.port)


if __name__ == "__main__":
    main()
