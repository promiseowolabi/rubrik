import rubrik_cdm
import urllib3
urllib3.disable_warnings()

rubrik = rubrik_cdm.Connect(enable_logging=True)

subnets = rubrik.set_esxi_subnets()

#subnets = rubrik.get_esxi_subnets()

print(subnets)

