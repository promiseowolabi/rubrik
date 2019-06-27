import rubrik_cdm
import urllib3

urllib3.disable_warnings()

node_ip = '10.10.10.10'
username = 'demo@rubrikdemo.com'
password = 'password'
sql_db = "AdventureWorks2016"
sql_instance = 'MSSQLSERVER'
sql_host = 'em1-promowol-w1.rubrikdemo.com'
clone_name = 'AdventureCLone'
date = '6-27-2019'
time = '12:11 PM'

rubrik = rubrik_cdm.Connect(node_ip, username, password, enable_logging=True)

sql_live_mount = rubrik.sql_live_mount(sql_db, sql_instance, sql_host, clone_name, date, time)
