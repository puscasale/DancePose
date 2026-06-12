from pathlib import Path

import numpy as np
import torch
from sqlalchemy.orm import Session

from app.ai.config import FINAL_MODEL_TYPE
from app.ai.labels import INV_LABEL_MAP, LABEL_TO_APP
from app.ai.models import DanceTransformer, LateFusionModel
from app.models.dance_style import DanceStyle
from app.models.dance_move import DanceMove


_DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

_CHECKPOINTS_DIR = Path("app/ai/checkpoints")
_VIT_PATH = _CHECKPOINTS_DIR / "vit_exp_3.pth"
_FUSION_VIT_PATH = _CHECKPOINTS_DIR / "fusion_vit_best.pth"

_VIT_MODEL = None
_FUSION_MODEL = None


def _build_vit_model() -> DanceTransformer:
    model = DanceTransformer().to(_DEVICE)
    model.load_state_dict(torch.load(_VIT_PATH, map_location=_DEVICE))
    model.eval()
    return model


def _get_vit_model() -> DanceTransformer:
    global _VIT_MODEL

    if _VIT_MODEL is None:
        _VIT_MODEL = _build_vit_model()

    return _VIT_MODEL


def _build_fusion_model() -> LateFusionModel:
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


def _get_fusion_model() -> LateFusionModel:
    global _FUSION_MODEL

    if _FUSION_MODEL is None:
        _FUSION_MODEL = _build_fusion_model()

    return _FUSION_MODEL


def _prepare_skeleton_input(skeleton_path: str | Path) -> torch.Tensor:
    skeleton = np.load(skeleton_path).astype(np.float32)  # [2, 150, 17]
    skeleton_tensor = (
        torch.from_numpy(skeleton)
        .unsqueeze(0)      # [1, 2, 150, 17]
        .unsqueeze(-1)     # [1, 2, 150, 17, 1]
        .to(_DEVICE)
    )

    return skeleton_tensor


def _prepare_fusion_inputs(
    skeleton_path: str | Path,
    video_feature_path: str | Path,
) -> tuple[torch.Tensor, torch.Tensor]:
    skeleton_tensor = _prepare_skeleton_input(skeleton_path)

    video_feat = np.load(video_feature_path).astype(np.float32)  # [512]
    video_tensor = torch.from_numpy(video_feat).unsqueeze(0).to(_DEVICE)

    return skeleton_tensor, video_tensor


def _format_prediction(pred_idx: int, confidence: float) -> dict:
    predicted_label = INV_LABEL_MAP[pred_idx]
    mapped = LABEL_TO_APP[predicted_label]

    return {
        "predicted_label": predicted_label,
        "confidence": confidence,
        "style_name": mapped["style_name"],
        "move_name": mapped["move_name"],
    }


def classify_vit(skeleton_path: str | Path) -> dict:
    model = _get_vit_model()
    skeleton_tensor = _prepare_skeleton_input(skeleton_path)

    with torch.no_grad():
        logits = model(skeleton_tensor)
        probs = torch.softmax(logits, dim=1)
        confidence, pred_idx = torch.max(probs, dim=1)

    return _format_prediction(
        pred_idx=int(pred_idx.item()),
        confidence=float(confidence.item()),
    )


def classify_fusion_vit(
    skeleton_path: str | Path,
    video_feature_path: str | Path,
) -> dict:
    model = _get_fusion_model()
    skeleton_tensor, video_tensor = _prepare_fusion_inputs(
        skeleton_path=skeleton_path,
        video_feature_path=video_feature_path,
    )

    with torch.no_grad():
        logits = model(skeleton_tensor, video_tensor)
        probs = torch.softmax(logits, dim=1)
        confidence, pred_idx = torch.max(probs, dim=1)

    return _format_prediction(
        pred_idx=int(pred_idx.item()),
        confidence=float(confidence.item()),
    )


def classify_dance(
    skeleton_path: str | Path,
    video_feature_path: str | Path | None = None,
) -> dict:
    if FINAL_MODEL_TYPE == "vit":
        return classify_vit(skeleton_path)

    if FINAL_MODEL_TYPE == "fusion":
        if video_feature_path is None:
            raise ValueError("video_feature_path is required when FINAL_MODEL_TYPE='fusion'")

        return classify_fusion_vit(
            skeleton_path=skeleton_path,
            video_feature_path=video_feature_path,
        )

    raise ValueError(
        f"Unknown FINAL_MODEL_TYPE={FINAL_MODEL_TYPE}. "
        "Expected 'vit' or 'fusion'."
    )


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