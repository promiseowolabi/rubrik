import rubrik_cdm
import urllib3

urllib3.disable_warnings()

sql_instance = 'MSSQLSERVER'
sql_host = 'em1-promowol-w1.rubrikdemo.com'
mounted_db_name = 'latest_clone'

rubrik = rubrik_cdm.Connect(enable_logging=True)

sql_live_unmount = rubrik.sql_live_unmount(mounted_db_name, sql_instance, sql_host)
