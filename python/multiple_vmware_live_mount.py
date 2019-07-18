import rubrik_cdm
import urllib3
urllib3.disable_warnings()

vm_list = ['em1-promowol-l1', 'em1-promowol-w1']

rubrik = rubrik_cdm.Connect(enable_logging=True)

for name in vm_list:
    vm_name = name
    live_mount = rubrik.vsphere_live_mount(vm_name)