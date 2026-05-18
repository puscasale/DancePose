from app.ai.llm_feedback import _fallback_feedback, _parse_feedback_text


def test_fallback_feedback_returns_expected_keys():
    result = _fallback_feedback(
        predicted_label="House Basic Step",
        overall_score=7.5,
        arms_score=6.5,
        legs_score=8.0,
        problematic_joints_text="left wrist, right elbow",
    )

    assert "summary" in result
    assert "strengths" in result
    assert "improvements" in result

    assert isinstance(result["summary"], str)
    assert isinstance(result["strengths"], str)
    assert isinstance(result["improvements"], str)

    assert len(result["summary"]) > 0
    assert len(result["strengths"]) > 0
    assert len(result["improvements"]) > 0


def test_parse_feedback_text_valid_format():
    text = """
SUMMARY:
The movement is recognizable. The lower body is more stable than the upper body.

STRENGTHS:
The legs support the rhythm well. The best moment shows good coordination.

IMPROVEMENTS:
Focus on arm control. Pay attention to the wrists and elbows.
"""

    result = _parse_feedback_text(text)

    assert result["summary"].startswith("The movement is recognizable")
    assert "legs" in result["strengths"]
    assert "arm control" in result["improvements"]


def test_parse_feedback_text_invalid_format_uses_text_as_summary():
    text = "This is a simple feedback message."

    result = _parse_feedback_text(text)

    assert result["summary"] == "This is a simple feedback message."
    assert len(result["strengths"]) > 0
    assert len(result["improvements"]) > 0