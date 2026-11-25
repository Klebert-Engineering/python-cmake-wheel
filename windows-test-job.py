"""Run one wheel test in a Windows job so descendants cannot keep CTest pipes open."""

import ctypes
import subprocess
import sys
import uuid
from contextlib import contextmanager
from ctypes import wintypes
from pathlib import Path


class BasicLimits(ctypes.Structure):
    _fields_ = [
        ("process_time", ctypes.c_int64),
        ("job_time", ctypes.c_int64),
        ("flags", wintypes.DWORD),
        ("min_working_set", ctypes.c_size_t),
        ("max_working_set", ctypes.c_size_t),
        ("active_processes", wintypes.DWORD),
        ("affinity", ctypes.c_size_t),
        ("priority", wintypes.DWORD),
        ("scheduling", wintypes.DWORD),
    ]


class ExtendedLimits(ctypes.Structure):
    # These unused fields must be present for the native structure size and alignment.
    _fields_ = [
        ("basic", BasicLimits),
        ("io_counters", ctypes.c_uint64 * 6),
        ("memory_limits", ctypes.c_size_t * 4),
    ]


kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
JOB_OBJECT_ASSIGN_PROCESS = 0x0001
JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE = 0x2000
JOB_OBJECT_EXTENDED_LIMIT_INFORMATION = 9


def checked_api(name, result_type, *argument_types):
    """Declare pointer-sized Win32 arguments and surface the original error."""
    def check(result, function, arguments):
        if not result:
            raise ctypes.WinError(ctypes.get_last_error())
        return result

    function = getattr(kernel32, name)
    function.argtypes = argument_types
    function.restype = result_type
    function.errcheck = check
    return function


create_job = checked_api("CreateJobObjectW", wintypes.HANDLE, wintypes.LPVOID, wintypes.LPCWSTR)
open_job = checked_api("OpenJobObjectW", wintypes.HANDLE, wintypes.DWORD, wintypes.BOOL, wintypes.LPCWSTR)
set_limits = checked_api("SetInformationJobObject", wintypes.BOOL, wintypes.HANDLE,
                         ctypes.c_int, wintypes.LPVOID, wintypes.DWORD)
assign_process = checked_api("AssignProcessToJobObject", wintypes.BOOL, wintypes.HANDLE, wintypes.HANDLE)
current_process = checked_api("GetCurrentProcess", wintypes.HANDLE)
close_handle = checked_api("CloseHandle", wintypes.BOOL, wintypes.HANDLE)


@contextmanager
def owned_handle(handle):
    try:
        yield handle
    finally:
        close_handle(handle)


def run(command):
    # Forward CTest's pipes explicitly, including when the runner has no console.
    return subprocess.call(command, stdin=sys.stdin, stdout=sys.stdout, stderr=sys.stderr)


def main(args):
    if args[0] == "--join":
        # Join before starting Bash, which may itself be a Git-for-Windows launcher.
        # Close our handle so only the supervisor controls the job's lifetime.
        with owned_handle(open_job(JOB_OBJECT_ASSIGN_PROCESS, False, args[1])) as job:
            assign_process(job, current_process())
        return run(args[2:])

    name = f"python-cmake-wheel-{uuid.uuid4().hex}"
    with owned_handle(create_job(None, name)) as job:
        limits = ExtendedLimits()
        limits.basic.flags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        set_limits(job, JOB_OBJECT_EXTENDED_LIMIT_INFORMATION,
                   ctypes.byref(limits), ctypes.sizeof(limits))
        # The supervisor stays outside the job and returns the test's exit code.
        # Closing its handle also stops services whose immediate parent already exited.
        return run([sys.executable, str(Path(__file__).resolve()), "--join", name, *args])


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
