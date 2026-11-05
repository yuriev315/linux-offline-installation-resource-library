#!/usr/bin/env python3
"""Write a <file>.url placeholder beside each licence-restricted file. Each one is a normal Windows internet shortcut
with an extra [File] section giving the size and SHA256. Every URL is checked now and the result recorded."""
import hashlib, os, subprocess, sys, time
LIB = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), "../.."))
BROADCOM = "https://support.broadcom.com/group/ecx/productdownloads?subfamily=VMware%20Workstation%20Pro&freeDownloads=true"
VT = "https://packages.vmware.com/tools/releases/latest/windows/"
items = [
    ("03_VMWARE/workstation_installers/VMware-Workstation-Full-26H1u1-25688693.exe", BROADCOM, "no", "VMware Workstation Pro 26H1u1"),
    ("03_VMWARE/workstation_installers/VMware-Workstation-Full-26H1u1-25688693.x86_64.bundle", BROADCOM, "no", "VMware Workstation Pro 26H1u1"),
    ("03_VMWARE/vmware_tools/VMware-tools-windows-13.1.5-25544008.iso", VT + "VMware-tools-windows-13.1.5-25544008.iso", "yes", "VMware Tools"),
    ("03_VMWARE/vmware_tools/VMware-tools-windows-13.1.5-25544008.iso.sha", VT + "VMware-tools-windows-13.1.5-25544008.iso.sha", "yes", "VMware Tools"),
    ("03_VMWARE/vmware_tools/VMware-tools-windows-13.1.5-25544008.iso.sig", VT + "VMware-tools-windows-13.1.5-25544008.iso.sig", "yes", "VMware Tools"),
    ("02_WSL2/wsl_installers/wsl.3.0.3.0.x64.msi", "https://github.com/microsoft/WSL/releases/download/3.0.3/wsl.3.0.3.0.x64.msi", "yes", "Microsoft WSL"),
    ("02_WSL2/wsl_kernel/wsl_update_x64.msi", "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi", "yes", "Microsoft WSL kernel update"),
]
assets = {}
for line in open(f"{LIB}/15_DEVELOPMENT_ENVIRONMENT/editors/ASSETS.txt"):
    sub, name, sha, url = line.split()
    d = {"vscode": "vscode", "vscode_server": "vscode_server", "vsix": "vsix"}[sub]
    items.append((f"15_DEVELOPMENT_ENVIRONMENT/editors/{d}/{name}", url, "yes", "Visual Studio Code"))


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as o:
        for b in iter(lambda: o.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


today = time.strftime("%Y-%m-%d", time.gmtime())
rows = []
for rel, url, direct, work in items:
    p = f"{LIB}/{rel}"
    code = subprocess.run(["curl", "-sS", "-o", "/dev/null", "-L", "-m", "40", "-r", "0-0", "-A", "Mozilla/5.0", "-w", "%{http_code}", url], capture_output=True, text=True).stdout.strip()
    h = sha(p); size = os.path.getsize(p)
    note = "Open this page, sign in and download the file." if direct == "no" else "Direct download."
    checked = f"{today} HTTP {code}" + (" (sign-in page, refuses scripts)" if direct == "no" else "")
    with open(p + ".url", "w", newline="") as o:
        o.write(f"[InternetShortcut]\r\nURL={url}\r\n\r\n[File]\r\nName={os.path.basename(rel)}\r\nProduct={work}\r\nSizeBytes={size}\r\nSHA256={h}\r\nDirectDownload={direct}\r\nChecked={checked}\r\nNote={note} Not stored in this repository because of its licence. See 12_CHECKSUMS_AND_METADATA/LICENSES.md\r\n")
    rows.append((rel, url, direct, work, size, h, code))
    print(f"{code:>4} direct={direct:3} {size:>10} {rel}")
with open(f"{LIB}/.tools/restricted_files.tsv", "w") as o:
    for r in rows:
        o.write("\t".join(map(str, r)) + "\n")
bad = [r for r in rows if r[2] == "yes" and r[6] not in ("200", "206")]
print(f"{len(rows)} placeholders; direct URLs not reachable: {len(bad)}")
sys.exit(1 if bad else 0)
