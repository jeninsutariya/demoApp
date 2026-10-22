#!/usr/bin/env python3
"""Fetch an app's public App Store reviews from Apple's official customer
reviews RSS feed and append them to replica/reviews.csv. Standard library only.

    python3 scripts/fetch_app_store_reviews.py                 # Meowdoku!, us gb ca au
    python3 scripts/fetch_app_store_reviews.py --app 6761760135 --countries us,gb --pages 10

Text is copied exactly: the review's title, a newline, then its body. Each
row's url points at the app's reviews page for that country, with the review
id as the fragment (the App Store has no per-review pages). Rows already in
the CSV (same review id) are skipped, so it's safe to re-run.

Needs network access to itunes.apple.com.
"""
import argparse
import csv
import json
import os
import sys
import urllib.error
import urllib.request

FEED = "https://itunes.apple.com/{cc}/rss/customerreviews/page={page}/id={app}/sortBy=mostRecent/json"


def label(obj, *keys):
    for k in keys:
        if not isinstance(obj, dict):
            return ""
        obj = obj.get(k, {})
    return obj.get("label", "") if isinstance(obj, dict) else ""


def parse_feed(data, app, cc):
    """Rows from one feed page. The first entry can be the app itself (no rating)."""
    entries = data.get("feed", {}).get("entry", [])
    if isinstance(entries, dict):
        entries = [entries]
    rows = []
    for e in entries:
        rating = label(e, "im:rating")
        body = label(e, "content")
        rid = label(e, "id")
        if not rating or not body or not rid:
            continue
        title = label(e, "title")
        rows.append({
            "source": "app-store-%s" % cc,
            "url": "https://apps.apple.com/%s/app/id%s?see-all=reviews#review-%s" % (cc, app, rid),
            "date": label(e, "updated")[:10],
            "rating": rating,
            "text": (title + "\n" + body) if title else body,
        })
    return rows


def fetch(app, cc, page):
    req = urllib.request.Request(FEED.format(cc=cc, page=page, app=app), headers={"User-Agent": "replica-research/1.0"})
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.load(r)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--app", default="6761760135")
    ap.add_argument("--countries", default="us,gb,ca,au")
    ap.add_argument("--pages", type=int, default=10, help="the feed serves at most 10 pages of 50")
    ap.add_argument("--csv", default=os.path.join(os.path.dirname(__file__), "..", "replica", "reviews.csv"))
    args = ap.parse_args()

    seen = set()
    if os.path.exists(args.csv):
        with open(args.csv, newline="", encoding="utf-8") as fh:
            seen = {row["url"] for row in csv.DictReader(fh)}
    new = []
    for cc in [c.strip() for c in args.countries.split(",") if c.strip()]:
        for page in range(1, args.pages + 1):
            try:
                rows = parse_feed(fetch(args.app, cc, page), args.app, cc)
            except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
                print("%s page %d: %s" % (cc, page, e), file=sys.stderr)
                break
            if not rows:
                break
            new += [r for r in rows if r["url"] not in seen]
            seen.update(r["url"] for r in rows)
    write_header = not os.path.exists(args.csv) or os.path.getsize(args.csv) == 0
    with open(args.csv, "a", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=["source", "url", "date", "rating", "text"])
        if write_header:
            w.writeheader()
        w.writerows(new)
    print("added %d reviews to %s" % (len(new), args.csv))
    return 0 if new else 1


if __name__ == "__main__":
    sys.exit(main())
