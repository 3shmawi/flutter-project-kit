#!/usr/bin/env python3
"""Adds a file in ios/Runner/ to the Runner target's Resources build phase.

    python3 xcode_add_resource.py ios/Runner.xcodeproj/project.pbxproj PrivacyInfo.xcprivacy

Idempotent: does nothing when the file is already in the project. The ids
are derived from the file name, so re-running (kit sync, add_module) never
creates duplicates. Exits non-zero when the project doesn't look like
Flutter's Runner project, so the caller can warn instead of breaking it.
"""
import hashlib
import re
import sys

pbx_path, name = sys.argv[1], sys.argv[2]
pbx = open(pbx_path, encoding="utf-8").read()

if re.search(r"/\* %s \*/ = \{isa = PBXFileReference" % re.escape(name), pbx):
    print(f"{name} already in the Xcode project")
    sys.exit(0)

digest = hashlib.sha1(f"flutter-project-kit:{name}".encode()).hexdigest().upper()
file_ref, build_file = digest[:24], digest[16:40]
file_type = {
    ".xcprivacy": "text.xml",
    ".plist": "text.plist.xml",
    ".json": "text.json",
}.get(name[name.rfind("."):], "file")


def insert_after(pattern, text, what):
    global pbx
    match = re.search(pattern, pbx, flags=re.M)
    if not match:
        sys.exit(f"xcode_add_resource: couldn't find {what} in {pbx_path}")
    pbx = pbx[: match.end()] + text + pbx[match.end():]


# 1. File reference.
insert_after(
    r"/\* Begin PBXFileReference section \*/\n",
    f'\t\t{file_ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = {name}; sourceTree = "<group>"; }};\n',
    "the PBXFileReference section",
)
# 2. Build file.
insert_after(
    r"/\* Begin PBXBuildFile section \*/\n",
    f"\t\t{build_file} /* {name} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {name} */; }};\n",
    "the PBXBuildFile section",
)
# 3. The Runner group (the group whose path is Runner).
group = re.search(
    r"(\t\t[0-9A-F]{24} /\* Runner \*/ = \{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = \(\n)(.*?)(\t\t\t\);\n\t\t\tpath = Runner;)",
    pbx,
    flags=re.S,
)
if not group:
    sys.exit(f"xcode_add_resource: couldn't find the Runner group in {pbx_path}")
pbx = pbx[: group.end(1)] + f"\t\t\t\t{file_ref} /* {name} */,\n" + pbx[group.end(1):]
# 4. Runner's Resources phase: the one that already holds Assets.xcassets.
phases = list(
    re.finditer(
        r"(\t\t[0-9A-F]{24} /\* Resources \*/ = \{\n\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = \d+;\n\t\t\tfiles = \(\n)(.*?)(\t\t\t\);)",
        pbx,
        flags=re.S,
    )
)
runner = [p for p in phases if "Assets.xcassets in Resources" in p.group(2)]
if len(runner) != 1:
    sys.exit(f"xcode_add_resource: couldn't find Runner's Resources phase in {pbx_path}")
at = runner[0].end(1)
pbx = pbx[:at] + f"\t\t\t\t{build_file} /* {name} in Resources */,\n" + pbx[at:]

open(pbx_path, "w", encoding="utf-8").write(pbx)
print(f"{name} added to Runner's resources")
