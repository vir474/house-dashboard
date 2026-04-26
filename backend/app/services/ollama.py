import json
import logging

import httpx

from app.core.config import settings
from app.models.house import House

logger = logging.getLogger(__name__)

PROMPT_TEMPLATE = """You are a house maintenance expert. Given the home profile below, suggest 3-5 additional maintenance tasks that a standard checklist might miss. Consider the home's age, location, features, and any risks specific to this property.

Home profile:
- Year built: {year_built}
- ZIP code: {zip_code}
- HVAC type: {hvac_type}
- Roof material: {roof_material}
- Has fireplace: {has_fireplace}
- Has pool: {has_pool}
- Has basement: {has_basement}
- Water heater age (years): {water_heater_age}

Respond ONLY with a JSON array. No explanation, no markdown, just the array.
Format: [{{"name": "task name", "frequency": "monthly|quarterly|annually|twice_yearly", "season": "spring|summer|fall|winter|null", "reason": "one sentence why"}}]"""


async def suggest_tasks(house: House) -> list[dict]:
    prompt = PROMPT_TEMPLATE.format(
        year_built=house.year_built or "unknown",
        zip_code=house.zip_code or "unknown",
        hvac_type=house.hvac_type or "unknown",
        roof_material=house.roof_material or "unknown",
        has_fireplace=house.has_fireplace,
        has_pool=house.has_pool,
        has_basement=house.has_basement,
        water_heater_age=house.water_heater_age or "unknown",
    )

    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{settings.OLLAMA_URL}/api/generate",
                json={
                    "model": settings.OLLAMA_MODEL,
                    "prompt": prompt,
                    "format": "json",
                    "stream": False,
                },
            )
            response.raise_for_status()
            raw = response.json().get("response", "[]")
            suggestions = json.loads(raw)
            return [{**s, "source": "llm"} for s in suggestions if isinstance(s, dict)]
    except Exception as e:
        logger.warning("Ollama suggestion failed: %s", e)
        return []
