import rubrik_cdm
import urllib3
urllib3.disable_warnings()

node_ip = '10.10.10.10'
username = 'demo@rubrikdemo.com'
password = 'password'
vm_name = "em1-promowol-l1"

rubrik = rubrik_cdm.Connect(node_ip, username, password, enable_logging=True)

cluster_version = rubrik.cluster_version()
print(cluster_version)

#instant_recovery = rubrik.vsphere_instant_recovery(vm_name, date, time)

live_mount = rubrik.vsphere_live_mount(vm_name, date='06-24-2018', time='12:00 AM')