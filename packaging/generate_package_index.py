#!/usr/bin/env python3
"""Generate an Arduino Boards Manager tool-only package index."""

import argparse
import glob
import json
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True, help="owner/repo")
    parser.add_argument("--tag", required=True)
    parser.add_argument("--tool-version", required=True)
    parser.add_argument("--metadata-glob", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    systems = []
    for metadata_path in sorted(glob.glob(args.metadata_glob, recursive=True)):
        with open(metadata_path, "r", encoding="utf-8") as f:
            item = json.load(f)
        filename = item["archiveFileName"]
        item["url"] = (
            f"https://github.com/{args.repo}/releases/download/"
            f"{args.tag}/{filename}"
        )
        systems.append(item)

    if not systems:
        raise SystemExit("no metadata files matched")

    index = {
        "packages": [
            {
                "name": "lopple",
                "maintainer": "lopple",
                "websiteURL": f"https://github.com/{args.repo}",
                "email": "",
                "help": {"online": f"https://github.com/{args.repo}/issues"},
                "platforms": [],
                "tools": [
                    {
                        "name": "riscv-none-embed-gcc",
                        "version": args.tool_version,
                        "systems": systems,
                    }
                ],
            }
        ]
    }

    output_path = Path(args.output)
    output_path.write_text(
        json.dumps(index, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
