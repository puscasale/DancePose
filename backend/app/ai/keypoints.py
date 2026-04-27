from pathlib import Path
import cv2
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub

from app.ai.config import MOVENET_INPUT_SIZE

_module = None
_movenet = None


def _get_movenet():
    global _module, _movenet

    if _movenet is None:
        _module = hub.load("https://tfhub.dev/google/movenet/multipose/lightning/1")
        _movenet = _module.signatures["serving_default"]

    return _movenet


def extract_keypoints_from_video(video_path: str | Path) -> np.ndarray:
    video_path = str(video_path)
    movenet = _get_movenet()

    cap = cv2.VideoCapture(video_path)
    all_frames_data: list[np.ndarray] = []

    if not cap.isOpened():
        raise ValueError(f"Cannot open video: {video_path}")

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        img = tf.image.resize_with_pad(frame, MOVENET_INPUT_SIZE, MOVENET_INPUT_SIZE)
        input_img = tf.cast(img, dtype=tf.int32)
        input_img = tf.expand_dims(input_img, axis=0)

        outputs = movenet(input_img)
        keypoints_with_scores = (
            outputs["output_0"].numpy()[0, 0, :51].reshape(17, 3).astype(np.float32)
        )

        all_frames_data.append(keypoints_with_scores)

    cap.release()

    if len(all_frames_data) == 0:
        raise ValueError(f"No frames could be processed from video: {video_path}")

    return np.array(all_frames_data, dtype=np.float32)  # [T, 17, 3]