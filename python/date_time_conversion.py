import rubrik_cdm
import urllib3

urllib3.disable_warnings()

date = '13-10-2019'
time = '10:15 AM'

rubrik = rubrik_cdm.Connect(enable_logging=True)

get_db = rubrik._date_time_conversion(date=date, time=time)#, instance=instance hostname=hostname)

print(get_db)
