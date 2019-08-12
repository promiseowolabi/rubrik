import rubrik_cdm
import urllib3
urllib3.disable_warnings()

vm_name = "em2-nikgrove-l1"

rubrik = rubrik_cdm.Connect(enable_logging=True)

live_mount = rubrik.get_vsphere_live_mount(vm_name)

print(live_mount)