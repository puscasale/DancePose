from pathlib import Path
import numpy as np

from app.ai.labels import INV_LABEL_MAP

EXPERT_2D_PATH = Path("ai_reference/EXPERT_2D_AUGMENTED")
EXPERT_VIDEO_FEATURES_DIR = Path("ai_reference/video_features_r3d18")

MAX_EXPERTS_PER_STEP = 3


def expert_step_label(file_path: str | Path) -> str:
    name = Path(file_path).name
    parts = name.split("_")
    style = parts[0][1:].upper()
    channel = parts[5].upper().replace(".NPY", "")
    return f"{style}_{channel}"


def expert_dancer_id(file_path: str | Path) -> str:
    parts = Path(file_path).name.split("_")
    return parts[3]


def is_expert_augmented(file_path: str | Path) -> bool:
    return "_aug_" in Path(file_path).stem.lower()


def get_expert_feature_base_name(file_path: str | Path) -> str:
    stem = Path(file_path).stem

    if " (" in stem:
        stem = stem.split(" (")[0]

    if "_aug_" in stem:
        stem = stem.split("_aug_")[0]

    parts = stem.split("_")

    style = None
    dancer = None
    music = None
    move = None

    for p in parts:
        p_low = p.lower()

        if p.startswith("g") and style is None:
            style = p
        elif p_low.startswith("d") and dancer is None and len(p) >= 2 and p[1:].isdigit():
            dancer = p
        elif p_low.startswith("m") and music is None:
            music = p
        elif p_low.startswith("ch") and move is None:
            move = p

    if None in [style, dancer, music, move]:
        return stem

    return f"{style}_{dancer}_{music}_{move}"


def get_expert_feature_path(expert_file: str | Path) -> Path:
    base = get_expert_feature_base_name(expert_file)
    return EXPERT_VIDEO_FEATURES_DIR / f"{base}.npy"


def get_expert_files_for_label(label: str) -> list[Path]:
    all_files = sorted(list(EXPERT_2D_PATH.glob("*.npy")))
    non_aug = [f for f in all_files if not is_expert_augmented(f)]

    matching = [f for f in non_aug if expert_step_label(f) == label]

    selected = []
    used_dancers = set()

    for ef in matching:
        dancer = expert_dancer_id(ef)
        if dancer not in used_dancers:
            selected.append(ef)
            used_dancers.add(dancer)
        if len(selected) == MAX_EXPERTS_PER_STEP:
            break

    return selected


def label_from_index(idx: int) -> str:
    return INV_LABEL_MAP[idx]