import rubrik_cdm
import urllib3

urllib3.disable_warnings()

rubrik = rubrik_cdm.Connect(enable_logging=True)

print(rubrik.on_demand_snapshot('em1-promowol-l1', 'vmware'))
