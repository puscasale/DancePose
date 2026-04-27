from pathlib import Path
import cv2
import numpy as np
import torch
import torch.nn as nn
from torchvision.models.video import r3d_18, R3D_18_Weights

from app.ai.config import R3D_NUM_FRAMES

_device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
_weights = R3D_18_Weights.DEFAULT
_preprocess = _weights.transforms()
_backbone = None
_feature_extractor = None


class R3D18FeatureExtractor(nn.Module):
    def __init__(self, backbone):
        super().__init__()
        self.stem = backbone.stem
        self.layer1 = backbone.layer1
        self.layer2 = backbone.layer2
        self.layer3 = backbone.layer3
        self.layer4 = backbone.layer4
        self.avgpool = backbone.avgpool

    def forward(self, x):
        x = self.stem(x)
        x = self.layer1(x)
        x = self.layer2(x)
        x = self.layer3(x)
        x = self.layer4(x)
        x = self.avgpool(x)
        x = torch.flatten(x, 1)  # [B, 512]
        return x


def _get_feature_extractor():
    global _backbone, _feature_extractor

    if _feature_extractor is None:
        _backbone = r3d_18(weights=_weights).to(_device)
        _backbone.eval()
        _feature_extractor = R3D18FeatureExtractor(_backbone).to(_device)
        _feature_extractor.eval()

    return _feature_extractor


def sample_video_frames(video_path: str | Path, num_frames: int = R3D_NUM_FRAMES) -> list[np.ndarray]:
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        raise ValueError(f"Cannot open video: {video_path}")

    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    if total_frames <= 0:
        cap.release()
        raise ValueError(f"Invalid or empty video: {video_path}")

    indices = np.linspace(0, total_frames - 1, num_frames).astype(int)

    frames: list[np.ndarray] = []
    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, int(idx))
        ok, frame = cap.read()
        if not ok:
            continue

        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frames.append(frame)

    cap.release()

    if len(frames) == 0:
        raise ValueError(f"No frames could be sampled from video: {video_path}")

    while len(frames) < num_frames:
        frames.append(frames[-1].copy())

    return frames


def extract_video_feature(video_path: str | Path, num_frames: int = R3D_NUM_FRAMES) -> np.ndarray:
    feature_extractor = _get_feature_extractor()
    frames = sample_video_frames(video_path, num_frames=num_frames)

    frame_tensors = []
    for frame in frames:
        frame_tensor = torch.from_numpy(frame).permute(2, 0, 1)  # [C, H, W]
        frame_tensors.append(frame_tensor)

    clip = torch.stack(frame_tensors, dim=0)  # [T, C, H, W]
    clip = _preprocess(clip)

    if clip.ndim == 4 and clip.shape[1] == 3:
        clip = clip.permute(1, 0, 2, 3)  # [C, T, H, W]
    elif clip.ndim == 4 and clip.shape[0] == 3:
        pass
    else:
        raise ValueError(f"Unexpected clip shape after preprocess: {clip.shape}")

    clip = clip.unsqueeze(0).to(_device)  # [1, C, T, H, W]

    with torch.no_grad():
        feat = feature_extractor(clip)

    return feat.squeeze(0).cpu().numpy().astype(np.float32)  # [512]