import rubrik_cdm
import urllib3

urllib3.disable_warnings()
rubrik = rubrik_cdm.Connect(enable_logging=True)

hostname = 'emea1-ntap01.rubrikdemo.com'

id = rubrik.object_id('ntap_smb', 'share', hostname=hostname, share_type='SMB')

print(id)