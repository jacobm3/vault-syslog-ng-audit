#!/usr/bin/python3

import argparse
import configparser
import pprint as pp
import re
import requests
import sys
import time

# COL1 = alert title
# COL2 = regex pattern to alert on
# COL3 = regex pattern to exclude from alerts (or False if no exclusion needed)
re_pattern_list = [
('kernel booting', r'kernel: Booting Linux', False),
('Fail', r'fail', r'plugin'),
('Error', r'error', False),
]

def options():
    'Parse command line options with argparse.'

    global args,config
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", dest="debug", action='store_true', help="print debug information")
    parser.add_argument("-c", dest="configpath", default='/usr/local/etc/vault-log-handler.ini', help='config file path')
    args = parser.parse_args()

    # if not options.feedlistfile:
    #     print("\nError: Must specify -l <feed list file>\n")
    #     parser.print_help()
    #     sys.exit(1)

    config = configparser.ConfigParser()
    config.read(args.configpath)


def load_re_list():
    'Builds a global re_obj_list containing a list of alert titles and regex objects to match them.'

    global re_obj_list

    # [ ['TITLE', regex_obj] ]
    re_obj_list = []
    for row in re_pattern_list:
        exclude_re = False
        if row[2]:
            exclude_re = re.compile(row[2],re.I)
        re_obj_list.append( [ row[0], re.compile(row[1],re.I), exclude_re ] )

    #print(re_obj_list)

def check(ln):
    for row in re_obj_list:
        m = row[1].search(ln)
        if m:

            # alert if an exclude_re is present and it fails to match
            if row[2]:
                m2 = row[2].search(ln)
                if not m2:
                    alert(row[0],ln)

            # also alert if row[1] matched and no exclude_re is defined
            else:
                alert(row[0],ln)

def alert(title,ln):
    msg = 'IGNORE TEST ALERT: %s, MSG: %s' % (title,ln)
    print(msg)
    #alert_slack(msg)
    #alert_webex(msg)

def alert_slack(msg):
    try:
        payload = '{"text":"%s"}' % msg
        headers = {'Content-type': 'application/json'}
        r = requests.post(config['slack']['url'], headers=headers, data=payload)
    except Exception as e:
        print(e)

def alert_webex(msg):
    try:
        payload = '{"markdown":"%s"}' % msg
        headers = {'Content-type': 'application/json'}
        r = requests.post(config['webex']['url'], headers=headers, data=payload)
    except Exception as e:
        print(e)

def read_stdin():
    ln = sys.stdin.readline().rstrip()
    while ln:
        try:
            check(ln)
        except Exception as e:
            pass
        ln = sys.stdin.readline().rstrip()

if __name__ == '__main__':
    options()
    load_re_list()
    read_stdin()
