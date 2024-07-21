from typing import Literal
import cloudscraper
from requests import Response
import sys

def scrape_listings(raw_release_id: bytes | int) -> tuple[Literal["ok"], str] | tuple[Literal["error"], int]:
    release_id: int
    if isinstance(raw_release_id, bytes):
        release_id = int(raw_release_id.decode())
    elif isinstance(raw_release_id, int):
        release_id = raw_release_id
    else:
        raise TypeError("Invalid release ID type")
    url: str = f"https://www.discogs.com/sell/release/{release_id}"
    scraper = cloudscraper.create_scraper()
    result: Response = scraper.get(url, params={"limit": 250})
    
    if result.ok:
        return "ok", result.text
    return "error", result.status_code
    