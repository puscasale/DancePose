LABEL_TO_APP = {
    "HO_CH03": {"style_name": "House", "move_name": "Side Kick"},
    "HO_CH04": {"style_name": "House", "move_name": "Swirl"},
    "HO_CH06": {"style_name": "House", "move_name": "Farmer"},
    "HO_CH08": {"style_name": "House", "move_name": "Shuffle"},
    "HO_CH09": {"style_name": "House", "move_name": "Heel Step"},

    "MH_CH01": {"style_name": "Middle Hip-Hop", "move_name": "Rager Rabbit"},
    "MH_CH04": {"style_name": "Middle Hip-Hop", "move_name": "Club"},
    "MH_CH08": {"style_name": "Middle Hip-Hop", "move_name": "Brooklyn Bounce"},
    "MH_CH09": {"style_name": "Middle Hip-Hop", "move_name": "Running Man"},
    "MH_CH10": {"style_name": "Middle Hip-Hop", "move_name": "Popcorn"},

    "JS_CH02": {"style_name": "Street Jazz", "move_name": "Positions des pieds"},
    "JS_CH03": {"style_name": "Street Jazz", "move_name": "Plié"},
    "JS_CH04": {"style_name": "Street Jazz", "move_name": "Jump"},
    "JS_CH07": {"style_name": "Street Jazz", "move_name": "Passé Balance"},
    "JS_CH08": {"style_name": "Street Jazz", "move_name": "Paddbre"},
}

CLASS_NAMES = [
    "HO_CH03",
    "HO_CH04",
    "HO_CH06",
    "HO_CH08",
    "HO_CH09",
    "JS_CH02",
    "JS_CH03",
    "JS_CH04",
    "JS_CH07",
    "JS_CH08",
    "MH_CH01",
    "MH_CH04",
    "MH_CH08",
    "MH_CH09",
    "MH_CH10",
]

LABEL_MAP = {label: idx for idx, label in enumerate(CLASS_NAMES)}
INV_LABEL_MAP = {idx: label for label, idx in LABEL_MAP.items()}
NUM_CLASSES = len(CLASS_NAMES)