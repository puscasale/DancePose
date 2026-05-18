def test_get_styles_returns_list(client):
    response = client.get("/styles/")

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1
    assert data[0]["name"] == "House"


def test_get_all_moves_returns_list(client):
    response = client.get("/moves/")

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1
    assert data[0]["name"] == "Basic Step"


def test_get_moves_by_existing_style(client):
    response = client.get("/moves/style/1")

    assert response.status_code == 200

    data = response.json()

    assert isinstance(data, list)
    assert len(data) >= 1
    assert data[0]["name"] == "Basic Step"


def test_get_moves_by_missing_style_returns_404(client):
    response = client.get("/moves/style/999999")

    assert response.status_code == 404
    assert response.json()["detail"] == "Style not found"