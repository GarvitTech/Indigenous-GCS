#!/usr/bin/env python3
"""
Audit the QML layer for references to C++ members that do not exist.

This catches the class of bug that broke logging: QML calling
`modelData.vehicleId` or `LogReader.exportSession()` when neither exists.
Qt reports these only at runtime, often as a silent `undefined`, so a page can
look fine while a feature does nothing.

Usage:  python3 tools/audit_qml_api.py
Exit code is 1 if any suspicious reference is found.
"""

import re
import sys
import pathlib
from collections import defaultdict

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Context objects exposed to QML from src/main.cpp via setContextProperty().
CONTEXT_OBJECTS = [
    "AppSettings", "ConnectionManager", "MAVLinkManager", "VehicleManager",
    "MissionManager", "ParameterManager", "CalibrationManager", "SafetyManager",
    "FirmwareManager", "MSPManager", "Simulator", "FlightLogger", "LogReader",
]

# Map a context object to the header that declares its API.
HEADERS = {
    "AppSettings":        "src/app/AppSettings.h",
    "ConnectionManager":  "src/communication/ConnectionManager.h",
    "MAVLinkManager":     "src/mavlink/MAVLinkManager.h",
    "VehicleManager":     "src/vehicle/VehicleManager.h",
    "MissionManager":     "src/mission/MissionManager.h",
    "ParameterManager":   "src/parameters/ParameterManager.h",
    "CalibrationManager": "src/calibration/CalibrationManager.h",
    "SafetyManager":      "src/safety/SafetyManager.h",
    "FirmwareManager":    "src/firmware/FirmwareManager.h",
    "MSPManager":         "src/msp/MSPManager.h",
    "Simulator":          "src/simulation/Simulator.h",
    "FlightLogger":       "src/logging/FlightLogger.h",
    "LogReader":          "src/logging/LogReader.h",
}

# Members inherited from QObject / Qt base classes that QML may legitimately use.
QT_BUILTINS = {
    "objectName", "parent", "children", "destroy", "deleteLater", "toString",
    "valueOf", "hasOwnProperty", "constructor", "length", "count",
}


def declared_members(header: pathlib.Path) -> set:
    """Collect Q_PROPERTY names, Q_INVOKABLE methods and public slots."""
    if not header.exists():
        return set()
    text = header.read_text(errors="replace")
    members = set()

    # Q_PROPERTY(Type name READ ...)
    for m in re.finditer(r"Q_PROPERTY\(\s*[\w:<>\*,\s]+?\s+(\w+)\s+READ", text):
        members.add(m.group(1))

    # Q_INVOKABLE ReturnType name(
    for m in re.finditer(r"Q_INVOKABLE\s+[\w:<>\*,\s]+?\s+(\w+)\s*\(", text):
        members.add(m.group(1))

    # Plain public methods:  ReturnType name(  at one indent level
    for m in re.finditer(r"^\s{4}[\w:<>\*&,\s]+?\s+(\w+)\s*\([^;]*\)\s*(?:const)?\s*(?:override)?\s*[;{]", text, re.M):
        members.add(m.group(1))

    # Signals (QML can connect to these by name)
    for m in re.finditer(r"^\s*void\s+(\w+)\s*\(", text, re.M):
        members.add(m.group(1))

    return members


def main() -> int:
    api = {name: declared_members(ROOT / HEADERS[name]) for name in CONTEXT_OBJECTS}

    # Signal handler names: QML writes onFooChanged for signal fooChanged.
    problems = defaultdict(list)

    for qml in sorted(ROOT.glob("qml/**/*.qml")):
        text = qml.read_text(errors="replace")
        rel = qml.relative_to(ROOT)

        for obj in CONTEXT_OBJECTS:
            # Match Obj.member  (not Obj.member() , not Obj.member =)
            for m in re.finditer(rf"\b{obj}\.(\w+)", text):
                member = m.group(1)
                if member in QT_BUILTINS:
                    continue
                if member not in api[obj]:
                    line = text[:m.start()].count("\n") + 1
                    problems[str(rel)].append(
                        f"  L{line}: {obj}.{member}  — not declared in {HEADERS[obj]}")

        # Signal handlers:  function onSomethingChanged(...)
        for m in re.finditer(r"function\s+on([A-Z]\w+)\s*\(", text):
            handler = m.group(1)
            # Derive the signal name: onFooChanged -> fooChanged
            signal = handler[0].lower() + handler[1:]
            line = text[:m.start()].count("\n") + 1
            found = any(signal in api[o] for o in CONTEXT_OBJECTS)
            if not found:
                problems[str(rel)].append(
                    f"  L{line}: handler on{handler} -> signal '{signal}' not found on any context object")

    if not problems:
        print("QML API audit: no unresolved references found.")
        return 0

    print("QML API audit: possible unresolved references\n")
    print("NOTE: handlers targeting a LOCAL QML object (a Connections block whose")
    print("      target is an item id, not a context object) are expected here and")
    print("      are not real problems. Only entries naming a context object matter.\n")
    total = 0
    for f, items in sorted(problems.items()):
        print(f"### {f}")
        for i in items:
            print(i)
            total += 1
        print()
    print(f"TOTAL: {total} suspicious reference(s)")
    return 1


if __name__ == "__main__":
    sys.exit(main())
