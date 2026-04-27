from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

from app.ai.scoring import load_pose_sequence, normalize_pose_sequence

MEDIA_DIR = Path("media")
HEATMAP_DIR = MEDIA_DIR / "heatmaps"
HEATMAP_DIR.mkdir(parents=True, exist_ok=True)

SKELETON_EDGES = [
    (0, 1), (0, 2),
    (1, 3), (2, 4),
    (5, 6),
    (5, 7), (7, 9),
    (6, 8), (8, 10),
    (5, 11), (6, 12),
    (11, 12),
    (11, 13), (13, 15),
    (12, 14), (14, 16),
]

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

BODY_JOINTS_ONLY = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]


def joint_errors_for_frame_pair(
    seq_nov_norm: np.ndarray,
    seq_exp_norm: np.ndarray,
    nov_idx: int,
    exp_idx: int,
) -> np.ndarray:
    nov_frame = seq_nov_norm[nov_idx]
    exp_frame = seq_exp_norm[exp_idx]
    joint_errors = np.linalg.norm(nov_frame - exp_frame, axis=1)
    return joint_errors.astype(np.float32)


def edge_errors_from_joint_errors(joint_errors: np.ndarray, edges: list[tuple[int, int]]) -> np.ndarray:
    edge_errors = []
    for a, b in edges:
        edge_errors.append((joint_errors[a] + joint_errors[b]) / 2.0)
    return np.array(edge_errors, dtype=np.float32)


def normalize_errors(errors: np.ndarray, eps: float = 1e-8) -> np.ndarray:
    mn = np.min(errors)
    mx = np.max(errors)
    if mx - mn < eps:
        return np.zeros_like(errors)
    return (errors - mn) / (mx - mn)


def errors_to_colors(errors: np.ndarray, cmap_name: str = "RdYlGn_r"):
    cmap = plt.get_cmap(cmap_name)
    normed = normalize_errors(errors)
    return [cmap(v) for v in normed]


def _to_plot_coords(frame: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    y = frame[:, 0]
    x = frame[:, 1]
    return x, -y


def plot_overlay_heatmap(
    seq_nov_norm: np.ndarray,
    seq_exp_norm: np.ndarray,
    nov_idx: int,
    exp_idx: int,
    title: str,
    save_path: str | Path,
):
    nov_frame = seq_nov_norm[nov_idx]
    exp_frame = seq_exp_norm[exp_idx]

    joint_errors = joint_errors_for_frame_pair(seq_nov_norm, seq_exp_norm, nov_idx, exp_idx)
    edge_errors = edge_errors_from_joint_errors(joint_errors, SKELETON_EDGES)

    joint_colors = errors_to_colors(joint_errors, cmap_name="RdYlGn_r")
    edge_colors = errors_to_colors(edge_errors, cmap_name="RdYlGn_r")

    nov_x, nov_y = _to_plot_coords(nov_frame)
    exp_x, exp_y = _to_plot_coords(exp_frame)

    fig, ax = plt.subplots(figsize=(8, 5.6))

    for (a, b) in SKELETON_EDGES:
        ax.plot(
            [exp_x[a], exp_x[b]],
            [exp_y[a], exp_y[b]],
            color="lightgray",
            linewidth=2,
            alpha=0.9,
        )

    ax.scatter(exp_x, exp_y, c="lightgray", s=40, alpha=0.9)

    for idx, (a, b) in enumerate(SKELETON_EDGES):
        ax.plot(
            [nov_x[a], nov_x[b]],
            [nov_y[a], nov_y[b]],
            color=edge_colors[idx],
            linewidth=4,
            alpha=0.95,
        )

    for j in range(len(nov_frame)):
        ax.scatter(
            nov_x[j],
            nov_y[j],
            color=joint_colors[j],
            s=90,
            edgecolor="black",
            linewidth=0.5,
        )

    ax.set_title(title)
    ax.axis("equal")
    ax.grid(True)

    cmap = plt.get_cmap("RdYlGn_r")
    norm = plt.Normalize(vmin=np.min(joint_errors), vmax=np.max(joint_errors))
    sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
    sm.set_array([])
    fig.colorbar(sm, ax=ax, label="Joint error")

    legend_elements = [
        Line2D([0], [0], color="lightgray", lw=2, label="Expert skeleton"),
        Line2D([0], [0], color="black", lw=4, label="Novice skeleton (heatmap)"),
    ]
    ax.legend(handles=legend_elements, loc="upper right")

    save_path = Path(save_path)
    save_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(save_path, bbox_inches="tight", dpi=200)
    plt.close(fig)

    return joint_errors, edge_errors


def get_top_problematic_joints(joint_errors: np.ndarray, top_k: int = 3) -> str:
    filtered = [(idx, float(joint_errors[idx])) for idx in BODY_JOINTS_ONLY]
    filtered.sort(key=lambda x: x[1], reverse=True)
    names = [JOINT_NAMES[idx] for idx, _ in filtered[:top_k]]
    return ", ".join(names)


def generate_session_heatmaps(
    novice_skeleton_path: str | Path,
    expert_skeleton_path: str | Path,
    best_novice_frame: int,
    best_expert_frame: int,
    worst_novice_frame: int,
    worst_expert_frame: int,
    session_id: int,
) -> dict:
    seq_nov = normalize_pose_sequence(load_pose_sequence(novice_skeleton_path))
    seq_exp = normalize_pose_sequence(load_pose_sequence(expert_skeleton_path))

    best_path = HEATMAP_DIR / f"session_{session_id}_best_heatmap.png"
    worst_path = HEATMAP_DIR / f"session_{session_id}_worst_heatmap.png"

    plot_overlay_heatmap(
        seq_nov,
        seq_exp,
        nov_idx=best_novice_frame,
        exp_idx=best_expert_frame,
        title=f"BEST FRAME - Session {session_id}",
        save_path=best_path,
    )

    worst_joint_errors, _ = plot_overlay_heatmap(
        seq_nov,
        seq_exp,
        nov_idx=worst_novice_frame,
        exp_idx=worst_expert_frame,
        title=f"WORST FRAME - Session {session_id}",
        save_path=worst_path,
    )

    problematic_joints_text = get_top_problematic_joints(worst_joint_errors, top_k=3)

    return {
        "best_heatmap_path": str(best_path),
        "worst_heatmap_path": str(worst_path),
        "problematic_joints_text": problematic_joints_text,
    }