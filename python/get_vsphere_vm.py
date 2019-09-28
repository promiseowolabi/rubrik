import rubrik_cdm
import urllib3

urllib3.disable_warnings()

rubrik = rubrik_cdm.Connect(enable_logging=True)

get_vsphere_vm = rubrik.get_vsphere_vm(limit=1, sort_order='asc')
print(get_vsphere_vm)