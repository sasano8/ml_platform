import os
from .command import Command
from . import _io


def init_ca(input):
    conf = _io.load_json(input)
    stepca = conf["merged"]["stepca"]
    _os = conf["merged"]["os"]

    # "stepca": {
    #   "ca_name": "Localhost",
    #   "server_address": ":9000",
    #   "out_crt": "/home/step/certs/wild.platform.localtest.me.crt",
    #   "out_key": "/home/step/certs/wild.platform.localtest.me.key",
    #   "primary_ca_host": "stepca.172-31-97-7.sslip.io",
    #   "common_name": "172-31-97-7.sslip.io",
    #   "sans": {
    #     "base_domain": "172-31-97-7.sslip.io",
    #     "stepca": "stepca.172-31-97-7.sslip.io",
    #     "knative": "knative.172-31-97-7.sslip.io",
    #     "knative_https": "*.default.knative.172-31-97-7.sslip.io"
    #   }
    # },

    kwargs = {
        "uid": _os["uid"],
        "gid": _os["gid"],
        "ca_name": stepca["ca_name"],
        "server_address": stepca["server_address"],
        "primary_ca_host": stepca["primary_ca_host"],
    }
    cmd = _init_ca(**kwargs)
    print(cmd.get_shell_cmd())
    result = cmd.run()
    return result.rc


def certificate_ca(input):
    conf = _io.load_json(input)
    stepca = conf["merged"]["stepca"]
    kwargs = {
        "server_address": stepca["server_address"],
        "primary_ca_host": stepca["primary_ca_host"],
        "common_name": stepca["common_name"],
        "out_crt": stepca["out_crt"],
        "out_key": stepca["out_key"],
        "sans": stepca["sans"],
    }
    cmd = _certificate_ca(**kwargs)
    print(cmd.get_shell_cmd())
    result = cmd.run()
    return result.rc


def _init_ca(
    ca_name: str,
    uid,
    gid,
    server_address,
    primary_ca_host,
    *dnss,
    pwd=None,
    provisioner="admin@example.com",
):
    """
    証明書サーバーの起動設定やルート証明書を発行し、サーバーを初期化する。

    primary_ca_host: 公開されるCAサーバーのホスト名
    hosts: 公開されるCAサーバーのホスト名群
    """
    # ca_name = "Localhost"
    pwd = os.getcwd() if pwd is None else str(pwd)
    cmd = [
        # fmt: off
        "docker",
        "run",
        "--rm",
        "-it",
        "--user",
        f"{uid}:{gid}",
        "-v",
        f"{pwd}/volumes/step:/home/step",
        "smallstep/step-ca",
        *"step ca init".split(" "),
        "--password-file",
        "/home/step/secrets/password",
        "--deployment-type",
        "standalone",
        "--address",
        str(server_address),
        "--provisioner",
        provisioner,
        "--name",
        ca_name,
        # fmt: on
    ]

    cmd.append("--dns")
    cmd.append(primary_ca_host)

    # dnss = ["stepca.172-31-97-7.sslip.io"]
    for dns in dnss:
        cmd.append("--dns")
        cmd.append(str(dns))

    return Command(cmd)


def _certificate_ca(
    server_address,
    primary_ca_host,
    common_name,
    out_crt,
    out_key,
    sans,
    provisioner="admin@example.com",
):
    """
    dnss: 公開されるCAサーバーのホスト名
    """
    if not common_name:
        raise Exception()

    if not out_crt:
        raise Exception()

    if not out_key:
        raise Exception()

    if not isinstance(sans, dict):
        raise Exception()

    cmd = [
        # fmt: off
        *"docker compose exec stepca step ca certificate".split(" "),
        common_name,
        out_crt,
        out_key,
        "--force",  # 常に上書き
        "--provisioner",
        provisioner,
        "--http-listen",
        f"http://{primary_ca_host}:{server_address}",
        "--root",
        "/home/step/certs/root_ca.crt",
        "--provisioner-password-file",
        "/home/step/secrets/password",
        # fmt: on
    ]

    for san in sans.values():
        cmd.append("--san")
        cmd.append(str(san))

    return Command(cmd)
