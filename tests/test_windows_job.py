"""Exercise CTest-style captured output with surviving native child processes."""

import socket
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path


THIS_FILE = Path(__file__).resolve()
LAUNCHER = THIS_FILE.parents[1] / "windows-test-job.py"


def serve(marker):
    with socket.socket() as server:
        server.bind(("127.0.0.1", 0))
        server.listen()
        print("background service ready", flush=True)
        temporary = marker.with_suffix(".tmp")
        temporary.write_text(str(server.getsockname()[1]))
        temporary.replace(marker)
        server.settimeout(30)  # A broken cleanup must not leak the fixture indefinitely.
        try:
            connection, _ = server.accept()
        except TimeoutError:
            return
        connection.close()


def ready_port(marker):
    deadline = time.monotonic() + 10
    while not marker.exists():
        if time.monotonic() > deadline:
            raise TimeoutError("background service did not start")
        time.sleep(0.05)
    return int(marker.read_text())


def leave_service_running(marker, disposition):
    subprocess.Popen([sys.executable, THIS_FILE, "serve", marker],
                     stdin=subprocess.DEVNULL, stdout=sys.stdout, stderr=sys.stderr)
    ready_port(marker)
    if disposition == "wait":
        time.sleep(30)
        return 0
    return int(disposition)


class WindowsJobTest(unittest.TestCase):
    def test_unsupervised_descendant_keeps_pipe_open(self):
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / "port"
            command = [sys.executable, THIS_FILE, "launch", marker, "0"]
            with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT) as parent:
                port = ready_port(marker)
                try:
                    self.assertEqual(parent.wait(timeout=10), 0)
                    with self.assertRaises(subprocess.TimeoutExpired):
                        parent.communicate(timeout=0.25)
                finally:
                    with socket.create_connection(("127.0.0.1", port), timeout=3):
                        pass
                    parent.communicate(timeout=10)

    @unittest.skipUnless(sys.platform == "win32", "requires Windows Job Objects")
    def test_exit_and_cancellation_close_descendants_and_pipes(self):
        for disposition in ("0", "23", "wait"):
            with self.subTest(disposition=disposition), tempfile.TemporaryDirectory() as directory:
                marker = Path(directory) / "port"
                command = [sys.executable, LAUNCHER, sys.executable, THIS_FILE,
                           "launch", marker, disposition]
                with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                      text=True) as supervisor:
                    try:
                        port = ready_port(marker)
                        if disposition == "wait":
                            supervisor.kill()  # Exercise a CTest timeout or interrupted run.
                        output, _ = supervisor.communicate(timeout=10)
                    finally:
                        if supervisor.poll() is None:
                            supervisor.kill()
                self.assertIn("background service ready", output)
                if disposition != "wait":
                    self.assertEqual(supervisor.returncode, int(disposition))
                with socket.socket() as next_service:
                    next_service.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
                    next_service.bind(("127.0.0.1", port))


if __name__ == "__main__":
    if sys.argv[1:2] == ["serve"]:
        serve(Path(sys.argv[2]))
    elif sys.argv[1:2] == ["launch"]:
        sys.exit(leave_service_running(Path(sys.argv[2]), sys.argv[3]))
    else:
        unittest.main()
