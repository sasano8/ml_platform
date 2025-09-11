import httpx
import pytest


@pytest.mark.parametrize(
    [
        "service_name",
        "url",
        "method",
        "verify",
        "expect"
    ],
    [
        ("Step CA", "ca.platform.localtest.me", "get", False, 400),
        ("Pocket ID Auth", "auth.platform.localtest.me", "get", False, 200),
        ("MinIO Console", "console.platform.localtest.me", "get", False, 200),
        ("MinIO S3 API", "s3.platform.localtest.me", "get", False, 403),
    ]
)
def test_service(service_name, url, method, verify, expect):
    url = "https://" + url
    print(url)
    assert httpx.request(method, url, verify=verify).status_code == expect
