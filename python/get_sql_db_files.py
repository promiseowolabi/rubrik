import rubrik_cdm
import urllib3

urllib3.disable_warnings()

name = 'AdventureWorks2016'
instance = 'MSSQLSERVER'
hostname = 'em1-promowol-w1.rubrikdemo.com'

rubrik = rubrik_cdm.Connect(enable_logging=True)

get_db_files = rubrik.get_sql_db_files(name, '10-14-2019', '3:00 PM', instance, hostname)#, instance=instance hostname=hostname)

print(get_db_files)
