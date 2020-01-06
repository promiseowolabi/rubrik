import rubrik_cdm
import urllib3

urllib3.disable_warnings()

rubrik = rubrik_cdm.Connect(enable_logging=True)

get_vsphere_vm = rubrik.get_vsphere_vm()

for item in get_vsphere_vm['data']:
    if item['effectiveSlaDomainName'] == 'Unprotected':
        print(item['name'])
