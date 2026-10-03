# AI Routine Import Runbook

This document covers setup, deployment, and verification for the AI Routine Importer feature.

---

## Architecture Overview

The AI Routine Importer converts workout photos (gym journals, whiteboards, screenshots) and raw text into structured GymLog routines.

1. **Client (`lib/features/routines/`)**: Captures or compresses images (< 1600px, JPEG 85) and posts to the Supabase Edge Function `ai-import-routine`.
2. **Backend (`supabase/functions/ai-import-routine/`)**: Calls Google Gemini 2.0 Flash with a strict `responseSchema` and system prompt. GEMINI_API_KEY stays securely on the server.
3. **Reconciler (`lib/features/routines/domain/ai_exercise_reconciler.dart`)**: Matches raw names to catalog exercises via alias dictionary and `ExerciseResolver` (`_kFuzzyMatchFloor = 0.6`), preserving equipment isolation.
4. **Review Screen (`lib/features/routines/presentation/screens/ai_routine_review_screen.dart`)**: Human-in-the-loop review with Verified, Suggested, and Custom badges.
5. **Persistence (`RoutinesDao.saveReconciledRoutine`)**: Atomic Drift transaction creating custom exercises and routine days/exercises together.

---

## Edge Function Deployment

### 1. Set the Gemini API Secret
Obtain a free API key from [Google AI Studio](https://aistudio.google.com/app/apikey).
```bash
supabase secrets set GEMINI_API_KEY="your_api_key_here"
```

### 2. Deploy the Edge Function
```bash
supabase functions deploy ai-import-routine
```

---

## Verification & Curl Testing

### Test with Text Input:
```bash
curl -i --location --request POST 'https://<project-ref>.supabase.co/functions/v1/ai-import-routine' \
  --header 'Authorization: Bearer <anon-key>' \
  --header 'Content-Type: application/json' \
  --data '{
    "text": "Push Day:\nIncline DB Bench 3x8-10 @ 30kg\nFlat Barbell Bench 4x6\nLateral Raises 3x15"
  }'
```

### Expected JSON Output:
```json
{
  "routineName": "Push Day",
  "days": [
    {
      "dayName": "Day 1 - Push",
      "exercises": [
        { "rawName": "Incline DB Bench", "sets": 3, "reps": "8-10", "weight": 30, "weightUnit": "kg" },
        { "rawName": "Flat Barbell Bench", "sets": 4, "reps": "6", "weight": null, "weightUnit": null },
        { "rawName": "Lateral Raises", "sets": 3, "reps": "15", "weight": null, "weightUnit": null }
      ]
    }
  ]
}
```
