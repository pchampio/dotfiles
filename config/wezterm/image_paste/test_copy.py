"""Exercise the actual Lua copy command with a forking clipboard owner.

No compositor, real clipboard changes, or SSH connection required.
"""
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest


MODULE = Path(__file__).with_name("init.lua").resolve()
DRIVER = r"""
package.loaded.wezterm = {
  run_child_process = function(args)
    if args[1] == 'wl-paste' then return true, 'image/png', '' end
    if args[1] == 'ps' then return true, '10 10 10', '' end
    if args[1] == 'mktemp' then return true, '/tmp/wezterm-image-TEST123.png', '' end
    if args[1] == 'sh' and args[4] == 'image-paste-copy' then
      for _, arg in ipairs(args) do io.write(arg, '\0') end
    end
    return true, '', ''
  end,
  log_info = function() end,
  log_error = function(message) error(message) end,
}
io.open = function()
  return {read = function() return 'zsh\0' end, close = function() end}
end
dofile(arg[1]).paste(
  {toast_notification = function() end},
  {get_domain_name = function() return 'local' end,
   get_tty_name = function() return '/dev/pts/1' end,
   paste = function() end})
"""

# Like wl-copy, the parent exits successfully while the clipboard owner keeps
# stderr open until a replacement selection arrives. stdout is already closed.
OWNER = """#!/usr/bin/env python3
import os
from pathlib import Path
import sys
import time
if os.environ.get('COPY_FAIL'):
    sys.stderr.write('clipboard unavailable\\n')
    sys.exit(1)
if os.environ.get('COPY_HANG'):
    time.sleep(30)
Path(os.environ['OWNER_STARTED']).touch()
if os.fork():
    sys.exit(0)
os.dup2(os.open(os.devnull, os.O_RDWR), 1)
deadline = time.monotonic() + 10
while not Path(os.environ['OWNER_STOP']).exists() and time.monotonic() < deadline:
    time.sleep(0.01)
Path(os.environ['OWNER_EXITED']).touch()
"""


class ClipboardCopyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        driver = root / "driver.lua"
        driver.write_text(DRIVER)
        result = subprocess.run(
            ["lua", str(driver), str(MODULE)], capture_output=True, check=True
        )
        self.command = result.stdout.decode().rstrip("\0").split("\0")
        self.assertEqual(self.command[:2], ["sh", "-c"])
        owner = root / "wl-copy"
        owner.write_text(OWNER)
        owner.chmod(0o700)
        self.env = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                        TMPDIR=str(root), OWNER_STARTED=str(root / "started"),
                        OWNER_STOP=str(root / "stop"), OWNER_EXITED=str(root / "exited"))
        self.addCleanup(self.stop_owner)

    def stop_owner(self):
        Path(self.env["OWNER_STOP"]).touch()
        if Path(self.env["OWNER_STARTED"]).exists():
            deadline = time.monotonic() + 2
            while not Path(self.env["OWNER_EXITED"]).exists():
                if time.monotonic() >= deadline:
                    self.fail("Clipboard owner did not exit after replacement")
                time.sleep(0.01)

    def test_direct_capture_reproduces_hang(self):
        process = subprocess.Popen(["wl-copy", "test"], env=self.env,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            with self.assertRaises(subprocess.TimeoutExpired):
                process.communicate(timeout=0.5)
            self.assertTrue(Path(self.env["OWNER_STARTED"]).exists())
        finally:
            Path(self.env["OWNER_STOP"]).touch()
            process.communicate(timeout=2)

    def test_copy_returns_while_owner_stays_alive(self):
        result = subprocess.run(self.command, env=self.env, capture_output=True, timeout=2)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(Path(self.env["OWNER_STARTED"]).exists())
        self.assertFalse(Path(self.env["OWNER_EXITED"]).exists())
        self.assertEqual(result.stderr, b"")
        self.assertEqual(list(Path(self.temp.name).glob("tmp.*")), [])

    def test_startup_error_is_preserved(self):
        result = subprocess.run(self.command, env=dict(self.env, COPY_FAIL="1"),
                                capture_output=True, timeout=2)
        self.assertEqual(result.returncode, 1)
        self.assertIn(b"clipboard unavailable", result.stderr)
        self.assertEqual(list(Path(self.temp.name).glob("tmp.*")), [])

    def test_startup_timeout_is_reported(self):
        result = subprocess.run(self.command, env=dict(self.env, COPY_HANG="1"),
                                capture_output=True, timeout=7)
        self.assertEqual(result.returncode, 124)
        self.assertIn(b"wl-copy failed (status 124)", result.stderr)
        self.assertEqual(list(Path(self.temp.name).glob("tmp.*")), [])


if __name__ == "__main__":
    unittest.main()
