from app.models.house import House

MAINTENANCE_RULES: list[dict] = [
    # Universal tasks — every house
    {"condition": lambda h: True, "tasks": [
        {"name": "Test smoke & CO detectors", "frequency": "monthly", "season": None},
        {"name": "Check & replace HVAC filter", "frequency": "monthly", "season": None},
        {"name": "Clean dryer vent", "frequency": "quarterly", "season": None},
        {"name": "Inspect caulk & weatherstripping", "frequency": "quarterly", "season": None},
        {"name": "Plumbing inspection for leaks", "frequency": "annually", "season": "spring"},
        {"name": "Flush water heater & test pressure valve", "frequency": "annually", "season": "spring"},
        {"name": "Deep clean kitchen appliances", "frequency": "quarterly", "season": None},
    ]},
    # HVAC
    {"condition": lambda h: h.hvac_type in ("central", "heat_pump"), "tasks": [
        {"name": "AC tune-up & refrigerant check", "frequency": "annually", "season": "spring"},
        {"name": "Furnace inspection", "frequency": "annually", "season": "fall"},
    ]},
    # Roof & gutters
    {"condition": lambda h: h.roof_material is not None, "tasks": [
        {"name": "Gutter cleaning", "frequency": "twice_yearly", "season": "spring"},
        {"name": "Gutter cleaning", "frequency": "twice_yearly", "season": "fall"},
        {"name": "Roof inspection", "frequency": "annually", "season": "fall"},
    ]},
    {"condition": lambda h: h.roof_material == "asphalt", "tasks": [
        {"name": "Inspect & replace damaged shingles", "frequency": "annually", "season": "spring"},
    ]},
    # Fireplace / chimney
    {"condition": lambda h: h.has_fireplace, "tasks": [
        {"name": "Chimney sweep & inspection", "frequency": "annually", "season": "fall"},
    ]},
    # Pool
    {"condition": lambda h: h.has_pool, "tasks": [
        {"name": "Pool equipment & filter inspection", "frequency": "monthly", "season": None},
        {"name": "Pool winterization", "frequency": "annually", "season": "fall"},
        {"name": "Pool opening & chemical balance", "frequency": "annually", "season": "spring"},
    ]},
    # Basement / crawl space
    {"condition": lambda h: h.has_basement, "tasks": [
        {"name": "Inspect basement for moisture & cracks", "frequency": "annually", "season": "spring"},
    ]},
    # Aging water heater
    {"condition": lambda h: h.water_heater_age is not None and h.water_heater_age >= 8, "tasks": [
        {"name": "Water heater professional inspection", "frequency": "annually", "season": "spring"},
    ]},
    # Older homes
    {"condition": lambda h: h.year_built is not None and h.year_built < 1980, "tasks": [
        {"name": "Inspect pipes for corrosion or lead", "frequency": "annually", "season": "spring"},
    ]},
]


def generate_tasks_from_rules(house: House) -> list[dict]:
    tasks = []
    seen = set()
    for rule in MAINTENANCE_RULES:
        if rule["condition"](house):
            for task in rule["tasks"]:
                key = (task["name"], task.get("season"))
                if key not in seen:
                    seen.add(key)
                    tasks.append({**task, "source": "rule", "reason": None})
    return tasks
