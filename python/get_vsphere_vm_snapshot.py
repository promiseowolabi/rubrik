import rubrik_cdm
import urllib3

urllib3.disable_warnings()

id = 'VirtualMachine:::2c5b7d05-5241-4534-8844-f47e6b0dd50d-vm-2799'
rubrik = rubrik_cdm.Connect(enable_logging=True)

get_vsphere_snapshot = rubrik.get_vsphere_vm_snapshot(id=id)
print(get_vsphere_snapshot)