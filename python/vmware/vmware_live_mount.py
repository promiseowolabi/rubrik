import rubrik_cdm
import urllib3
urllib3.disable_warnings()

vm_name = "em1-promowol-l1"

rubrik = rubrik_cdm.Connect(enable_logging=True)

live_mount = rubrik.vsphere_live_mount('em1-promowol-l1')

print(live_mount)