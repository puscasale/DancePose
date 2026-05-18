def test_register_success(raw_client):
    response = raw_client.post(
        "/auth/register",
        json={
            "full_name": "New User",
            "email": "newuser@example.com",
            "password": "newpassword123",
        },
    )

    assert response.status_code == 201

    data = response.json()

    assert data["full_name"] == "New User"
    assert data["email"] == "newuser@example.com"
    assert "id" in data
    assert "password" not in data
    assert "password_hash" not in data


def test_register_rejects_duplicate_email(raw_client):
    response = raw_client.post(
        "/auth/register",
        json={
            "full_name": "Duplicate User",
            "email": "test@example.com",
            "password": "testing123",
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Email is already registered"


def test_login_success(raw_client):
    response = raw_client.post(
        "/auth/login",
        json={
            "email": "test@example.com",
            "password": "testing123",
        },
    )

    assert response.status_code == 200

    data = response.json()

    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_rejects_wrong_password(raw_client):
    response = raw_client.post(
        "/auth/login",
        json={
            "email": "test@example.com",
            "password": "wrongpassword",
        },
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email or password"


def test_auth_me_with_valid_token(raw_client):
    login_response = raw_client.post(
        "/auth/login",
        json={
            "email": "test@example.com",
            "password": "testing123",
        },
    )

    token = login_response.json()["access_token"]

    response = raw_client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert response.status_code == 200

    data = response.json()

    assert data["id"] == 1
    assert data["email"] == "test@example.com"
    assert data["full_name"] == "Test User"


def test_auth_me_without_token_is_rejected(raw_client):
    response = raw_client.get("/auth/me")

    assert response.status_code in [401, 403]