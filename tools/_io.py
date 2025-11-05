import os, sys, json


def open_file(path: str = "-", mode="r"):
    if path == "-":
        fd = os.dup(sys.stdout.fileno())
        f = os.fdopen(
            fd, "w", buffering=1, encoding=sys.stdout.encoding, errors="replace"
        )
        return f
    else:
        return open(path, mode)


def load_json(path: str = "-"):
    with open_file(path, "r") as f:
        data = json.load(f)
    return data
