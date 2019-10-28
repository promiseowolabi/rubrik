import rubrik_cdm
import urllib3
urllib3.disable_warnings()

vm_name = "em1-promowol-l1"

rubrik = rubrik_cdm.Connect(enable_logging=True)

rubrik.vcenter_refresh_vm(vm_name)