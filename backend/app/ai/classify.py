from pathlib import Path
import torch
import numpy as np
from sqlalchemy.orm import Session

from app.ai.models import DanceTransformer, LateFusionModel
from app.ai.labels import INV_LABEL_MAP, LABEL_TO_APP
from app.models.dance_style import DanceStyle
from app.models.dance_move import DanceMove

_DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

_CHECKPOINTS_DIR = Path("app/ai/checkpoints")
_VIT_PATH = _CHECKPOINTS_DIR / "vit_exp_3.pth"
_FUSION_VIT_PATH = _CHECKPOINTS_DIR / "fusion_vit_best.pth"

_MODEL = None


def _build_model() -> LateFusionModel:
    vit_backbone = DanceTransformer().to(_DEVICE)
    vit_backbone.load_state_dict(torch.load(_VIT_PATH, map_location=_DEVICE))
    vit_backbone.eval()

    fusion_model = LateFusionModel(
        skeleton_backbone=vit_backbone,
        freeze_backbone=True,
    ).to(_DEVICE)

    fusion_model.load_state_dict(torch.load(_FUSION_VIT_PATH, map_location=_DEVICE))
    fusion_model.eval()

    return fusion_model


def _get_model() -> LateFusionModel:
    global _MODEL
    if _MODEL is None:
        _MODEL = _build_model()
    return _MODEL


def _prepare_inputs(
    skeleton_path: str | Path,
    video_feature_path: str | Path,
) -> tuple[torch.Tensor, torch.Tensor]:
    skeleton = np.load(skeleton_path).astype(np.float32)       # [2, 150, 17]
    video_feat = np.load(video_feature_path).astype(np.float32)  # [512]

    skeleton_tensor = torch.from_numpy(skeleton).unsqueeze(0).unsqueeze(-1).to(_DEVICE)
    video_tensor = torch.from_numpy(video_feat).unsqueeze(0).to(_DEVICE)

    return skeleton_tensor, video_tensor


def classify_fusion_vit(
    skeleton_path: str | Path,
    video_feature_path: str | Path,
) -> dict:
    model = _get_model()
    skeleton_tensor, video_tensor = _prepare_inputs(skeleton_path, video_feature_path)

    with torch.no_grad():
        logits = model(skeleton_tensor, video_tensor)
        probs = torch.softmax(logits, dim=1)
        confidence, pred_idx = torch.max(probs, dim=1)

    pred_idx_int = int(pred_idx.item())
    confidence_float = float(confidence.item())

    predicted_label = INV_LABEL_MAP[pred_idx_int]
    mapped = LABEL_TO_APP[predicted_label]

    return {
        "predicted_label": predicted_label,
        "confidence": confidence_float,
        "style_name": mapped["style_name"],
        "move_name": mapped["move_name"],
    }


def resolve_predicted_ids(
    db: Session,
    style_name: str,
    move_name: str,
) -> tuple[int | None, int | None]:
    style = db.query(DanceStyle).filter(DanceStyle.name == style_name).first()
    if not style:
        return None, None

    move = (
        db.query(DanceMove)
        .filter(
            DanceMove.style_id == style.id,
            DanceMove.name == move_name,
        )
        .first()
    )

    return style.id, move.id if move else None