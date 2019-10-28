import rubrik_cdm
import urllib3

urllib3.disable_warnings()

db_name = "AdventureWorks2016"
sql_instance = 'MSSQLSERVER'
sql_host = 'em1-promowol-w1.rubrikdemo.com'
date = '08-20-2019'
time = '08:38 AM'

rubrik = rubrik_cdm.Connect(enable_logging=True)

sql_instant_recovery = rubrik.sql_instant_recovery(db_name, date, time, sql_instance, sql_host)

print(sql_instant_recovery)