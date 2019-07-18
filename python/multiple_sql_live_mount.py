# Create a db live mount for each point in time in a list
# Use case: compare records in a database over time

import rubrik_cdm
import urllib3

urllib3.disable_warnings()

db_name = "AdventureWorks2016"
sql_instance = 'MSSQLSERVER'
sql_host = 'em1-promowol-w1.rubrikdemo.com'

recovery_point = { 'earliest_clone': {'date':'07-11-2019', 'time':'01:30 AM'}, 'latest_clone': {'date':'07-13-2019', 'time':'01:30 AM'}}

rubrik = rubrik_cdm.Connect(enable_logging=True)

for point, date_time in recovery_point.items():
    #for datetime in date_time:
        #print(date_time[datetime])
    date = date_time['date']
    time = date_time['time']
    mount_name = point

    #print(date, time)
    #print(mount_name)
    sql_live_mount = rubrik.sql_live_mount(db_name, date, time, sql_instance, sql_host, mount_name)
