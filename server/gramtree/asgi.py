"""uvicorn 入口：uvicorn gramtree.asgi:app"""

from gramtree.main import create_app

app = create_app()
