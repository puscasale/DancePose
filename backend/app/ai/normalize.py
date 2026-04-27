import numpy as np

from app.ai.config import WINDOW_SIZE


def raw_to_ctv(raw_keypoints: np.ndarray) -> np.ndarray:
    coords = raw_keypoints[:, :, :2].astype(np.float32)   # [T, 17, 2]
    return coords.transpose(2, 0, 1).astype(np.float32)   # [2, T, 17]


def normalize_torso_ctv(data_ctv: np.ndarray) -> np.ndarray:
    data = data_ctv.copy().astype(np.float32)
    T = data.shape[1]

    out = np.zeros_like(data, dtype=np.float32)

    for t in range(T):
        frame = data[:, t, :]

        torso_center = np.mean(frame[:, [5, 6, 11, 12]], axis=1, keepdims=True)

        shoulder_mid = np.mean(frame[:, [5, 6]], axis=1)
        hip_mid = np.mean(frame[:, [11, 12]], axis=1)
        torso_size = np.linalg.norm(shoulder_mid - hip_mid)

        if torso_size < 0.001:
            torso_size = 1.0

        out[:, t, :] = (frame - torso_center) / torso_size

    return out.astype(np.float32)


def scale_to_standard_human_ctv(data_ctv: np.ndarray) -> np.ndarray:
    data = data_ctv.copy().astype(np.float32)

    mid_hip_y = (data[0, :, 11] + data[0, :, 12]) / 2
    mid_hip_x = (data[1, :, 11] + data[1, :, 12]) / 2

    data[0, :, :] -= mid_hip_y[:, np.newaxis]
    data[1, :, :] -= mid_hip_x[:, np.newaxis]

    avg_sh_y = (data[0, :, 5] + data[0, :, 6]) / 2
    h_scale = np.mean(np.abs(avg_sh_y))

    w_scale = np.mean(np.abs(data[1, :, 5] - data[1, :, 6]))

    if h_scale > 0.001:
        data[0, :, :] /= h_scale
    if w_scale > 0.001:
        data[1, :, :] /= w_scale

    return data.astype(np.float32)


def pad_or_trim_sequence_ctv(data: np.ndarray, window_size: int = WINDOW_SIZE) -> np.ndarray:
    if data.shape[1] > window_size:
        return data[:, :window_size, :].astype(np.float32)

    if data.shape[1] < window_size:
        last_frame = data[:, -1:, :]
        pad_size = window_size - data.shape[1]
        padding = np.repeat(last_frame, pad_size, axis=1)
        data = np.concatenate([data, padding], axis=1)

    return data.astype(np.float32)


def prepare_full_skeleton(raw_keypoints: np.ndarray) -> np.ndarray:
    data_ctv = raw_to_ctv(raw_keypoints)
    data_ctv = normalize_torso_ctv(data_ctv)
    data_ctv = scale_to_standard_human_ctv(data_ctv)
    return data_ctv.astype(np.float32)   # [2, T, 17]


def prepare_skeleton_for_model(raw_keypoints: np.ndarray) -> np.ndarray:
    full = prepare_full_skeleton(raw_keypoints)
    fixed = pad_or_trim_sequence_ctv(full, WINDOW_SIZE)
    return fixed.astype(np.float32)      # [2, 150, 17]