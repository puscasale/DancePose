from app.ai.llm_feedback import generate_llm_feedback

result = generate_llm_feedback(
    predicted_label="HO_CH03",
    overall_score=8.1,
    arms_score=5.4,
    legs_score=7.8,
    best_novice_second=11.37,
    worst_novice_second=10.88,
    problematic_joints_text="left_elbow, right_wrist, left_shoulder",
)

print("\nSUMMARY:\n", result["summary"])
print("\nSTRENGTHS:\n", result["strengths"])
print("\nIMPROVEMENTS:\n", result["improvements"])