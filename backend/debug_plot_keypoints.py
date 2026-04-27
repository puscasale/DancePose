from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt

RAW_PATH = Path("ai_data/raw_keypoints/session_12.npy")
NORM_PATH = Path("ai_data/normalized_keypoints/session_12.npy")

EDGES = [
    (0, 1), (0, 2), (1, 3), (2, 4),
    (5, 6), (5, 7), (7, 9), (6, 8), (8, 10),
    (5, 11), (6, 12), (11, 12),
    (11, 13), (13, 15), (12, 14), (14, 16),
]

def plot_raw_frame(ax, raw_data, frame_idx, title):
    frame = raw_data[frame_idx]  # [17, 3]
    coords = frame[:, :2]        # [17, 2]

    y = coords[:, 0]
    x = coords[:, 1]

    ax.scatter(x, -y, c="red", s=30)

    for i, j in EDGES:
        ax.plot([x[i], x[j]], [-y[i], -y[j]], color="red", linewidth=1.5)

    ax.set_title(title)
    ax.axis("equal")
    ax.grid(True, linestyle="--", alpha=0.3)

def plot_norm_frame(ax, norm_data, frame_idx, title):
    # norm_data shape: [2, T, 17]
    c0 = norm_data[0, frame_idx, :]
    c1 = norm_data[1, frame_idx, :]

    ax.scatter(c1, -c0, c="blue", s=30)

    for i, j in EDGES:
        ax.plot([c1[i], c1[j]], [-c0[i], -c0[j]], color="blue", linewidth=1.5)

    ax.set_title(title)
    ax.axis("equal")
    ax.grid(True, linestyle="--", alpha=0.3)

def main():
    raw_data = np.load(RAW_PATH)
    norm_data = np.load(NORM_PATH)

    print("Raw shape:", raw_data.shape)
    print("Norm shape:", norm_data.shape)

    raw_frames = [0, min(50, raw_data.shape[0] - 1), min(100, raw_data.shape[0] - 1)]
    norm_frames = [0, min(50, norm_data.shape[1] - 1), min(100, norm_data.shape[1] - 1)]

    fig, axes = plt.subplots(2, 3, figsize=(15, 10))

    for col, frame_idx in enumerate(raw_frames):
        plot_raw_frame(
            axes[0, col],
            raw_data,
            frame_idx,
            f"Raw skeleton - frame {frame_idx}",
        )

    for col, frame_idx in enumerate(norm_frames):
        plot_norm_frame(
            axes[1, col],
            norm_data,
            frame_idx,
            f"Normalized skeleton - frame {frame_idx}",
        )

    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    main()