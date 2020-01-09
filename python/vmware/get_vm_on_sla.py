import rubrik_cdm
import urllib3

urllib3.disable_warnings()

rubrik = rubrik_cdm.Connect(enable_logging=True)

get_vm_sla = rubrik.get_sla_objects('4hr-30d-AWS', 'vmware')

for key, value in get_vm_sla.items():
    print(key, '->', value)
