import rubrik_cdm
import urllib3

urllib3.disable_warnings()

name = 'em1-promowol-l1'
rubrik = rubrik_cdm.Connect(enable_logging=True)

get_vsphere_snapshot = rubrik.get_vsphere_vm_snapshot(vm_name=name)
print(get_vsphere_snapshot)