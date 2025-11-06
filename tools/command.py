from __future__ import annotations
import os, sys, time, shlex, selectors
import subprocess
from dataclasses import dataclass, asdict
from typing import (
    Callable,
    Dict,
    List,
    Optional,
    Sequence,
    Union,
    Tuple,
    Any,
    TypeVar,
    Generic,
)
from functools import partial
import json

F = TypeVar("F")


@dataclass
class CmdParams:
    cmd: Union[str, Sequence[str]]
    shell: bool = False
    cwd: Optional[str] = None
    env: Optional[Dict[str, str]] = None
    timeout: Optional[float] = None
    input_text: Optional[str] = None
    encoding: str = "utf-8"
    on_stdout: Callable[[str], None] = sys.stdout.write
    on_stderr: Callable[[str], None] = sys.stderr.write
    check: bool = False
    use_stdbuf: bool = False  # POSIXのみ: 子プロセスの行バッファ化で順序ブレを軽減


@dataclass
class CmdResult:
    cmd: List[str]
    rc: int
    duration_sec: float
    # cwd: Optional[str]
    # stdout: str      # 逐次出したログを全て結合したもの（利便用）
    # stderr: str

    def dumps(self):
        data = asdict(self)
        return json.dumps(data, ensure_ascii=False)


class Defer(partial):
    def run(self, /, *args, **keywords):
        return self.__call__(*args, **keywords)

    @classmethod
    def wrap(cls, func):
        def wrapper(*args, **kwargs):
            return cls(func, *args, **kwargs)

        wrapper.__name__ = func.__name__
        wrapper.__doc__ = func.__doc__
        return wrapper


class Commands:
    def __init__(self, *commands):
        self._commands = commands

    def run(self, stop_on_error: bool = True):
        results = []
        self.on_end_all(self._commands)
        for i, cmd in enumerate(self._commands):
            self.on_start(i)
            result = cmd.run()
            results.append(result)
            self.on_end(i)
            if result.rc == 0:
                if stop_on_error:
                    break

        self.on_end_all(self._commands, result)
        return results

    def on_start_all(self): ...

    def on_start(self, i): ...

    def on_end(self, i): ...

    def on_end_all(self): ...


class Command:
    def __init__(
        self,
        cmd: Union[str, Sequence[str]],
        *,
        shell: bool = False,
        cwd: Optional[str] = None,
        env: Optional[Dict[str, str]] = None,
        timeout: Optional[float] = None,
        input_text: Optional[str] = None,
        encoding: str = "utf-8",
        on_stdout: Callable[[str], None] = sys.stdout.write,
        on_stderr: Callable[[str], None] = sys.stderr.write,
        # check: bool = False,
        use_stdbuf: bool = False,  # POSIXのみ: 子プロセスの行バッファ化で順序ブレを軽減
    ):
        display_cmd, exec_cmd = self.build_cmd(cmd, shell, use_stdbuf)
        self._kwargs = {
            "display_cmd": display_cmd,
            "cmd": exec_cmd,
            "shell": shell,
            "cwd": cwd,
            "env": env,
            "timeout": timeout,
            "input_text": input_text,
            "encoding": encoding,
            "on_stdout": on_stdout,
            "on_stderr": on_stderr,
            # "check": check,
        }

    @property
    def display_cmd(self):
        return self._kwargs["display_cmd"]
    
    def get_shell_cmd(self):
        if isinstance(self._kwargs["display_cmd"], str):
            return self._kwargs["display_cmd"]
        elif isinstance(self._kwargs["display_cmd"], list):
            ...
        else:
            raise RuntimeError()
        
        import shlex
        multi_line = " \\\n".join(shlex.quote(line) for line in self._kwargs["display_cmd"])
        return multi_line

    @staticmethod
    def build_cmd(cmd, shell, use_stdbuf):
        if os.name != "posix":
            raise RuntimeError(
                "This streamlined version currently supports POSIX only."
            )

        # 受け取り形式の検証と実行コマンド整形
        if shell:
            if not isinstance(cmd, str):
                raise ValueError("shell=True のときは cmd は str を渡してください。")
            display_cmd = cmd
            exec_cmd = f"stdbuf -oL -eL {cmd}" if use_stdbuf else cmd
        else:
            if not isinstance(cmd, Sequence):
                raise ValueError(
                    "shell=False のときは cmd は Sequence[str] を渡してください。"
                )
            display_cmd = list(cmd)
            exec_cmd = (
                (["stdbuf", "-oL", "-eL"] + list(cmd)) if use_stdbuf else list(cmd)
            )

        return display_cmd, exec_cmd

    def run(self, /, **kwargs):
        return run_command(**self._kwargs, **kwargs)


# @Defer.wrap
def run_command(
    display_cmd,
    cmd: Union[str, Sequence[str]],
    *,
    shell: bool = False,
    cwd: Optional[str] = None,
    env: Optional[Dict[str, str]] = None,
    timeout: Optional[float] = None,
    input_text: Optional[str] = None,
    encoding: str = "utf-8",
    on_stdout: Callable[[str], None] = sys.stdout.write,
    on_stderr: Callable[[str], None] = sys.stderr.write,
    # check: bool = False,
    # use_stdbuf: bool = False,  # POSIXのみ: 子プロセスの行バッファ化で順序ブレを軽減
) -> CmdResult:
    if os.name != "posix":
        raise RuntimeError("This streamlined version currently supports POSIX only.")

    # 受け取り形式の検証と実行コマンド整形
    # if shell:
    #     if not isinstance(cmd, str):
    #         raise ValueError("shell=True のときは cmd は str を渡してください。")
    #     display_cmd = cmd
    #     exec_cmd = f"stdbuf -oL -eL {cmd}" if use_stdbuf else cmd
    # else:
    #     if not isinstance(cmd, Sequence):
    #         raise ValueError(
    #             "shell=False のときは cmd は Sequence[str] を渡してください。"
    #         )
    #     display_cmd = list(cmd)
    #     exec_cmd = (["stdbuf", "-oL", "-eL"] + list(cmd)) if use_stdbuf else list(cmd)

    popen_env = os.environ.copy()
    if env:
        popen_env.update(env)

    preexec_fn = os.setsid  # 新しいPGで起動して子ごと止めやすく
    creationflags = 0

    start = time.time()
    proc = subprocess.Popen(
        cmd,
        shell=shell,
        cwd=cwd,
        env=popen_env,
        stdin=subprocess.PIPE if input_text is not None else None,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding=encoding,
        bufsize=1,  # 行単位
        preexec_fn=preexec_fn,  # POSIX
        creationflags=creationflags,
    )

    if input_text is not None and proc.stdin:
        proc.stdin.write(input_text)
        proc.stdin.close()

    sel = selectors.DefaultSelector()
    if proc.stdout:
        sel.register(proc.stdout, selectors.EVENT_READ)
    if proc.stderr:
        sel.register(proc.stderr, selectors.EVENT_READ)

    def _kill_tree():
        try:
            import signal, os as _os

            _os.killpg(_os.getpgid(proc.pid), signal.SIGTERM)
        except Exception:
            try:
                proc.terminate()
            except Exception:
                pass

    try:
        while True:
            if timeout is not None and (time.time() - start) > timeout:
                _kill_tree()
                raise subprocess.TimeoutExpired(display_cmd, timeout)

            events = sel.select(timeout=0.1)
            for key, _ in events:
                line = key.fileobj.readline()
                if not line:
                    continue
                if key.fileobj is proc.stdout:
                    on_stdout(line)  # 逐次コールバックのみ
                    on_stdout("\n")
                else:
                    on_stderr(line)
                    on_stderr("\n")

            if proc.poll() is not None:
                # 残りを読み切って全てコールバックへ
                if proc.stdout:
                    for line in proc.stdout.readlines():
                        on_stdout(line)
                        on_stdout("\n")
                if proc.stderr:
                    for line in proc.stderr.readlines():
                        on_stderr(line)
                        on_stderr("\n")
                break
    finally:
        try:
            if proc.stdin:
                proc.stdin.close()
        except Exception:
            pass

    rc = proc.wait()
    # if check and rc != 0:
    #     # 出力は保持していないので output/stderr は付けない
    #     raise subprocess.CalledProcessError(rc, display_cmd)

    return CmdResult(
        cmd=display_cmd if isinstance(display_cmd, list) else [display_cmd],
        rc=rc,
        duration_sec=time.time() - start,
    )
