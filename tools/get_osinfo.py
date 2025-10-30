import platform

os_map = {
    "Linux": "linux",
    "Darwin": "darwin",
    "Windows": "windows",
}
arch_map = {
    "x86_64": "amd64",
    "AMD64": "amd64",
    "aarch64": "arm64",
    "arm64": "arm64",
    "armv7l": "armv7",
    "i386": "386",
    "i686": "386",
}

os = os_map.get(platform.system(), platform.system().lower())
arch = arch_map.get(platform.machine(), platform.machine().lower())
print(f"{os}-{arch}")
