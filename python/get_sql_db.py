import rubrik_cdm
import urllib3

urllib3.disable_warnings()

name = 'AdventureWorks2016_EXT'
instance = 'MSSQLSERVER'
hostname = 'em1-promowol-w1.rubrikdemo.com'

rubrik = rubrik_cdm.Connect(enable_logging=True)

get_db = rubrik.get_sql_db(name=name, instance=instance, hostname=hostname)#, instance=instance hostname=hostname)

print(get_db)
