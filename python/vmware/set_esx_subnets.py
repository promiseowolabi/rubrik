import rubrik_cdm
import urllib3
urllib3.disable_warnings()

rubrik = rubrik_cdm.Connect(enable_logging=True)

rubrik.set_esx_subnets()

subnets = rubrik.get_esx_subnets()

print(subnets)