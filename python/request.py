import requests
import sys
import json
from requests.auth import HTTPBasicAuth


# Cluster IP Address and Credentials
NODE_IP = "demo.rubrik.com"
USERNAME = "promise@demo.com"
PASSWORD = "password"


def login_token(username, password):
    """ Generate a new API Token """

    api_version = "v1"
    api_endpoint = "/session"

    request_url = "https://{}/api/{}{}".format(NODE_IP, api_version, api_endpoint)

    data = {'username': username, 'password': password}

    authentication = HTTPBasicAuth(username, password)

    try:
        api_request = requests.post(request_url, data=json.dumps(data), verify=False, auth=authentication)
    except requests.exceptions.ConnectionError as connection_error:
        print(connection_error)
        sys.exit()
    except requests.exceptions.HTTPError as http_error:
        print(http_error)
        sys.exit()

    response_body = api_request.json()

    if 'token' in response_body:
        return response_body['token']
    else:
        print('The response body did not contain the expected token.\n')
        print(response_body)

token = login_token(USERNAME, PASSWORD)

AUTHORIZATION_HEADER = {'Content-Type': 'application/json',
                        'Accept': 'application/json',
                        'Authorization': 'Bearer ' + token
                        }

api_version = "v1"
api_endpoint = "/vmware/vm"

request_url = "https://{}/api/{}{}".format(NODE_IP, api_version, api_endpoint)

api_request = requests.get(request_url, verify=False, headers=AUTHORIZATION_HEADER)

response_body = api_request.json()

print(response_body)

