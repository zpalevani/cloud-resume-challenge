import os
import importlib.util
from pathlib import Path

APP_PATH = Path(__file__).resolve().parents[1] / "function" / "app.py"

spec = importlib.util.spec_from_file_location("app", APP_PATH)
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)


def _event(method: str):
    return {
        "requestContext": {
            "http": {"method": method}
        }
    }


def test_get_returns_count_zero_when_missing(monkeypatch):
    os.environ["TABLE_NAME"] = "dummy"

    class FakeTable:
        def get_item(self, Key):
            return {}  # no Item

    monkeypatch.setattr(app, "_table", lambda: FakeTable())

    resp = app.handler(_event("GET"), None)
    assert resp["statusCode"] == 200
    assert '"count": 0' in resp["body"]


def test_post_increments(monkeypatch):
    os.environ["TABLE_NAME"] = "dummy"

    class FakeTable:
        def update_item(self, **kwargs):
            return {"Attributes": {"count": 7}}

    monkeypatch.setattr(app, "_table", lambda: FakeTable())

    resp = app.handler(_event("POST"), None)
    assert resp["statusCode"] == 200
    assert '"count": 7' in resp["body"]
