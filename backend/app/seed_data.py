from sqlalchemy.orm import Session

from app.models.dance_style import DanceStyle
from app.models.dance_move import DanceMove


def seed_database(db: Session):
    existing_styles = db.query(DanceStyle).count()
    if existing_styles > 0:
        return

    house = DanceStyle(
        name="House",
        description="Groove-based movement focused on rhythm, bounce, and flow.",
    )

    middle_hip_hop = DanceStyle(
        name="Middle Hip-Hop",
        description="Sharp, grounded, and musical moves with strong control.",
    )

    street_jazz = DanceStyle(
        name="Street Jazz",
        description="Expressive, stylish movement with attitude and clean lines.",
    )

    db.add_all([house, middle_hip_hop, street_jazz])
    db.commit()

    db.refresh(house)
    db.refresh(middle_hip_hop)
    db.refresh(street_jazz)

    moves = [
        DanceMove(
            style_id=house.id,
            name="Side Kick",
            description="A groove step with a rhythmic side leg extension.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/house/side_kick.mp4",
        ),
        DanceMove(
            style_id=house.id,
            name="Sworl",
            description="A circular turning groove with relaxed upper body control.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/house/swirl.mp4",
        ),
        DanceMove(
            style_id=house.id,
            name="Farmer",
            description="A grounded house step built on weight shifts and timing.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/house/farmer.mp4",
        ),
        DanceMove(
            style_id=house.id,
            name="Shuffle",
            description="Quick sliding and switching footwork with continuous rhythm.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/house/shuffle.mp4",
        ),
        DanceMove(
            style_id=house.id,
            name="Heel Step",
            description="A heel-focused step with clean foot timing and soft groove.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/house/heel_step.mp4",
        ),
        DanceMove(
            style_id=middle_hip_hop.id,
            name="Rager Rabbit",
            description="A playful hip-hop groove with energetic rebound accents.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/middle_hip_hop/rager_rabbit.mp4",
        ),
        DanceMove(
            style_id=middle_hip_hop.id,
            name="Club",
            description="A compact social groove with strong pulse and attitude.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/middle_hip_hop/club.mp4",
        ),
        DanceMove(
            style_id=middle_hip_hop.id,
            name="Brooklyn Bounce",
            description="A bounce-based move driven by knees, torso, and groove.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/middle_hip_hop/brooklyn_bounce.mp4",
        ),
        DanceMove(
            style_id=middle_hip_hop.id,
            name="Running Man",
            description="An old-school step based on slide-and-step running motion.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/middle_hip_hop/running_man.mp4",
        ),
        DanceMove(
            style_id=middle_hip_hop.id,
            name="Popcorn",
            description="A reactive groove with quick explosive accents.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/middle_hip_hop/popcorn.mp4",
        ),
        DanceMove(
            style_id=street_jazz.id,
            name="Positions des pieds",
            description="A foundation exercise for foot placement and alignment.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/street_jazz/positions_des_pieds.mp4",
        ),
        DanceMove(
            style_id=street_jazz.id,
            name="Plié",
            description="A controlled knee bend used to build balance and softness.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/street_jazz/pile.mp4",
        ),
        DanceMove(
            style_id=street_jazz.id,
            name="Jump",
            description="A basic elevation move with controlled take-off and landing.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/street_jazz/jump.mp4",
        ),
        DanceMove(
            style_id=street_jazz.id,
            name="Passé Balance",
            description="A balance position useful for posture and control.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/street_jazz/passe_balance.mp4",
        ),
        DanceMove(
            style_id=street_jazz.id,
            name="Paddbre",
            description="A traveling transition step connecting movements smoothly.",
            difficulty="Beginner",
            tutorial_video_path="assets/videos/street_jazz/paddbre.mp4",
        ),
    ]

    db.add_all(moves)
    db.commit()