import numpy as np

from app.ai.config import (
    RAW_KEYPOINTS_DIR,
    NORM_KEYPOINTS_DIR,
    MODEL_INPUT_KEYPOINTS_DIR,
    VIDEO_FEATURES_DIR,
)
from app.ai.keypoints import extract_keypoints_from_video
from app.ai.normalize import prepare_full_skeleton, prepare_skeleton_for_model
from app.ai.video_features import extract_video_feature


def run_preprocessing_pipeline(video_path: str, session_id: int) -> dict:
    raw_keypoints = extract_keypoints_from_video(video_path)          # [T, 17, 3]
    normalized_full = prepare_full_skeleton(raw_keypoints)           # [2, T, 17]
    model_input_skeleton = prepare_skeleton_for_model(raw_keypoints) # [2, 150, 17]
    video_feature = extract_video_feature(video_path)                # [512]

    raw_keypoints_path = RAW_KEYPOINTS_DIR / f"session_{session_id}.npy"
    normalized_full_path = NORM_KEYPOINTS_DIR / f"session_{session_id}.npy"
    model_input_path = MODEL_INPUT_KEYPOINTS_DIR / f"session_{session_id}.npy"
    video_feature_path = VIDEO_FEATURES_DIR / f"session_{session_id}.npy"

    np.save(raw_keypoints_path, raw_keypoints.astype(np.float32))
    np.save(normalized_full_path, normalized_full.astype(np.float32))
    np.save(model_input_path, model_input_skeleton.astype(np.float32))
    np.save(video_feature_path, video_feature.astype(np.float32))

    return {
        "raw_keypoints_path": str(raw_keypoints_path),
        "normalized_full_path": str(normalized_full_path),
        "model_input_path": str(model_input_path),
        "video_feature_path": str(video_feature_path),
        "raw_keypoints_shape": list(raw_keypoints.shape),
        "normalized_full_shape": list(normalized_full.shape),
        "model_input_shape": list(model_input_skeleton.shape),
        "video_feature_shape": list(video_feature.shape),
    }