import rubrik_cdm
import urllib3

urllib3.disable_warnings()

db_name = "AdventureWorks2016"
sql_instance = 'MSSQLSERVER'
sql_host = 'em1-promowol-w1.rubrikdemo.com'

rubrik = rubrik_cdm.Connect(enable_logging=True)

sql_live_mount = rubrik.get_sql_live_mount(db_name, sql_instance, sql_host)

print(sql_live_mount['data'][0]['mountedDatabaseName'])
