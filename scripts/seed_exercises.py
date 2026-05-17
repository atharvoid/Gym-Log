import json, sqlite3, urllib.request
from pathlib import Path

# Correct URL for free-exercise-db compiled dist
URL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"

def build():
    out = Path("assets/db/exercises.db")
    out.parent.mkdir(parents=True, exist_ok=True)

    print("Downloading exercises...")
    try:
        with urllib.request.urlopen(URL) as r:
            exercises = json.loads(r.read().decode())
        print(f"Fetched {len(exercises)} exercises")
    except Exception as e:
        print(f"ERROR: {e}")
        return

    conn = sqlite3.connect(out)
    cur = conn.cursor()

    cur.execute("DROP TABLE IF EXISTS exercises")
    cur.execute("""
        CREATE TABLE exercises (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            body_part TEXT NOT NULL,
            equipment TEXT NOT NULL,
            target TEXT NOT NULL,
            gif_url TEXT NOT NULL,
            secondary_muscles TEXT NOT NULL,
            instructions TEXT NOT NULL
        )
    """)
    cur.execute("CREATE INDEX idx_body_part ON exercises(body_part)")
    cur.execute("CREATE INDEX idx_equipment ON exercises(equipment)")
    cur.execute("CREATE INDEX idx_target ON exercises(target)")

    rows = []
    for i, ex in enumerate(exercises):
        name = ex.get('name', '')
        body_part = ex.get('category', 'other')
        equipment = (ex.get('equipment') or ['bodyweight'])[0]
        target = (ex.get('primaryMuscles') or ['other'])[0]
        gif_url = f"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{ex.get('id','')}/0.jpg"
        secondary = json.dumps(ex.get('secondaryMuscles', []))
        instructions = json.dumps(ex.get('instructions', []))
        rows.append((i + 1, name, body_part, equipment, target, gif_url, secondary, instructions))

    cur.executemany("INSERT INTO exercises VALUES (?,?,?,?,?,?,?,?)", rows)
    conn.commit()
    conn.close()
    print(f"Done. Seeded {len(rows)} exercises → {out} ({out.stat().st_size // 1024}KB)")

if __name__ == "__main__":
    build()