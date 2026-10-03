// GymLog AI Routine Importer Relay
//
// Extracts structured workout routines from images or text using Google Gemini 2.0 Flash.
// Runs as a Supabase Edge Function to keep the GEMINI_API_KEY secure on the server.
//
// Deploy:
//   supabase functions deploy ai-import-routine
//   supabase secrets set GEMINI_API_KEY=<gemini_api_key>

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");

const ROUTINE_JSON_SCHEMA = {
  type: "OBJECT",
  properties: {
    routineName: {
      type: "STRING",
      description: "Overall title for the workout or program. Prioritize the routine/split session name (e.g. 'Push #1', 'Upper A', 'Leg Day') over generic column headers or week numbers (e.g. 'Week 1'). If both exist, combine them like 'Push #1 (Week 1)'.",
    },
    days: {
      type: "ARRAY",
      description: "List of training days. If single workout, return exactly 1 day object.",
      items: {
        type: "OBJECT",
        properties: {
          dayName: {
            type: "STRING",
            description: "Name of the training day, e.g. 'Day 1 - Push', 'Upper Body', or 'Monday'",
          },
          exercises: {
            type: "ARRAY",
            items: {
              type: "OBJECT",
              properties: {
                rawName: {
                  type: "STRING",
                  description: "Clean exercise name with equipment (e.g. 'Cross-Body Triceps Extension', 'Bench Press', 'Cable Y-Raise'). Strip numbering, cues, and coach brands.",
                },
                sets: {
                  type: "INTEGER",
                  description: "Number of working sets if specified, or null if not explicitly mentioned",
                },
                reps: {
                  type: "STRING",
                  description: "Target reps or range, e.g. '8-10', '12', '30s HOLD', or null if unspecified",
                },
                weight: {
                  type: "NUMBER",
                  description: "Target weight value if specified, or null",
                },
                weightUnit: {
                  type: "STRING",
                  description: "'kg' or 'lbs', or null if unspecified",
                },
                restSeconds: {
                  type: "INTEGER",
                  description: "Rest interval in seconds if specified, or null",
                },
                notes: {
                  type: "STRING",
                  description: "Any exercise notes, superset tags (e.g. 'Superset A1'), form cues, tempo, dropset info, or coaching styles (e.g. 'N1-Style', 'Squeeze-Only')",
                },
              },
              required: ["rawName"],
            },
          },
        },
        required: ["dayName", "exercises"],
      },
    },
  },
  required: ["routineName", "days"],
};

const SYSTEM_INSTRUCTION = `You are an expert fitness data parser. Your task is to extract workout routines from images or raw text into a clean, structured JSON object adhering strictly to the provided schema.

Rules:
1. Extract ONLY exercises, sets, reps, and weights that are explicitly present or visible.
2. DO NOT invent, assume, or extrapolate exercises, sets, reps, or weights.
3. Routine Title: Always prioritize the split/routine title (e.g. 'Push #1', 'Pull #2', 'Leg Day') over week numbers ('Week 1'). If both are visible, name it 'Push #1 (Week 1)'.
4. Working Sets: If the source has separate 'Warm-Up Sets' and 'Working Sets' columns, extract ONLY the 'Working Sets' count for sets. If sets are not mentioned, set sets to null.
5. Clean Exercise Names (rawName):
   - Strip list numbers and superset tags (e.g., 'A1.', 'A2.', '1.', '2b.') from the exercise name. Record 'Superset A1' or 'Superset A2' in notes instead.
   - Strip coach/brand/system prefixes (e.g. 'N1-Style', 'RP-Style', 'Joe Bennett Style') from the name; record in notes.
   - Strip execution/ROM/tempo modifiers (e.g. 'Squeeze-Only', 'Stretch-Only', 'Paused', 'Slow Eccentric') from the name; record in notes.
   - Strip parenthetical muscle target annotations (e.g. '(Side Delt)', '(Upper Pec)') from the name. Keep equipment parentheticals like '(Dumbbell)', '(Cable)', '(Barbell)'.
   - Strip time durations from the name when present in reps (e.g., if exercise says 'Pec Static Stretch 30s' with reps '30s HOLD', the name is 'Pec Static Stretch').
6. Compound / Paired Exercises (+):
   - If an exercise entry combines two movements with '+' or '/' and paired reps (e.g., 'Squeeze-Only Triceps Pressdown + Stretch-Only Overhead Triceps Extension' with reps '8 + 8'), split them into TWO distinct sequential exercise objects!
   - Exercise 1: name 'Triceps Pressdown', reps '8', notes 'Squeeze-Only; Paired with Overhead Extension'.
   - Exercise 2: name 'Overhead Triceps Extension', reps '8', notes 'Stretch-Only; Paired with Triceps Pressdown'.
7. If reps are not explicitly mentioned, set reps to null.
8. If weight is not explicitly mentioned, set weight to null. If weight is specified in lbs, set weightUnit to 'lbs'. If in kg, set weightUnit to 'kg'.
9. If the input contains multiple training days (e.g. Day 1, Day 2 or Monday, Wednesday, Friday), split them into separate day objects. For a single workout session, return exactly 1 day object.`;

serve(async (req) => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Content-Type": "application/json",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers,
    });
  }

  if (!GEMINI_API_KEY) {
    return new Response(
      JSON.stringify({ error: "Relay not configured: GEMINI_API_KEY missing on server" }),
      { status: 500, headers }
    );
  }

  try {
    const body = await req.json();
    const { imageBase64, imageMimeType, text } = body;

    if (!imageBase64 && (!text || typeof text !== "string" || text.trim().length === 0)) {
      return new Response(
        JSON.stringify({ error: "Must provide either imageBase64 or text" }),
        { status: 400, headers }
      );
    }

    const contents: any[] = [];
    const parts: any[] = [];

    if (text && text.trim().length > 0) {
      parts.push({ text: `Workout routine text to parse:\n${text.trim()}` });
    }

    if (imageBase64) {
      parts.push({
        inlineData: {
          mimeType: imageMimeType || "image/jpeg",
          data: imageBase64,
        },
      });
      parts.push({
        text: "Please extract the workout routine shown in this image.",
      });
    }

    contents.push({ role: "user", parts });

    // Pinned model: gemini-2.5-flash
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        contents,
        systemInstruction: {
          parts: [{ text: SYSTEM_INSTRUCTION }],
        },
        generationConfig: {
          temperature: 0.1,
          responseMimeType: "application/json",
          responseSchema: ROUTINE_JSON_SCHEMA,
        },
      }),
    });

    if (!geminiResponse.ok) {
      if (geminiResponse.status === 429) {
        return new Response(
          JSON.stringify({
            error: "RATE_LIMITED",
            message: "AI import is temporarily busy. Please wait a minute and try again.",
          }),
          { status: 429, headers }
        );
      }
      const errorText = await geminiResponse.text();
      console.error("Gemini API error:", errorText);
      return new Response(
        JSON.stringify({ error: `Gemini API error: ${geminiResponse.statusText}` }),
        { status: geminiResponse.status, headers }
      );
    }

    const geminiResult = await geminiResponse.json();
    const candidateText =
      geminiResult.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!candidateText) {
      return new Response(
        JSON.stringify({ error: "No workout data recognized in the input" }),
        { status: 422, headers }
      );
    }

    const parsedJson = JSON.parse(candidateText);
    return new Response(JSON.stringify(parsedJson), {
      status: 200,
      headers,
    });
  } catch (err: any) {
    console.error("ai-import-routine exception:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers }
    );
  }
});
