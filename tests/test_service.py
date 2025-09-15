import httpx
import pytest
import json
import os


class Writer:
    def __init__(self, f):
        self._f = f

    def write_jsonl(self, data):
        dumped = json.dumps(data, indent=None, ensure_ascii=False)
        self._f.write(dumped)
        self._f.write("\n")


@pytest.fixture(scope="session")
def protocol_report():
    path_file = ".cache/protocol_report.jsonl"
    path_dir = os.path.dirname(path_file)
    os.makedirs(path_dir, exist_ok=True)

    with open(path_file, "w") as f:
        yield Writer(f)


@pytest.mark.parametrize(
    ["service_name", "url", "method", "verify", "expect"],
    [
        pytest.param(
            "Step CA",
            "ca.platform.localtest.me",
            "get",
            False,
            400,
        ),
        pytest.param("Pocket ID Auth", "auth.platform.localtest.me", "get", True, 200),
        pytest.param(
            "MinIO Console", "console.platform.localtest.me", "get", True, 200
        ),
        pytest.param("MinIO S3 API", "s3.platform.localtest.me", "get", True, 403),
    ],
)
def test_service(protocol_report: Writer, service_name, url, method, verify, expect):
    report = {}
    report_additional = {}
    report["method"] = method
    report["url"] = "https://" + url
    report_additional["status_code"] = expect

    _res = {"result": False}

    try:
        try:
            with httpx.Client(http2=True, verify=verify) as client:
                # report["verify"] = verify
                res = client.request(**report)
        except httpx.ConnectError as e:
            _res["err"] = str(e.__class__) + ": " + str(e)
            raise

        _res["status_code"] = res.status_code
        _res["http_version"] = res.http_version
        assert res.status_code == expect
        assert res.http_version == "HTTP/2"
        _res["result"] = True

    finally:
        report.update(report_additional)
        report_result = {"req": report, "res": _res}
        protocol_report.write_jsonl(report_result)
