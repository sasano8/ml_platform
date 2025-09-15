import httpx
import pytest
import json

skipif = pytest.mark.skipif


class Writer:
    def __init__(self, f):
        self._f = f

    def write_jsonl(self, data):
        dumped = json.dumps(data, indent=None, ensure_ascii=False)
        self._f.write(dumped)
        self._f.write("\n")


@pytest.fixture(scope="session")
def protocol_report():
    with open("protocol_report.jsonl", "w") as f:
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
            marks=skipif(True, reason="503.なぜ？"),
        ),
        ("Pocket ID Auth", "auth.platform.localtest.me", "get", False, 200),
        ("MinIO Console", "console.platform.localtest.me", "get", False, 200),
        ("MinIO S3 API", "s3.platform.localtest.me", "get", False, 403),
    ],
)
def test_service(protocol_report: Writer, service_name, url, method, verify, expect):
    report = {}
    report_additional = {}
    report["method"] = method
    report["url"] = "https://" + url
    report["verify"] = verify
    report_additional["status_code"] = expect

    _res = {"result": False}

    try:
        try:
            res = httpx.request(**report)
        except httpx.ConnectError as e:
            _res["err"] = str(e.__class__) + ": " + str(e)
            raise

        _res["status_code"] = res.status_code
        assert res.status_code == expect
        _res["result"] = True

    finally:
        report.update(report_additional)
        report_result = {"req": report, "res": _res}
        protocol_report.write_jsonl(report_result)
