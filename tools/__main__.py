import os, sys
import json


def open_file(path: str = "-", mode="r"):
    if path == "-":
        fd = os.dup(sys.stdout.fileno())
        f = os.fdopen(
            fd, "w", buffering=1, encoding=sys.stdout.encoding, errors="replace"
        )
        return f
    else:
        return open(path, mode)


def create_parser():
    import argparse

    p = argparse.ArgumentParser(prog="mygit", description="mini git-like tool")
    # p.add_argument("-v", "--verbose", action="count", default=0, help="increase verbosity")

    sub = p.add_subparsers(dest="command")
    s = sub.add_parser("init", help="initialize a repository")
    s.add_argument("--network", required=True)
    s.add_argument("--driver", required=True)
    s.add_argument("--subnet", required=True)
    s.add_argument("--gateway", required=True)
    s.add_argument(
        "--output", nargs="?", default=".env.json", help="target directory (default: .)"
    )
    s.set_defaults(func=conf_init)

    s = sub.add_parser("calculate", help="add file(s) to index")
    s.add_argument(
        "--input", nargs="?", default=".env.json", help="target directory (default: .)"
    )
    s.add_argument(
        "--output", nargs="?", default=".env.json", help="target directory (default: .)"
    )
    # s.add_argument("files", nargs="+", help="files to add")
    # s.add_argument("-f", "--force", action="store_true", help="allow adding otherwise ignored files")
    s.set_defaults(func=conf_calculate)
    return p


def main(argv: list[str] | None = None):
    parser = create_parser()
    args = parser.parse_args(argv)

    kwargs = vars(args)
    command = kwargs.pop("command", None)
    func = kwargs.pop("func", None)

    # サブコマンドなし（グローバルオプションだけ）の場合もヘルプ表示
    if command is None:
        parser.print_help()
        return

    return int(bool(func(**kwargs)))


def conf_init(network: str, driver: str, subnet: str, gateway: str, output: str):
    config = {
        "def": {
            "network": {
                "name": network,
                "driver": driver,
                "subnet": subnet,
                "gateway": gateway,
            },
            "kube": {
                "network": network,
                # "knative_address": "172.30.0.2",
                # "subnet": "172.30.0.0/16",
                # "gateway": "172.30.0.1",
                # "knative_alias": "172-30-0-2.sslip.io",
                # "external_host": "172.30.0.2",
                # "wildcarddomain": "sslip.io",
                # "external_domain": "172-30-0-2.sslip.io",
            },
            "minio": {
                "minio_root_user": "minioadmin",
                "minio_root_password": "minioadmin123",
            },
        }
    }

    config = calculate(config)

    with open_file(output, "w") as f:
        json.dump(config, f, ensure_ascii=False, indent=2, sort_keys=False)
        f.write("\n")


def conf_calculate(input: str, output: str):
    with open(input, "r") as f:
        config = json.load(f)

    config = calculate(config)

    with open_file(output, "w") as f:
        json.dump(config, f, ensure_ascii=False, indent=2, sort_keys=False)
        f.write("\n")


def calculate(data: dict):
    def next_host_after_gateway(subnet: str, gateway: str) -> str:
        import itertools
        from ipaddress import ip_network, ip_address

        net = ip_network(subnet, strict=False)
        gw = ip_address(gateway)
        if gw not in net:
            raise ValueError(f"gateway {gw} not in subnet {net}")

        def get_hosts(hosts):
            for host in hosts:
                if host > gw:
                    yield str(host)

        count = 1
        hosts = net.hosts()  # ネットワーク内の“使用可能ホスト”を昇順で返す
        hosts = list(itertools.islice(get_hosts(hosts), count))
        if len(hosts) != count:
            raise Exception(f"{len(hosts)} {count}")
        return hosts

    calculate_root = {}
    data["calculate"] = calculate_root
    data.setdefault("override", {})
    network: dict = data["def"]["network"]
    calculate = {}
    calculate_root["network"] = calculate
    fixed_ips = next_host_after_gateway(network["subnet"], network["gateway"])
    calculate["fixed_ips"] = fixed_ips

    calculate = {}
    calculate_root["kube"] = calculate
    calculate["knative_address"] = fixed_ips[0]
    calculate["knative_alias"] = fixed_ips[0].replace(".", "-") + ".sslip.io"

    data["merged"] = merge(data)

    return data


def merge(data: dict, exclude=["network"]):
    _exclude = set(exclude)
    merged = {}
    for k, v in data["def"].items():
        if k in _exclude:
            continue

        merged[k] = v

    for k, v in data["calculate"].items():
        if k in _exclude:
            continue

        current = merged[k]

        for _k, _v in v.items():
            current[_k] = _v

    for k, v in data["override"].items():
        if k in _exclude:
            continue

        current = merged[k]

        for _k, _v in v.items():
            current[_k] = _v

    return merged


if __name__ == "__main__":
    result = main()
    raise SystemExit(result)
