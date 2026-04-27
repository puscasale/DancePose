import os
import time
from google import genai

_client = None

MODEL_CANDIDATES = [
    "gemini-2.5-flash-lite",
    "gemini-2.5-flash",
    "gemini-2.0-flash",
]


def _get_client():
    global _client
    if _client is None:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY is not set")
        _client = genai.Client(api_key=api_key)
    return _client


def _parse_feedback_text(text: str) -> dict:
    summary = "The execution is generally recognizable, with one body region performing more consistently than the other."
    strengths = "The stronger segment of the body contributes most to the clarity of the movement. The best moment suggests that the movement can be executed more cleanly."
    improvements = "The weaker body region should be the main focus in future practice. Greater consistency is needed around the weakest moment."

    try:
        parts = text.split("STRENGTHS:")
        summary_part = parts[0].replace("SUMMARY:", "").strip()

        rest = parts[1].split("IMPROVEMENTS:")
        strengths_part = rest[0].strip()
        improvements_part = rest[1].strip()

        summary = summary_part or summary
        strengths = strengths_part or strengths
        improvements = improvements_part or improvements
    except Exception:
        if text.strip():
            summary = text.strip()

    return {
        "summary": summary,
        "strengths": strengths,
        "improvements": improvements,
    }


def _fallback_feedback(
    predicted_label: str,
    overall_score: float,
    arms_score: float,
    legs_score: float,
    problematic_joints_text: str | None,
) -> dict:
    stronger_area = "lower body" if legs_score >= arms_score else "upper body"
    weaker_area = "upper body" if legs_score >= arms_score else "lower body"

    summary = (
        f"The movement is recognizable as {predicted_label}, with the {stronger_area} showing better consistency than the {weaker_area}. "
        f"The main opportunity for improvement is to make the weaker region more controlled and more stable throughout the sequence."
    )

    strengths = (
        f"The {stronger_area} contributes most to the clarity of the execution. "
        "The best detected moment shows that the movement can be performed with better structure and control."
    )

    improvements = (
        f"Practice should focus on the {weaker_area}, especially around the least stable part of the sequence. "
        f"Pay extra attention to these joints: {problematic_joints_text or 'the most unstable joints'}."
    )

    return {
        "summary": summary,
        "strengths": strengths,
        "improvements": improvements,
    }


def generate_llm_feedback(
    predicted_label: str,
    overall_score: float,
    arms_score: float,
    legs_score: float,
    best_novice_second: float | None,
    worst_novice_second: float | None,
    problematic_joints_text: str | None,
) -> dict:
    client = _get_client()

    stronger_area = "legs" if legs_score >= arms_score else "arms"
    weaker_area = "arms" if legs_score >= arms_score else "legs"

    prompt = f"""
You are writing feedback for a dance-movement evaluation app.

Your tone must be:
- professional
- concise
- technical but easy to understand
- useful for practice

Use only the data below.

DATA:
- Predicted move: {predicted_label}
- Overall score: {overall_score:.1f}/10
- Arms score: {arms_score:.1f}/10
- Legs score: {legs_score:.1f}/10
- Stronger area: {stronger_area}
- Weaker area: {weaker_area}
- Best moment time: {best_novice_second if best_novice_second is not None else "N/A"} seconds
- Weakest moment time: {worst_novice_second if worst_novice_second is not None else "N/A"} seconds
- Problematic joints: {problematic_joints_text or "N/A"}

Important:
- Do NOT repeat the raw numbers in every sentence.
- Do NOT restate obvious information like "the legs score is higher".
- Do NOT use exaggerated praise.
- Do NOT mention missing data.
- Focus on what the user should understand and improve.
- The feedback should feel like a concise coach note, not a long report.

Return exactly this format:

SUMMARY:
Write 2 short sentences. Explain the overall quality of execution and where the main imbalance is.

STRENGTHS:
Write exactly 2 short sentences in one paragraph. Mention what currently works best and what the best moment suggests.

IMPROVEMENTS:
Write exactly 2 short sentences in one paragraph. Mention the main technical focus and naturally refer to the problematic joints if useful.
""".strip()

    errors = []

    for model_name in MODEL_CANDIDATES:
        for attempt in range(2):
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=prompt,
                )
                text = (response.text or "").strip()
                if text:
                    return _parse_feedback_text(text)
            except Exception as e:
                errors.append(f"{model_name} attempt {attempt + 1}: {e}")
                time.sleep(2)

    print("[LLM FEEDBACK FALLBACK] Gemini failed:")
    for err in errors:
        print(" ", err)

    return _fallback_feedback(
        predicted_label=predicted_label,
        overall_score=overall_score,
        arms_score=arms_score,
        legs_score=legs_score,
        problematic_joints_text=problematic_joints_text,
    )