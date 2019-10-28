import rubrik_cdm
import urllib3

urllib3.disable_warnings()

object_name = 'Everything'
sla_name = '1d-30d-NoArchive'
object_type = 'fileset'
nas_host = 'emea1-ntap01.rubrikdemo.com'
share = '/ntap_restore'

rubrik = rubrik_cdm.Connect(enable_logging=True)

#assign_sla(self, object_name, sla_name, object_type, log_backup_frequency_in_seconds=None, log_retention_hours=None, copy_only=None, windows_host=None, nas_host=None, share=None, timeout=30)

assign_sla = rubrik.assign_sla(object_name, sla_name, object_type, nas_host=nas_host, share=share)

print(assign_sla)

