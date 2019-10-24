import urllib3
import rubrik_cdm

urllib3.disable_warnings()

rubrik = rubrik_cdm.Connect(enable_logging=True)

api_endpoint = '/cluster/me/version'
api_version = 'v1'

api_validation = rubrik._api_validation(api_version, api_endpoint)

print(api_validation)
