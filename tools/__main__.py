import os, sys
import json
from typing import Union
from ._io import open_file
from . import ca


def create_parser():
    import argparse

    p = argparse.ArgumentParser(prog="mygit", description="mini git-like tool")
    # p.add_argument("-v", "--verbose", action="count", default=0, help="increase verbosity")

    sub = p.add_subparsers(dest="command")

    ##########################
    ### init
    ##########################
    s = sub.add_parser("conf_init", help="initialize a repository")
    s.set_defaults(func=conf_init)
    s.add_argument("--network", required=True)
    s.add_argument("--driver", required=True)
    s.add_argument("--subnet", required=True)
    s.add_argument("--gateway", required=True)
    s.add_argument("--external_base_domain", required=True)
    s.add_argument("--uid", default=None)
    s.add_argument("--gid", default=None)
    s.add_argument(
        "--output", nargs="?", default=".env.json", help="target directory (default: .)"
    )

    ##########################
    ### calculate
    ##########################
    s = sub.add_parser("conf_calculate", help="")
    s.set_defaults(func=conf_calculate)
    s.add_argument(
        "--input", nargs="?", default=".env.json", help="target directory (default: .)"
    )
    s.add_argument(
        "--output", nargs="?", default=".env.json", help="target directory (default: .)"
    )

    s = sub.add_parser("ca_init", help="")
    s.set_defaults(func=ca.init_ca)
    s.add_argument(
        "--input", nargs="?", default=".env.json", help="target directory (default: .)"
    )

    s = sub.add_parser("ca_certificate", help="")
    s.set_defaults(func=ca.certificate_ca)
    s.add_argument(
        "--input", nargs="?", default=".env.json", help="target directory (default: .)"
    )

    return p


def main(argv: Union[list[str], None] = None):
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


def conf_init(
    network: str,
    driver: str,
    subnet: str,
    gateway: str,
    external_base_domain: str,
    *,
    output: str,
    uid: str = None,
    gid: str = None,
):
    uid = uid if uid else os.getuid()
    gid = gid if gid else os.getuid()
    config = {
        "init": {
            "os": {
                "uid": str(uid),
                "gid": str(gid),
            },
            "network": {
                "name": network,
                "driver": driver,
                "subnet": subnet,
                "gateway": gateway,
                "external_base_domain": external_base_domain,
            },
            "stepca": {
                "server_address": ":9000",
                "ca_name": "Localhost",
                "out_crt": "/home/step/certs/wild.platform.localtest.me.crt",
                "out_key": "/home/step/certs/wild.platform.localtest.me.key",
            },
            "kube": {
                "network": network,
            },
            "kong": {
                "KONG_SSL_CERT": "/certs/fullchain.wild.platform.localtest.me.crt",
                "KONG_SSL_CERT_KEY": "/certs/wild.platform.localtest.me.key",
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
    with open_file(input, "r") as f:
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
    network: dict = data["init"]["network"]
    calculate = {}
    calculate_root["network"] = calculate
    fixed_ips = next_host_after_gateway(network["subnet"], network["gateway"])
    calculate["fixed_ips"] = fixed_ips

    data["merged"] = merge(data, exclude=[])
    external_base_domain = data["merged"]["network"]["external_base_domain"]

    calculate = data["calculate"].setdefault("stepca", {})
    calculate["primary_ca_host"] = "stepca." + external_base_domain
    calculate["common_name"] = external_base_domain

    sans: dict = calculate.setdefault("sans", {})
    sans["base_domain"] = external_base_domain
    sans["stepca"] = "stepca." + external_base_domain
    sans["knative"] = "knative." + external_base_domain
    sans["knative_https"] = "*.default." + "knative." + external_base_domain
    # sans["knative_grpcs"] = "*.default.grpcs." + "knative." + external_base_domain

    calculate = data["calculate"].setdefault("kong", {})
    calculate["domains"] = {**data["calculate"]["stepca"]["sans"]}

    calculate = data["calculate"].setdefault("kube", {})
    calculate["internal_ip"] = fixed_ips[
        0
    ]  # TODO: 現在若い番号を割り当てているが、複数のコンテナを同時立ち上げると先にipが使われてしまうので、後ろから取った方がよい
    calculate["external_domain"] = data["calculate"]["stepca"]["sans"]["knative"]

    data["merged"] = merge(data)
    # print(data["merged"])

    return data


def merge(data: dict, exclude=["network"]):
    import copy

    _exclude = set(exclude)
    merged = {}
    for k, v in data["init"].items():
        if k in _exclude:
            continue

        merged[k] = copy.deepcopy(v)

    for k, v in data["calculate"].items():
        if k in _exclude:
            continue

        current = merged.setdefault(k, {})

        for _k, _v in v.items():
            current[_k] = _v

    for k, v in data["override"].items():
        if k in _exclude:
            continue

        current = merged.setdefault(k, {})

        for _k, _v in v.items():
            current[_k] = _v

    return merged


if __name__ == "__main__":
    result = main()
    raise SystemExit(result)
