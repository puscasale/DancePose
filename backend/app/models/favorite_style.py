from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from app.core.database import Base


class FavoriteStyle(Base):
    __tablename__ = "favorite_styles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    style_id = Column(Integer, ForeignKey("dance_styles.id"), nullable=False)

    __table_args__ = (
        UniqueConstraint("user_id", "style_id", name="uq_favorite_style_user_style"),
    )