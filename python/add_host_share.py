import rubrik_cdm
import urllib3

urllib3.disable_warnings()

hostname = 'emea1-ntap01.rubrikdemo.com'
share_type = 'NFS'
export_point = '/ntap_restore'

rubrik = rubrik_cdm.Connect(enable_logging=True)

add_host_share = rubrik.add_host_share(hostname, share_type, export_point)
print(add_host_share)
