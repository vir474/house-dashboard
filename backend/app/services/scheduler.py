from datetime import datetime, timedelta


FREQUENCY_DAYS: dict[str, int] = {
    "weekly": 7,
    "monthly": 30,
    "quarterly": 90,
    "twice_yearly": 182,
    "annually": 365,
}

SEASON_MONTH: dict[str, int] = {
    "spring": 4,
    "summer": 7,
    "fall": 10,
    "winter": 1,
}


def compute_next_due(frequency: str, season: str | None, from_date: datetime | None = None) -> datetime:
    base = from_date or datetime.utcnow()

    if season:
        target_month = SEASON_MONTH[season]
        candidate = base.replace(month=target_month, day=1, hour=8, minute=0, second=0, microsecond=0)
        if candidate <= base:
            candidate = candidate.replace(year=candidate.year + 1)
        return candidate

    days = FREQUENCY_DAYS.get(frequency, 365)
    return base + timedelta(days=days)
