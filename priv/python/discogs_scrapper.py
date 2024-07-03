import cloudscraper
from requests import Response
import sys

def scrape_listings(release_id: int) -> tuple[int, str | None]:
    url: str = f"https://www.discogs.com/sell/release/{release_id}"
    scraper = cloudscraper.create_scraper()
    result: Response = scraper.get('https://www.discogs.com/sell/release/16054318', params={"limit": 250})
    
    if result.ok:
        return result.status_code, result.text
    return result.status_code, None
    