import urllib.request
import json

GITHUB_RELEASES_URL = "https://api.github.com/repos/Krsatvik1/KB/releases/latest"

def check_for_updates(current_version: str) -> dict | None:
    """
    Polls GitHub Releases API.
    Returns {'version': '1.x.x', 'url': '...'} if newer, else None.
    """
    try:
        req = urllib.request.Request(
            GITHUB_RELEASES_URL,
            headers={"User-Agent": "FlowDesk-Server"}
        )
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read())
        latest = data.get("tag_name", "").lstrip("v")
        url = data.get("html_url", "")
        if _is_newer(latest, current_version):
            return {"version": latest, "url": url}
    except Exception as e:
        print(f"Update check failed: {e}")
    return None

def _is_newer(latest: str, current: str) -> bool:
    def parts(v):
        try:
            return [int(x) for x in v.split(".")]
        except Exception:
            return [0]
    return parts(latest) > parts(current)
