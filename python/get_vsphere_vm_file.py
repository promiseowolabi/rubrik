import rubrik_cdm
import urllib3

urllib3.disable_warnings()
rubrik = rubrik_cdm.Connect(enable_logging=True)

name = 'em1-promowol-l1'
path = '/etc/hosts'

get_vsphere_vm_file = rubrik.get_vsphere_vm_file(name, path=path)

files = get_vsphere_vm_file['data'][0]['fileVersions']
for file in files:
    print(file['lastModified'])