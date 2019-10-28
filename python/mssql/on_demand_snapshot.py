import rubrik_cdm
import urllib3

urllib3.disable_warnings()

object_type = "mssql_db"
object_name = "AdventureWorks2016"
sql_instance = 'MSSQLSERVER'
sql_host = 'em1-promowol-w1.rubrikdemo.com'
sql_db = object_name

rubrik = rubrik_cdm.Connect(enable_logging=True)

snapshot = rubrik.on_demand_snapshot(object_name, object_type, sql_host=sql_host, sql_instance=sql_instance, sql_db=sql_db)
