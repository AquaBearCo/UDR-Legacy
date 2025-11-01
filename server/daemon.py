#!/usr/bin/env python3

"""Lightweight helpers for running the UDR server as a daemon."""

from __future__ import annotations

import atexit
import os
import sys
import time
from pathlib import Path
from signal import SIGTERM
from typing import Optional


class Daemon:
    """
    A generic daemon class, based on http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/
   
    Usage: subclass the Daemon class and override the run() method
    """
    def __init__(
        self,
        pidfile: str,
        stdin: str = "/dev/null",
        stdout: str = "/dev/null",
        stderr: str = "/dev/null",
    ) -> None:
        self.stdin = stdin
        self.stdout = stdout
        self.stderr = stderr
        self.pidfile = pidfile
   
    def daemonize(self):
        """
        do the UNIX double-fork magic, see Stevens' "Advanced
        Programming in the UNIX Environment" for details (ISBN 0201563177)
        http://www.erlenstar.demon.co.uk/unix/faq_2.html#SEC16
        """
        try:
            pid = os.fork()
            if pid > 0:
                # exit first parent
                sys.exit(0)
        except OSError as exc:
            sys.stderr.write(f"[FAIL] fork #1: {exc.errno} ({exc.strerror})\n")
            sys.exit(1)

        # decouple from parent environment
        os.chdir("/")
        os.setsid()
        os.umask(0)

        # do second fork
        try:
            pid = os.fork()
            if pid > 0:
                # exit from second parent
                sys.exit(0)
        except OSError as exc:
            sys.stderr.write(f"[FAIL] fork #2: {exc.errno} ({exc.strerror})\n")
            sys.exit(1)

        # write pidfile
        pid = str(os.getpid())
        Path(self.pidfile).write_text(f"{pid}\n", encoding="utf-8")

        atexit.register(self.delpid)
          
        # redirect standard file descriptors
        sys.stdout.flush()
        sys.stderr.flush()
        with open(self.stdin, "r", encoding="utf-8", errors="ignore") as si, open(
            self.stdout, "a+", encoding="utf-8", errors="ignore"
        ) as so, open(self.stderr, "a+", encoding="utf-8", errors="ignore"
        ) as se:
            os.dup2(si.fileno(), sys.stdin.fileno())
            os.dup2(so.fileno(), sys.stdout.fileno())
            os.dup2(se.fileno(), sys.stderr.fileno())

    def delpid(self):
        try:
            os.remove(self.pidfile)
        except FileNotFoundError:
            pass

    def start(self):
        """
        Start the daemon
        """
        # Check for a pidfile to see if the daemon already runs
        pid: Optional[int]
        try:
            with open(self.pidfile, "r", encoding="utf-8") as pf:
                pid = int(pf.read().strip())
        except (IOError, ValueError):
            pid = None

        if pid:
            message = "[FAIL] pidfile %s already exists. Daemon already running?\n"
            sys.stderr.write(message % self.pidfile)
            sys.exit(1)
       
        # Start the daemon
        self.daemonize()
        self.run()

    def stop(self):
        """
        Stop the daemon
        """
        # Get the pid from the pidfile
        try:
            with open(self.pidfile, "r", encoding="utf-8") as pf:
                pid = int(pf.read().strip())
        except (IOError, ValueError):
            pid = None

        if not pid:
            message = "[FAIL] pidfile %s does not exist. Daemon not running?\n"
            sys.stderr.write(message % self.pidfile)
            return # not an error in a restart

        # Try killing the daemon process       
        try:
            while True:
                os.kill(pid, SIGTERM)
                time.sleep(0.1)
        except OSError as err:
            message = str(err)
            if "No such process" in message:
                try:
                    os.remove(self.pidfile)
                except FileNotFoundError:
                    pass
            else:
                sys.stderr.write(f"[FAIL]\n{message}\n")
                sys.exit(1)

    #def restart(self):
    #        """
    #        Restart the daemon
    #        """
    #        self.stop()
    #        self.start()

    def run(self):
        """
        You should override this method when you subclass Daemon. It will be called after the process has been
        daemonized by start() or restart().
        """
