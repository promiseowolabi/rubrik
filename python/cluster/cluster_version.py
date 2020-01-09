import rubrik_cdm
import urllib3

urllib3.disable_warnings()

rubrik = rubrik_cdm.Connect(enable_logging=True)

print(rubrik.cluster_version())
