import rubrik_cdm
import urllib3

urllib3.disable_warnings()

object_name = 'em1-promowol-l1'
sla_name = '4hr-30d-AWS'
object_type = 'vmware'

rubrik = rubrik_cdm.Connect(enable_logging=True)

assign_sla = rubrik.assign_sla(object_name = 'em1-promowol-l1', sla_name = '4hr-30d-AWS', object_type = 'vmware')

print(assign_sla)

