from pathlib import Path

AI_DATA_DIR = Path("ai_data")
AI_DATA_DIR.mkdir(parents=True, exist_ok=True)

RAW_KEYPOINTS_DIR = AI_DATA_DIR / "raw_keypoints"
RAW_KEYPOINTS_DIR.mkdir(parents=True, exist_ok=True)

NORM_KEYPOINTS_DIR = AI_DATA_DIR / "normalized_keypoints"
NORM_KEYPOINTS_DIR.mkdir(parents=True, exist_ok=True)

MODEL_INPUT_KEYPOINTS_DIR = AI_DATA_DIR / "model_input_keypoints"
MODEL_INPUT_KEYPOINTS_DIR.mkdir(parents=True, exist_ok=True)

VIDEO_FEATURES_DIR = AI_DATA_DIR / "video_features"
VIDEO_FEATURES_DIR.mkdir(parents=True, exist_ok=True)

WINDOW_SIZE = 150
NUM_JOINTS = 17
VIDEO_FEAT_DIM = 512
MOVENET_INPUT_SIZE = 256
R3D_NUM_FRAMES = 16

FINAL_MODEL_TYPE = "vit"  # options: "vit", "fusion"