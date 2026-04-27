from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from app.core.database import Base


class FavoriteMove(Base):
    __tablename__ = "favorite_moves"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    move_id = Column(Integer, ForeignKey("dance_moves.id"), nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "move_id", name="uq_favorite_move_user_move"),
    )