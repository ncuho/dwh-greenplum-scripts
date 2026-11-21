#!/usr/bin/env python3
"""Observe known demo writers and Kafka; does not establish or claim a fence."""
import json, subprocess, urllib.request, re, pathlib, sys


def output(args):
    return subprocess.run(
        args, check=True, text=True, capture_output=True, timeout=12
    ).stdout


def main():
    state = json.load(
        urllib.request.urlopen("http://127.0.0.1:18086/api/state", timeout=10)
    )
    if not state["broker"]["ok"]:
        raise RuntimeError("broker unavailable")
    description = output(
        [
            "sudo",
            "-n",
            "-u",
            "kafka",
            "env",
            "JAVA_HOME=/opt/kafka-demo/jdk",
            "/opt/kafka-demo/current/bin/kafka-topics.sh",
            "--bootstrap-server",
            "10.77.25.20:9093",
            "--command-config",
            "/etc/kafka-demo/client.properties",
            "--describe",
            "--topic",
            "oil.events.v1",
        ]
    )
    match = re.search(r"\bTopicId:\s*(\S+)", description)
    if not match:
        raise RuntimeError("topic ID unavailable")
    acl = output(
        [
            "sudo",
            "-n",
            "-u",
            "kafka",
            "env",
            "JAVA_HOME=/opt/kafka-demo/jdk",
            "/opt/kafka-demo/current/bin/kafka-acls.sh",
            "--bootstrap-server",
            "10.77.25.20:9093",
            "--command-config",
            "/etc/kafka-demo/client.properties",
            "--list",
        ]
    )
    entries = re.findall(
        r"\(principal=([^,]+), host=([^,]+), operation=([^,]+), permissionType=([^\)]+)\)",
        acl,
    )
    expected = {
        ("User:CN=oil-producer", "*", "WRITE", "DENY"),
        ("User:CN=oil-producer", "*", "WRITE", "ALLOW"),
        ("User:CN=oil-connect-worker", "*", "READ", "ALLOW"),
        ("User:CN=oil-iceberg-wave2-worker", "*", "READ", "ALLOW"),
        ("User:CN=oil-kafka-ui-metadata", "*", "DESCRIBE", "ALLOW"),
    }
    resources = re.findall(
        r"ResourcePattern\(resourceType=([^,]+), name=([^,]+), patternType=([^\)]+)\)",
        acl,
    )
    acl_fenced = (
        set(entries) == expected
        and len(entries) == len(expected)
        and resources == [("TOPIC", "oil.events.v1", "LITERAL")]
    )
    processes = []
    for path in pathlib.Path("/proc").glob("[0-9]*/cmdline"):
        try:
            parts = path.read_bytes().split(b"\0")
            cmd = [p.decode("utf-8", "replace") for p in parts if p]
            if cmd and any(re.search(r"(^|/)oil_events\.py$", p) for p in cmd):
                processes.append({"pid": int(path.parent.name), "executable": cmd[0]})
        except (OSError, ValueError):
            pass
    print(
        json.dumps(
            {
                "topic": "oil.events.v1",
                "topic_id": match.group(1),
                "cluster_id": state["broker"].get("cluster_id"),
                "partitions": state["broker"]["partitions"],
                "producer_topic_acl_fenced": acl_fenced,
                "gp_connector": state["source"],
                "wave2_connector": state["wave2"],
                "known_oil_generator_processes": processes,
                "warning": "ACL check excludes trusted superusers; it does not fence Greenplum writers or administrators.",
            }
        )
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)
