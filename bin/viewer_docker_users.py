"""Estimate the host user behind root processes in local Docker containers."""

import json
import os
import pwd
import re
import subprocess
import sys


DOCKER_CGROUP = re.compile(
    r"/(?:docker-([0-9a-f]{64})\.scope|docker/([0-9a-f]{64}))(?=/|$)"
)
DOCKER_SOCKET = "/var/run/docker.sock"
OWNER_PATHS = (
    '{{println (json (index .Config.Labels "com.docker.compose.project.working_dir"))}}'
    '{{range .Mounts}}{{if eq .Type "bind"}}{{println (json .Source)}}{{end}}{{end}}'
)


def path_owner(path):
    if not isinstance(path, str) or not os.path.isabs(path):
        return None
    try:
        uid = os.stat(path).st_uid
        if uid == 0:
            return None
        user = pwd.getpwuid(uid)
    except (OSError, KeyError, ValueError):
        return None
    if (os.path.basename(user.pw_shell) in ("false", "nologin")
            or any(char.isspace() for char in user.pw_name)):
        return None
    return user.pw_name


def guess_owner(container):
    if not os.access(DOCKER_SOCKET, os.W_OK):
        return None
    try:
        output = subprocess.check_output(
            ["docker", "--host", "unix://" + DOCKER_SOCKET, "inspect",
             "--type", "container", "--format", OWNER_PATHS, container],
            stderr=subprocess.DEVNULL, universal_newlines=True, timeout=2,
        )
        project_dir, *bind_paths = (json.loads(line) for line in output.splitlines() if line)
    except (OSError, subprocess.SubprocessError, ValueError):
        return None
    owner = path_owner(project_dir)
    if owner:
        return owner
    owners = {path_owner(path) for path in bind_paths} - {None}
    if len(owners) == 1:
        return owners.pop()
    return None


class DockerUsers:
    def __init__(self, proc_root="/proc"):
        self.proc_root = proc_root
        self.labels = {}

    def label(self, pid):
        try:
            with open(os.path.join(self.proc_root, str(pid), "cgroup")) as cgroups:
                for line in cgroups:
                    match = DOCKER_CGROUP.search(line.rstrip("\n"))
                    if match:
                        break
                else:
                    return None
        except OSError:
            return None

        container = match.group(1) or match.group(2)
        if container not in self.labels:
            owner = guess_owner(container)
            self.labels[container] = "Doc:" + (owner or container[:12])
        return self.labels[container]


def label_swap_rows():
    docker_users = DockerUsers()
    for line in sys.stdin.buffer:
        fields = line.split(b" ", 3)
        if (len(fields) == 4 and fields[2] == b"0"
                and fields[0].isdigit() and fields[1].isdigit()):
            label = docker_users.label(int(fields[1]))
            if label:
                fields[2] = os.fsencode(label)
                line = b" ".join(fields)
        sys.stdout.buffer.write(line)


if __name__ == "__main__":
    label_swap_rows()
