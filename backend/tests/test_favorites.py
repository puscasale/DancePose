def test_get_favorites_initially_empty(client):
    response = client.get("/favorites/")

    assert response.status_code == 200

    data = response.json()

    assert data["styles"] == []
    assert data["moves"] == []


def test_add_favorite_style(client):
    response = client.post("/favorites/styles/1")

    assert response.status_code == 200
    assert response.json()["message"] == "Style added to favorites"

    favorites_response = client.get("/favorites/")
    favorites = favorites_response.json()

    assert len(favorites["styles"]) == 1
    assert favorites["styles"][0]["style_id"] == 1
    assert favorites["styles"][0]["style_name"] == "House"


def test_add_favorite_style_twice_returns_already_message(client):
    first_response = client.post("/favorites/styles/1")
    second_response = client.post("/favorites/styles/1")

    assert first_response.status_code == 200
    assert second_response.status_code == 200
    assert second_response.json()["message"] == "Style already in favorites"


def test_add_missing_favorite_style_returns_404(client):
    response = client.post("/favorites/styles/999999")

    assert response.status_code == 404
    assert response.json()["detail"] == "Style not found"


def test_remove_favorite_style(client):
    add_response = client.post("/favorites/styles/1")
    assert add_response.status_code == 200

    remove_response = client.delete("/favorites/styles/1")

    assert remove_response.status_code == 200
    assert remove_response.json()["message"] == "Style removed from favorites"

    favorites_response = client.get("/favorites/")
    favorites = favorites_response.json()

    assert favorites["styles"] == []


def test_remove_missing_favorite_style_returns_404(client):
    response = client.delete("/favorites/styles/1")

    assert response.status_code == 404
    assert response.json()["detail"] == "Favorite style not found"


def test_add_favorite_move(client):
    response = client.post("/favorites/moves/1")

    assert response.status_code == 200
    assert response.json()["message"] == "Move added to favorites"

    favorites_response = client.get("/favorites/")
    favorites = favorites_response.json()

    assert len(favorites["moves"]) == 1
    assert favorites["moves"][0]["move_id"] == 1
    assert favorites["moves"][0]["move_name"] == "Basic Step"


def test_add_favorite_move_twice_returns_already_message(client):
    first_response = client.post("/favorites/moves/1")
    second_response = client.post("/favorites/moves/1")

    assert first_response.status_code == 200
    assert second_response.status_code == 200
    assert second_response.json()["message"] == "Move already in favorites"


def test_add_missing_favorite_move_returns_404(client):
    response = client.post("/favorites/moves/999999")

    assert response.status_code == 404
    assert response.json()["detail"] == "Move not found"


def test_remove_favorite_move(client):
    add_response = client.post("/favorites/moves/1")
    assert add_response.status_code == 200

    remove_response = client.delete("/favorites/moves/1")

    assert remove_response.status_code == 200
    assert remove_response.json()["message"] == "Move removed from favorites"

    favorites_response = client.get("/favorites/")
    favorites = favorites_response.json()

    assert favorites["moves"] == []


def test_remove_missing_favorite_move_returns_404(client):
    response = client.delete("/favorites/moves/1")

    assert response.status_code == 404
    assert response.json()["detail"] == "Favorite move not found"