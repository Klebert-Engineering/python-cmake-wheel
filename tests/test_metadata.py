"""Inspect actual wheel artifacts with and without the optional metadata."""

from email import message_from_bytes
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from zipfile import ZipFile


class MetadataTest(unittest.TestCase):
    def check_wheel(self, stable):
        source = Path(__file__).resolve().parent / "metadata"
        with tempfile.TemporaryDirectory() as tmp:
            build = Path(tmp)
            subprocess.run(["cmake", "-S", source, "-B", build,
                            f"-DPython3_EXECUTABLE={sys.executable}",
                            f"-DTEST_STABLE_ABI={'ON' if stable else 'OFF'}"], check=True)
            subprocess.run(["cmake", "--build", build, "--config", "Release"], check=True)
            wheel, = (build / "dist").glob("*.whl")
            tag = "cp310-abi3" if stable else "cp{0}-cp{0}".format(sys.implementation.cache_tag.split("-")[1])
            self.assertIn(f"-{tag}-", wheel.name)
            with ZipFile(wheel) as archive:
                info = "example-1.0.dist-info/"
                self.assertIn(f"Tag: {tag}-", archive.read(info + "WHEEL").decode())
                metadata = message_from_bytes(archive.read(info + "METADATA"))
                if stable:
                    self.assertEqual(metadata["Description-Content-Type"], "text/markdown")
                    self.assertEqual(metadata.get_payload().strip().splitlines(),
                                     (source / "README.md").read_text(encoding="utf-8").strip().splitlines())
                    self.assertEqual(metadata["License-Expression"] or metadata["License"], "BSD-3-Clause")
                else:
                    self.assertIsNone(metadata["Description-Content-Type"])
                    self.assertNotIn("example/README.txt", archive.namelist())
            if stable:
                subprocess.run([sys.executable, "-m", "twine", "check", "--strict", wheel], check=True)

    def test_stable_abi_and_readme(self):
        self.check_wheel(True)

    def test_default_abi_without_readme(self):
        self.check_wheel(False)


if __name__ == "__main__":
    unittest.main()
