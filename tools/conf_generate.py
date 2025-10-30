from dataclasses import dataclass, asdict


@dataclass
class ConfigArgs:
    format: str
    external_host: str
    wildcarddomain: str
    subnet: str
    gateway: str
    knative_address: str
    # knative_alias: str
    minio_root_user: str
    minio_root_password: str

    @classmethod
    def from_cli(cls, default_format="json"):
        import argparse

        parser = argparse.ArgumentParser(description="")
        parser.add_argument("--format", default=default_format)
        parser.add_argument("--external_host", required=True)
        parser.add_argument("--wildcarddomain", default="sslip.io")
        parser.add_argument("--subnet", default="172.30.0.0/16")
        parser.add_argument("--gateway", default="172.30.0.1")
        parser.add_argument("--knative_address", default="172.30.0.2")
        # parser.add_argument("--knative_alias", default="knative")
        parser.add_argument("--minio_root_user", default="minioadmin")
        parser.add_argument("--minio_root_password", default="minioadmin123")
        # parser.add_argument("--volume", default="172.30.0.1")

        # UID=1000
        # GID=1000

        # MINIO_ROOT_USER=minioadmin
        # MINIO_ROOT_PASSWORD=minioadmin123

        # # KONG_HTTP_PORT=8000
        # KONG_HTTP_PORT=80
        # KONG_HTTPS_PORT=443

        # APP_DOMAIN=DESKTOP-1ST3DCE

        args = parser.parse_args()
        return cls(**vars(args))

    def to_dict(self, resolve=True):
        data = asdict(self)
        if not resolve:
            return data

        data["external_domain"] = self.get_external_domain()
        data["knative_alias"] = self.get_external_domain()

        return data

    def get_external_domain(self):
        if self.wildcarddomain:
            return self.external_host.replace(".", "-") + "." + self.wildcarddomain
        else:
            return self.external_host

    @staticmethod
    def to_dotenv(data: dict) -> str:
        from io import StringIO

        # data = self.to_dict()
        def dump(data: dict, f):
            for k, v in data.items():
                f.write(k.upper() + "=" + str(v) + "\n")

        with StringIO() as f:
            dump(data, f)
            return f.getvalue()

    @staticmethod
    def to_json(data: dict) -> str:
        import json

        return json.dumps(data, ensure_ascii=False, indent=2)

    def dumps(self, format=None):
        data = self.to_dict()
        _format = data.pop("format", None)
        if format is None:
            format = _format

        if format == "dict":
            return data
        elif format == ".env":
            return self.to_dotenv(data)
        elif format == "json":
            return self.to_json(data)
        else:
            raise Exception()


if __name__ == "__main__":
    args = ConfigArgs.from_cli(default_format="json")
    # print(args.to_dict())
    # print(args.get_external_domain())
    print(args.dumps())
