from pathlib import Path
import numpy as np

from app.ai.labels import LABEL_MAP
from app.ai.fusion_features import extract_fusion_features
from app.ai.expert_bank import get_expert_files_for_label, get_expert_feature_path


JOINT_NAMES = {
    0: "nose",
    1: "left_eye",
    2: "right_eye",
    3: "left_ear",
    4: "right_ear",
    5: "left_shoulder",
    6: "right_shoulder",
    7: "left_elbow",
    8: "right_elbow",
    9: "left_wrist",
    10: "right_wrist",
    11: "left_hip",
    12: "right_hip",
    13: "left_knee",
    14: "right_knee",
    15: "left_ankle",
    16: "right_ankle",
}

ARM_ANGLE_TRIPLETS = [
    (5, 7, 9),
    (6, 8, 10),
    (11, 5, 7),
    (12, 6, 8),
]

LEG_ANGLE_TRIPLETS = [
    (11, 13, 15),
    (12, 14, 16),
    (5, 11, 13),
    (6, 12, 14),
]

ANGLE_ALPHA = 0.03


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    a = a.astype(np.float32)
    b = b.astype(np.float32)

    denom = (np.linalg.norm(a) * np.linalg.norm(b)) + 1e-8
    return float(np.dot(a, b) / denom)


def embedding_similarity_to_score(sim: float) -> float:
    return float(np.clip(((sim + 1.0) / 2.0) * 100.0, 0.0, 100.0))


def confidence_to_score(prob: float) -> float:
    return float(np.clip(prob * 100.0, 0.0, 100.0))


def load_pose_sequence(npy_path: str | Path) -> np.ndarray:
    data = np.load(npy_path).astype(np.float32)  # [C, T, V]
    if data.ndim != 3:
        raise ValueError(f"Unexpected pose shape: {data.shape} for {npy_path}")
    seq = np.transpose(data, (1, 2, 0))  # [T, V, 2]
    return seq.astype(np.float32)


def normalize_pose_sequence(seq: np.ndarray) -> np.ndarray:
    seq = seq.copy().astype(np.float32)

    left_hip = seq[:, 11, :]
    right_hip = seq[:, 12, :]
    hip_center = (left_hip + right_hip) / 2.0

    left_shoulder = seq[:, 5, :]
    right_shoulder = seq[:, 6, :]
    shoulder_center = (left_shoulder + right_shoulder) / 2.0

    torso_len = np.linalg.norm(shoulder_center - hip_center, axis=1, keepdims=True)
    torso_len = np.clip(torso_len, 1e-6, None)

    seq = seq - hip_center[:, None, :]
    seq = seq / torso_len[:, None, :]

    return seq.astype(np.float32)


def angle_3pts(a: np.ndarray, b: np.ndarray, c: np.ndarray) -> float:
    ba = a - b
    bc = c - b

    norm_ba = np.linalg.norm(ba)
    norm_bc = np.linalg.norm(bc)

    if norm_ba < 1e-8 or norm_bc < 1e-8:
        return 0.0

    cosang = np.dot(ba, bc) / (norm_ba * norm_bc)
    cosang = np.clip(cosang, -1.0, 1.0)
    return float(np.degrees(np.arccos(cosang)))


def frame_angles(frame: np.ndarray, triplets: list[tuple[int, int, int]]) -> np.ndarray:
    angles = []
    for a, b, c in triplets:
        angles.append(angle_3pts(frame[a], frame[b], frame[c]))
    return np.array(angles, dtype=np.float32)


def sequence_angles(seq: np.ndarray, triplets: list[tuple[int, int, int]]) -> np.ndarray:
    all_angles = []
    for t in range(len(seq)):
        all_angles.append(frame_angles(seq[t], triplets))
    return np.stack(all_angles, axis=0).astype(np.float32)


def dtw_path_precomputed(seq_a: np.ndarray, seq_b: np.ndarray, frame_distance_fn):
    n = len(seq_a)
    m = len(seq_b)

    dp = np.full((n + 1, m + 1), np.inf, dtype=np.float64)
    dp[0, 0] = 0.0

    parent = np.full((n + 1, m + 1, 2), -1, dtype=np.int32)

    for i in range(1, n + 1):
        for j in range(1, m + 1):
            cost = frame_distance_fn(seq_a[i - 1], seq_b[j - 1])

            candidates = [
                (dp[i - 1, j], (i - 1, j)),
                (dp[i, j - 1], (i, j - 1)),
                (dp[i - 1, j - 1], (i - 1, j - 1)),
            ]

            prev_cost, prev_idx = min(candidates, key=lambda x: x[0])
            dp[i, j] = cost + prev_cost
            parent[i, j] = prev_idx

    path = []
    i, j = n, m
    while i > 0 or j > 0:
        path.append((i - 1, j - 1))
        i_prev, j_prev = parent[i, j]
        i, j = i_prev, j_prev

    path.reverse()
    mean_cost = dp[n, m] / max(len(path), 1)

    return path, float(mean_cost)


def angle_score_from_error(err: float, alpha: float = ANGLE_ALPHA) -> float:
    score = 100.0 * np.exp(-alpha * err)
    score = np.clip(score, 0.0, 100.0)
    return float(score)


def compute_angle_part_score(
    novice_skeleton_path: str | Path,
    expert_skeleton_path: str | Path,
    triplets: list[tuple[int, int, int]],
) -> dict:
    seq_nov = normalize_pose_sequence(load_pose_sequence(novice_skeleton_path))
    seq_exp = normalize_pose_sequence(load_pose_sequence(expert_skeleton_path))

    seq_a = sequence_angles(seq_nov, triplets)
    seq_b = sequence_angles(seq_exp, triplets)

    dist_fn = lambda a, b: np.mean(np.abs(a - b))

    path, err = dtw_path_precomputed(seq_a, seq_b, dist_fn)
    frame_errors = np.array([dist_fn(seq_a[i], seq_b[j]) for i, j in path], dtype=np.float32)

    score = angle_score_from_error(err)

    best_idx = int(np.argmin(frame_errors))
    worst_idx = int(np.argmax(frame_errors))

    return {
        "error": float(err),
        "score": float(score),
        "path": path,
        "frame_errors": frame_errors,
        "best_pair": path[best_idx],
        "worst_pair": path[worst_idx],
    }


def get_correct_label_for_scoring(
    mode: str,
    predicted_label: str,
    selected_style_name: str | None = None,
    selected_move_name: str | None = None,
) -> str:
    if mode == "learning" and selected_style_name and selected_move_name:
        for label, meta in _label_to_app().items():
            if (
                meta["style_name"] == selected_style_name
                and meta["move_name"] == selected_move_name
            ):
                return label

    return predicted_label


def _label_to_app():
    from app.ai.labels import LABEL_TO_APP
    return LABEL_TO_APP


def compute_overall_ai_score(
    novice_model_input_path: str | Path,
    novice_video_feature_path: str | Path,
    mode: str,
    predicted_label: str,
    selected_style_name: str | None = None,
    selected_move_name: str | None = None,
) -> dict:
    novice_out = extract_fusion_features(
        skeleton_path=novice_model_input_path,
        video_feature_path=novice_video_feature_path,
    )

    probs = novice_out["probs"]
    emb = novice_out["embedding"]

    correct_label = get_correct_label_for_scoring(
        mode=mode,
        predicted_label=predicted_label,
        selected_style_name=selected_style_name,
        selected_move_name=selected_move_name,
    )

    true_idx = LABEL_MAP[correct_label]
    confidence_correct_class = confidence_to_score(float(probs[true_idx]))  # 0..100

    expert_refs = get_expert_files_for_label(correct_label)
    if len(expert_refs) == 0:
        raise ValueError(f"No expert references found for label {correct_label}")

    sims = []

    for ef in expert_refs:
        expert_feature_path = get_expert_feature_path(ef)
        expert_out = extract_fusion_features(
            skeleton_path=ef,
            video_feature_path=expert_feature_path,
        )

        sim = cosine_similarity(emb, expert_out["embedding"])
        sims.append((ef, sim))

    sims_sorted = sorted(sims, key=lambda x: x[1], reverse=True)

    best_expert_path, best_sim = sims_sorted[0]
    embedding_score_best = embedding_similarity_to_score(best_sim)  # 0..100

    overall_ai_score = 0.5 * confidence_correct_class + 0.5 * embedding_score_best

    return {
        "correct_label": correct_label,
        "confidence_correct_class": float(confidence_correct_class),  # 0..100
        "embedding_similarity_best_raw": float(best_sim),
        "embedding_score_best": float(embedding_score_best),          # 0..100
        "overall_ai_score": float(overall_ai_score),                 # 0..100
        "best_expert_file": Path(best_expert_path).name,
        "best_expert_path": str(best_expert_path),
    }


def compute_body_part_scores(
    novice_normalized_full_path: str | Path,
    expert_normalized_full_path: str | Path,
) -> dict:
    arms = compute_angle_part_score(
        novice_skeleton_path=novice_normalized_full_path,
        expert_skeleton_path=expert_normalized_full_path,
        triplets=ARM_ANGLE_TRIPLETS,
    )

    legs = compute_angle_part_score(
        novice_skeleton_path=novice_normalized_full_path,
        expert_skeleton_path=expert_normalized_full_path,
        triplets=LEG_ANGLE_TRIPLETS,
    )

    overall_angles = compute_angle_part_score(
        novice_skeleton_path=novice_normalized_full_path,
        expert_skeleton_path=expert_normalized_full_path,
        triplets=ARM_ANGLE_TRIPLETS + LEG_ANGLE_TRIPLETS,
    )

    return {
        "arms_score_raw": float(arms["score"]),   # 0..100
        "legs_score_raw": float(legs["score"]),   # 0..100
        "arms_error": float(arms["error"]),
        "legs_error": float(legs["error"]),
        "best_novice_frame": int(overall_angles["best_pair"][0]),
        "best_expert_frame": int(overall_angles["best_pair"][1]),
        "worst_novice_frame": int(overall_angles["worst_pair"][0]),
        "worst_expert_frame": int(overall_angles["worst_pair"][1]),
    }