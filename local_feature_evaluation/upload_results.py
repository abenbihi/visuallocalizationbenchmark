"""
Author: Tomas Jenicek
"""
import argparse
import sys
import requests
from bs4 import BeautifulSoup

parser = argparse.ArgumentParser()
parser.add_argument("--session_id", required=True, type=str)
parser.add_argument("--method_name", required=True, type=str)
parser.add_argument("--result_path", required=True, type=str)
args = parser.parse_args()

#session = "4d3btcg5rfkjv0pn6mk7j4jml473zz9r"
session = args.session_id

resp = requests.get("https://www.visuallocalization.net/submission/",
        headers={"Cookie": f"sessionid={session}"})

bs = BeautifulSoup(resp.content, features="html.parser")
csrf = bs.select('form > input[name="csrfmiddlewaretoken"]')[0].attrs['value']

url = "https://www.visuallocalization.net/submission/"

headers = {
        "Cookie": f"csrftoken={resp.cookies['csrftoken']}; sessionid={session}",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36",
}

data = {
        "csrfmiddlewaretoken": csrf,
        "method_name": args.method_name, #"test",
        "publication_url": "",
        "code_url": "",
        "info_field": "",
        "dataset": "aachen",
        "workshop_submission": "default",
}

files = {
        #"result_file": open("/home/abenbihi/ws/tools/vlb/local_feature_evaluation/res/aachen/anubis/38/Aachen_eval_anubis.txt", "r"),
        "result_file": open(args.result_path, "r"),
}

resp = requests.post(url, files=files, data=data, headers=headers)

print(resp.status_code)
