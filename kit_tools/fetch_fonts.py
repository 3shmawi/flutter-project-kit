#!/usr/bin/env python3
"""Downloads Google Fonts as static TTFs into the app (no runtime fetching).

usage: fetch_fonts.py <assets/fonts dir> "<Latin family>" "<Arabic family>"
Prints the pubspec `fonts:` entries and license asset paths as JSON:
  {"families": [{"family": "Inter", "fonts": [{"asset": ..., "weight": 400}]}],
   "licenses": ["assets/fonts/Inter/LICENSE.txt"]}
Exit code 1 if nothing could be downloaded (the app then uses system fonts).
"""
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

UA = "curl/8.4.0"  # Google Fonts serves TrueType to non-browser agents
WEIGHT_SETS = ["400;500;600;700", "400;700", "400"]


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as res:
        return res.read()


def css_for(family):
    for weights in WEIGHT_SETS:
        q = urllib.parse.quote(family).replace("%20", "+")
        url = f"https://fonts.googleapis.com/css2?family={q}:wght@{weights}"
        try:
            return get(url).decode()
        except urllib.error.HTTPError:
            continue
    raise RuntimeError(f"'{family}' not found on Google Fonts")


def faces(css, prefer_arabic):
    """weight -> url; when a weight has several subsets, pick the right one."""
    out = {}
    for block in re.findall(r"@font-face\s*{([^}]*)}", css):
        weight = int(re.search(r"font-weight:\s*(\d+)", block).group(1))
        url = re.search(r"url\((https://[^)]+)\)", block).group(1)
        ranges = (re.search(r"unicode-range:\s*([^;]+);", block) or [None, ""])[1]
        has_arabic = "U+06" in ranges or not ranges
        has_latin = "U+0000" in ranges or not ranges
        wanted = has_arabic if prefer_arabic else has_latin
        if weight not in out or wanted:
            out[weight] = url
    return out


def license_text(family):
    slug = family.lower().replace(" ", "")
    for folder in ("ofl", "apache", "ufl"):
        for name in ("OFL.txt", "LICENSE.txt", "UFL.txt"):
            url = f"https://raw.githubusercontent.com/google/fonts/main/{folder}/{slug}/{name}"
            try:
                return get(url).decode()
            except urllib.error.URLError:
                continue
    return None


def main():
    out_dir, latin, arabic = sys.argv[1], sys.argv[2], sys.argv[3]
    result = {"families": [], "licenses": []}
    seen = set()
    for family, prefer_arabic in ((latin, False), (arabic, True)):
        if not family or family in seen:
            continue
        seen.add(family)
        folder = re.sub(r"[^A-Za-z0-9]", "", family)
        target = os.path.join(out_dir, folder)
        os.makedirs(target, exist_ok=True)
        try:
            fonts = []
            for weight, url in sorted(faces(css_for(family), prefer_arabic).items()):
                if not url.endswith((".ttf", ".otf")):
                    raise RuntimeError(f"{family}: got {url.rsplit('.', 1)[-1]}, need ttf")
                path = os.path.join(target, f"{folder}-{weight}.ttf")
                with open(path, "wb") as f:
                    f.write(get(url))
                fonts.append({"asset": path, "weight": weight})
            if not fonts:
                raise RuntimeError(f"{family}: no font files")
            result["families"].append({"family": family, "fonts": fonts})
            text = license_text(family)
            if text:
                lic = os.path.join(target, "LICENSE.txt")
                with open(lic, "w", encoding="utf-8") as f:
                    f.write(text)
                result["licenses"].append(lic)
            print(f"✓ {family}: weights {', '.join(str(x['weight']) for x in fonts)}", file=sys.stderr)
        except Exception as e:  # noqa: BLE001 — report and continue with system font
            print(f"! {family}: {e}", file=sys.stderr)
    print(json.dumps(result))
    sys.exit(0 if result["families"] else 1)


if __name__ == "__main__":
    main()
