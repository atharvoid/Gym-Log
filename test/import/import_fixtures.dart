// Real sample exports used across the import tests. These mirror the two
// sheets in the reconciled "Hevy vs Strong CSV Format" spec: the SAME two
// workouts, one logged in Hevy (kg, comma) and one in Strong (lbs, semicolon).
// Importing either must yield the same kilogram volume (within lbs rounding).
//
// Verified totals: 2 sessions, 8 exercises, 22 sets.
//   Hevy   total volume = 9483.00 kg
//   Strong total volume ≈ 9481.31 kg  (Strong rounds lbs to 1 decimal)

/// Hevy export — comma-delimited, all text fields quoted, unit in the header
/// (`weight_kg`), 0-based `set_index`, dates like "30 Jun 2025, 19:56".
const hevySampleCsv = '''
"title","start_time","end_time","description","exercise_title","superset_id","exercise_notes","set_index","set_type","weight_kg","reps","distance_km","duration_seconds","rpe"
"Monday Chest Day","30 Jun 2025, 19:56","30 Jun 2025, 20:58","","Incline Bench Press (Dumbbell)","","",0,"normal",48,13,,,
"Monday Chest Day","30 Jun 2025, 19:56","30 Jun 2025, 20:58","","Incline Bench Press (Dumbbell)","","",1,"normal",60,13,,,
"Monday Chest Day","30 Jun 2025, 19:56","30 Jun 2025, 20:58","","Incline Bench Press (Dumbbell)","","",2,"normal",72,12,,,
"Monday Chest Day","30 Jun 2025, 19:56","30 Jun 2025, 20:58","","Bench Press (Dumbbell)","","",0,"normal",60,15,,,
"Monday Chest Day","30 Jun 2025, 19:56","30 Jun 2025, 20:58","","Bench Press (Dumbbell)","","",1,"normal",72,15,,,
"Monday Chest Day","30 Jun 2025, 19:56","30 Jun 2025, 20:58","","Lower Chest Fly","","",0,"normal",20,20,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Seated Overhead Press (Barbell)","","Warmup",0,"normal",20,15,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Seated Overhead Press (Barbell)","","Warmup",1,"normal",30,15,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Shoulder Press (Dumbbell)","","",0,"normal",44,15,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Triceps Pushdown","","",0,"normal",12.5,20,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Triceps Pushdown","","",1,"normal",20,20,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Triceps Pushdown","","",2,"normal",25,20,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Single Arm Lateral Raise (Cable)","","",0,"normal",5,15,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Single Arm Lateral Raise (Cable)","","",1,"normal",5,15,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Single Arm Lateral Raise (Cable)","","",2,"normal",7.5,12,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Single Arm Lateral Raise (Cable)","","",3,"normal",7.5,12,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Single Arm Lateral Raise (Cable)","","",4,"normal",7.5,13,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Single Arm Lateral Raise (Cable)","","",5,"normal",7.5,13,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Face Pull","","",0,"normal",17.5,20,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Face Pull","","",1,"normal",25,20,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Face Pull","","",2,"normal",30,20,,,
"Shoulders Day","28 Jun 2025, 19:34","28 Jun 2025, 20:36","Shoulder day hits different","Face Pull","","",3,"normal",30,10,,,''';

/// Strong export — semicolon-delimited, separate `Weight Unit` column (lbs),
/// 1-based `Set Order`, warmups flagged via `Notes = "Warmup"`, dates like
/// "2025-06-30 19:56:00".
const strongSampleCsv = '''
Date;Workout Name;Exercise Name;Set Order;Weight;Weight Unit;Reps;RPE;Distance;Distance Unit;Seconds;Notes;Workout Notes;Workout Duration
2025-06-30 19:56:00;Monday Chest Day;Incline Bench Press (Dumbbell);1;105.8;lbs;13;;0;mi.;0;;;62m
2025-06-30 19:56:00;Monday Chest Day;Incline Bench Press (Dumbbell);2;132.3;lbs;13;;0;mi.;0;;;62m
2025-06-30 19:56:00;Monday Chest Day;Incline Bench Press (Dumbbell);3;158.7;lbs;12;;0;mi.;0;;;62m
2025-06-30 19:56:00;Monday Chest Day;Bench Press (Dumbbell);1;132.3;lbs;15;;0;mi.;0;;;62m
2025-06-30 19:56:00;Monday Chest Day;Bench Press (Dumbbell);2;158.7;lbs;15;;0;mi.;0;;;62m
2025-06-30 19:56:00;Monday Chest Day;Lower Chest Fly;1;44.1;lbs;20;;0;mi.;0;;;62m
2025-06-28 19:34:00;Shoulders Day;Seated Overhead Press (Barbell);1;44.1;lbs;15;;0;mi.;0;Warmup;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Seated Overhead Press (Barbell);2;66.1;lbs;15;;0;mi.;0;Warmup;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Shoulder Press (Dumbbell);1;97.0;lbs;15;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Triceps Pushdown;1;27.6;lbs;20;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Triceps Pushdown;2;44.1;lbs;20;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Triceps Pushdown;3;55.1;lbs;20;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Single Arm Lateral Raise (Cable);1;11.0;lbs;15;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Single Arm Lateral Raise (Cable);2;11.0;lbs;15;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Single Arm Lateral Raise (Cable);3;16.5;lbs;12;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Single Arm Lateral Raise (Cable);4;16.5;lbs;12;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Single Arm Lateral Raise (Cable);5;16.5;lbs;13;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Single Arm Lateral Raise (Cable);6;16.5;lbs;13;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Face Pull;1;38.6;lbs;20;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Face Pull;2;55.1;lbs;20;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Face Pull;3;66.1;lbs;20;;0;mi.;0;;Shoulder day hits different;62m
2025-06-28 19:34:00;Shoulders Day;Face Pull;4;66.1;lbs;10;;0;mi.;0;;Shoulder day hits different;62m''';
