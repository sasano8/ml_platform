import httpx
import pytest


@pytest.mark.parametrize(
    [
        "url",
        "method",
        "verify",
        "expect"
    ],
    [
        ("ca.platform.localtest.me", "get", False, 400),  # bad request
        ("auth.platform.localtest.me", "get", False, 200),
        ("console.platform.localtest.me", "get", False, 200),
        ("s3.platform.localtest.me", "get", False, 403),  # forbidden
    ]
)
def test_service(url, method, verify, expect):
    url = "https://" + url
    print(url)
    assert httpx.request(method, url, verify=verify).status_code == expect
