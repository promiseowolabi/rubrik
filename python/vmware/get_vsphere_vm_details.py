import rubrik_cdm
import urllib3

urllib3.disable_warnings()
rubrik = rubrik_cdm.Connect(enable_logging=True)

name = 'em1-promowol-l1'

get_vsphere_vm_details = rubrik.get_vsphere_vm_details(vm_name=name)

print(get_vsphere_vm_details)