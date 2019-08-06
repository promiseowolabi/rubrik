import rubrik_cdm
import urllib3

urllib3.disable_warnings()

db_name = "AdventureWorks2016"
sql_instance = 'MSSQLSERVER'
sql_host = 'em1-promowol-w1.rubrikdemo.com'
mount_name = 'AdventureClone'
date = '07-19-2019'
time = '01:30 AM'

rubrik = rubrik_cdm.Connect(enable_logging=True)

sql_live_mount = rubrik.sql_live_mount(db_name, date, time, sql_instance, sql_host, mount_name)
