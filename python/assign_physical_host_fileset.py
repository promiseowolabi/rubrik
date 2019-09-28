import rubrik_cdm
import urllib3

urllib3.disable_warnings()

fileset_name = 'Everything'
sla_name = '1d-30d-NoArchive'
operating_system = 'NONE'
hostname = 'emea1-ntap01.rubrikdemo.com'


rubrik = rubrik_cdm.Connect(enable_logging=True)

assign_sla = rubrik.assign_physical_host_fileset(hostname, fileset_name, operating_system, sla_name)

print(assign_sla)

