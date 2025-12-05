import json
from pathlib import Path

INPUT = Path("dataV5.json")
OUT_JOBS = Path("dataV6.json")
OUT_SOFT = Path("softSkills.json")
OUT_HARD = Path("hardSkills.json")

SOFT_MAP = [
    ("analyticalReasoningAndProblemSolving", "analyticalReasoning", "Problem Solving"),
    ("creativityAndInsightfulThinking", "creativity", "Creativity"),
    ("communicationAndNetworking", "communication", "Communication"),
    ("leadershipAndInfluence", "leadership", "Leadership"),
    ("courageAndRiskTolerance", "riskTolerance", "Risk Tolerance"),
    ("spacialNavigation", "spatialNavigation", "Navigation"),
    ("carefulnessAndAttentionToDetail", "attentionToDetail", "Attention To Detail"),
    ("perseveranceAndGrit", "perseverance", "Perseverance"),
    ("tinkeringAndFingerPrecision", "tinkering", "Tinkering"),
    ("physicalStrength", "strength", "Strength"),
    ("coordinationAndBalance", "coordination", "Coordination"),
    ("resilienceAndEndurance", "endurance", "Endurance"),
]

# Canonicalize hard skills
def canonical_hard_id(name: str, kind: str) -> str:
    # kind ∈ {"software","license","certification","portfolio"}
    n = name.strip()
    if kind == "license":
        if n in ("B", "Driver's License"): return "drivers"
        if n in ("CE", "CDL"): return "cdl"
        if n in ("RN", "Nurse", "Nurse License"): return "rn"
        if n in ("EL", "Electrician License"): return "electrician"
        if n in ("PL", "Plumber License"): return "plumber"
        return n.lower().replace(" ", "").replace("&", "and")
    if kind == "software":
        if n == "Office": return "office"
        if n == "Programming": return "programming"
        if n == "Photo/Video Editing": return "mediaEditing"
        if n == "Game Engine": return "gameEngine"
        return n.lower().replace(" ", "")
    if kind == "certification":
        if n == "Security": return "security"
        return n.lower().replace(" ", "")
    if kind == "portfolio":
        if n == "App": return "appPortfolio"
        if n == "Game": return "gamePortfolio"
        if n == "Website": return "websitePortfolio"
        if n == "Library": return "libraryPortfolio"
        if n == "Paper": return "paperPortfolio"
        if n == "Presentation": return "presentationPortfolio"
        return n.lower().replace(" ", "") + "Portfolio"
    return n.lower()

def hard_meta(name: str, kind: str):
    id_ = canonical_hard_id(name, kind)
    # Provide friendly names
    friendly = {
        "office": "Office Suite",
        "programming": "Programming",
        "mediaEditing": "Photo & Video Editing",
        "gameEngine": "Game Engine",
        "rn": "Registered Nurse License",
        "drivers": "Driver’s License",
        "cdl": "Commercial Driver’s License",
        "electrician": "Electrician License",
        "plumber": "Plumber License",
        "security": "Security Awareness",
        "appPortfolio": "App",
        "gamePortfolio": "Game",
        "websitePortfolio": "Website",
        "libraryPortfolio": "Library",
        "paperPortfolio": "Paper",
        "presentationPortfolio": "Presentation",
    }.get(id_, name)
    return {
        "id": id_,
        "name": friendly,
        "type": kind,
        "description": None,
        "asset": None
    }

def migrate():
    data = json.loads(Path(INPUT).read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError("Expected list root")

    # Build registries
    soft_registry = [
        { "id": new_id, "name": display, "description": None, "asset": None }
        for old_key, new_id, display in SOFT_MAP
    ]
    hard_seen = {}
    jobs_out = []

    for job in data:
        req = job.get("requirements", {})
        edu = req.get("education", {})
        soft = req.get("softSkills", {})
        hard = req.get("hardSkills", {}) or {}

        # Collect hard registry entries
        for kind in ("certifications", "licenses", "software", "portfolio"):
            items = hard.get(kind, []) or []
            kind_type = {
                "certifications": "certification",
                "licenses": "license",
                "software": "software",
                "portfolio": "portfolio"
            }[kind]
            for name in items:
                meta = hard_meta(name, kind_type)
                hard_seen[meta["id"]] = meta

        # Build V6 soft refs
        soft_refs = []
        for old_key, new_id, _ in SOFT_MAP:
            if old_key in soft:
                soft_refs.append({ "id": new_id, "level": int(soft[old_key]) })

        # Build V6 hard refs (level 1 default)
        hard_refs = []
        for kind in ("certifications", "licenses", "software", "portfolio"):
            items = hard.get(kind, []) or []
            kind_type = {
                "certifications": "certification",
                "licenses": "license",
                "software": "software",
                "portfolio": "portfolio"
            }[kind]
            for name in items:
                hard_refs.append({ "id": canonical_hard_id(name, kind_type), "level": 1 })

        jobs_out.append({
            "id": job["id"],
            "category": job["category"],
            "income": job["income"],
            "summary": job["summary"],
            "icon": job["icon"],
            "requirements": {
                "education": {
                    "minEQF": edu.get("minEQF", 0),
                    "acceptedProfiles": edu.get("acceptedProfiles")
                },
                "softSkills": soft_refs,
                "hardSkills": hard_refs
            },
            "version": 6
        })

    # Write outputs
    Path(OUT_SOFT).write_text(json.dumps(soft_registry, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    hard_registry = list(hard_seen.values())
    Path(OUT_HARD).write_text(json.dumps(hard_registry, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    Path(OUT_JOBS).write_text(json.dumps(jobs_out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Wrote:", OUT_SOFT, OUT_HARD, OUT_JOBS)

if __name__ == "__main__":
    migrate()
