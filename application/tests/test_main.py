from fastapi.testclient import TestClient

from src.main import app

client = TestClient(app)


def test_root() -> None:
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Sample API"}


def test_health() -> None:
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


def test_version() -> None:
    response = client.get("/version")
    assert response.status_code == 200
    assert response.json() == {"version": "1.0"}


def test_routes_work_with_and_without_prefix(monkeypatch) -> None:
    # ALB health checks hit /health directly, user traffic arrives with the prefix
    monkeypatch.setattr(app, "root_path", "/sample-api")
    assert client.get("/health").status_code == 200
    assert client.get("/sample-api/health").status_code == 200
    assert client.get("/sample-api/version").json() == {"version": "1.0"}


def test_unknown_route_returns_404() -> None:
    assert client.get("/does-not-exist").status_code == 404
