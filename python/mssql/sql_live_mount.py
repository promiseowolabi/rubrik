import rubrik_cdm
import urllib3

urllib3.disable_warnings()

db_name = "AdventureWorks2016"
#db_name = 'chris'
sql_instance = 'MSSQLSERVER'
sql_host = 'em1-promowol-w1.rubrikdemo.com'
#sql_host = 'EM1-chrileco-w1'
mount_name = 'AdventureClone_log'
date = '02-06-2020'
time = '08:00 AM'

rubrik = rubrik_cdm.Connect(enable_logging=True)

sql_live_mount = rubrik.sql_live_mount(db_name, sql_instance, sql_host, mount_name)
