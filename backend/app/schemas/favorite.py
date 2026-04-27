from pydantic import BaseModel


class FavoriteStyleItem(BaseModel):
    style_id: int
    style_name: str


class FavoriteMoveItem(BaseModel):
    move_id: int
    move_name: str
    style_id: int | None = None
    style_name: str | None = None


class FavoritesResponse(BaseModel):
    styles: list[FavoriteStyleItem]
    moves: list[FavoriteMoveItem]


class SimpleMessageResponse(BaseModel):
    message: str