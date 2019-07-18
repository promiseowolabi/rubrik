import rubrik_cdm
import urllib3
urllib3.disable_warnings()

mounted_vm_name = "em1-promowol-l1 07-16 15:33 0"

rubrik = rubrik_cdm.Connect(enable_logging=True)

live_mount = rubrik.vsphere_live_unmount(mounted_vm_name)
