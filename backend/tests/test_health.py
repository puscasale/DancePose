def test_root_endpoint(client):
    response = client.get("/")

    assert response.status_code == 200

    data = response.json()

    assert data["message"] == "DancePose backend is running"
    assert data["database_url_loaded"] is True