import rubrik_cdm
import urllib3

urllib3.disable_warnings()
rubrik = rubrik_cdm.Connect(enable_logging=True)

object_name = "ntap_smb"
object_type = "share"
fileset = "everything"
hostname = "emea1-ntap01.rubrikdemo.com"
share_type = "SMB"
on_demand_share = rubrik.on_demand_snapshot(object_name, object_type, fileset=fileset, hostname=hostname, share_type=share_type)

print(on_demand_share)