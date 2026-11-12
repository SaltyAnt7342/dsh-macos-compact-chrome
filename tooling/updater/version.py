"""Version helpers for the DSH compact-sidebar updater."""

import re
import sys


def version_key(value: str) -> tuple[int, int, int, int, int]:
    """Return a sortable key for a DSH release version such as 0.2.2-rc.1."""
    match = re.match(r"^(\d+)\.(\d+)\.(\d+)(?:[-.](alpha|beta|rc)[.-]?(\d+))?$", value)
    if match is None:
        return (0, 0, 0, 0, 0)
    stage = {"alpha": 0, "beta": 1, "rc": 2}.get(match.group(4), 3)
    return (int(match.group(1)), int(match.group(2)), int(match.group(3)), stage, int(match.group(5) or 999))


def main() -> int:
    mode = sys.argv[1]
    if mode == "latest":
        tags = [line.strip()[5:] for line in sys.stdin if line.strip().startswith("dsh-v")]
        if not tags:
            return 1
        print(f"dsh-v{max(tags, key=version_key)}")
        return 0
    if mode == "gt":
        print("yes" if version_key(sys.argv[2]) > version_key(sys.argv[3]) else "no")
        return 0
    raise SystemExit(f"unknown mode {mode}")


if __name__ == "__main__":
    raise SystemExit(main())
