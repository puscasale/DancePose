from pathlib import Path
import torch
import torch.nn.functional as F
import numpy as np

from app.ai.models import DanceTransformer, LateFusionModel
from app.ai.config import WINDOW_SIZE

_DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

_CHECKPOINTS_DIR = Path("app/ai/checkpoints")
_VIT_PATH = _CHECKPOINTS_DIR / "vit_exp_3.pth"
_FUSION_VIT_PATH = _CHECKPOINTS_DIR / "fusion_vit_best.pth"

_FUSION_MODEL = None


def _build_fusion_model() -> LateFusionModel:
    skeleton_backbone = DanceTransformer().to(_DEVICE)
    skeleton_backbone.load_state_dict(torch.load(_VIT_PATH, map_location=_DEVICE))
    skeleton_backbone.eval()

    model = LateFusionModel(
        skeleton_backbone=skeleton_backbone,
        freeze_backbone=True,
    ).to(_DEVICE)

    model.load_state_dict(torch.load(_FUSION_VIT_PATH, map_location=_DEVICE))
    model.eval()

    return model


def get_fusion_model() -> LateFusionModel:
    global _FUSION_MODEL
    if _FUSION_MODEL is None:
        _FUSION_MODEL = _build_fusion_model()
    return _FUSION_MODEL


def _pad_or_trim_skeleton_ctv(skeleton: np.ndarray, window_size: int = WINDOW_SIZE) -> np.ndarray:
    """
    Input: [2, T, 17]
    Output: [2, 150, 17]
    """
    if skeleton.ndim != 3:
        raise ValueError(f"Unexpected skeleton shape: {skeleton.shape}")

    if skeleton.shape[0] != 2:
        raise ValueError(f"Expected skeleton shape [2, T, 17], got {skeleton.shape}")

    if skeleton.shape[1] > window_size:
        skeleton = skeleton[:, :window_size, :]
    elif skeleton.shape[1] < window_size:
        last_frame = skeleton[:, -1:, :]
        pad_size = window_size - skeleton.shape[1]
        padding = np.repeat(last_frame, pad_size, axis=1)
        skeleton = np.concatenate([skeleton, padding], axis=1)

    return skeleton.astype(np.float32)


def load_model_inputs(
    skeleton_path: str | Path,
    video_feature_path: str | Path,
) -> tuple[torch.Tensor, torch.Tensor]:
    skeleton = np.load(skeleton_path).astype(np.float32)            # [2, T, 17] or [2,150,17]
    skeleton = _pad_or_trim_skeleton_ctv(skeleton, WINDOW_SIZE)     # force [2,150,17]

    video_feat = np.load(video_feature_path).astype(np.float32)     # [512]

    skeleton_tensor = torch.from_numpy(skeleton).unsqueeze(0).unsqueeze(-1).to(_DEVICE)
    video_tensor = torch.from_numpy(video_feat).unsqueeze(0).to(_DEVICE)

    return skeleton_tensor, video_tensor


def fusion_forward_with_features(
    skeleton_tensor: torch.Tensor,
    video_tensor: torch.Tensor,
) -> dict:
    model = get_fusion_model()
    model.eval()

    with torch.no_grad():
        skel_logits = model.skeleton_backbone(skeleton_tensor)       # [B, 15]
        video_z = model.video_proj(video_tensor)                     # [B, 128]
        fused_input = torch.cat([skel_logits, video_z], dim=1)       # [B, 143]

        hidden = model.fusion_head[0](fused_input)                   # Linear
        hidden = model.fusion_head[1](hidden)                        # ReLU
        hidden = model.fusion_head[2](hidden)                        # Dropout (passthrough in eval)
        logits = model.fusion_head[3](hidden)                        # [B, 15]

        probs = F.softmax(logits, dim=1)

    return {
        "skel_logits": skel_logits,
        "video_z": video_z,
        "fused_input": fused_input,
        "hidden_embedding": hidden,
        "logits": logits,
        "probs": probs,
    }


def extract_fusion_features(
    skeleton_path: str | Path,
    video_feature_path: str | Path,
) -> dict:
    skeleton_tensor, video_tensor = load_model_inputs(skeleton_path, video_feature_path)
    out = fusion_forward_with_features(skeleton_tensor, video_tensor)

    return {
        "embedding": out["hidden_embedding"].squeeze(0).cpu().numpy().astype(np.float32),
        "logits": out["logits"].squeeze(0).cpu().numpy().astype(np.float32),
        "probs": out["probs"].squeeze(0).cpu().numpy().astype(np.float32),
    }