#!/usr/bin/python3

import argparse
import configparser
import json
import pprint as pp
import re
import requests
import sys


# list of regex object/alert msg tuples which will be used to identify alert conditions
alert_re_list = []
alert_re_list.append((re.compile(r'vault.*root token generated'),'Root token generated'))
alert_re_list.append((re.compile(r'vault.*enabled credential backend'),'Auth method enabled'))
alert_re_list.append((re.compile(r'vault.*vault is sealed'),'Vault sealed'))
alert_re_list.append((re.compile(r'vault.*vault is unsealed'),'Vault unsealed'))
alert_re_list.append((re.compile(r'vault.*Vault shutdown triggered'),'Vault shutdown'))
alert_re_list.append((re.compile(r'vault.*root generation initialized'),'Root token generation initiated'))
alert_re_list.append((re.compile(r'vault.*root generation finished'),'Root token generation finished'))
alert_re_list.append((re.compile(r'vault.*core: rekey initialized'),'Vault security barrier rekey process initialized'))
alert_re_list.append((re.compile(r'vault.*core: security barrier rekeyed'),'Vault security barrier successfully rekeyed'))
alert_re_list.append((re.compile(r'vault.*core: security barrier initialized'),'Vault security barrier initialized'))

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


def check(ln):

    alert_msgs = []
    for alert_re in alert_re_list:
        m = alert_re[0].search(ln)
        if m:
            alert_msgs.append(alert_re[1])

    if alert_msgs:
        #print('ALERT:',alert_msgs,ln)
        alert_slack('ALERT: %s %s' % (alert_msgs,ln))

def alert_slack(msg):

    try:
        payload = '{"text":"%s"}' % msg
        headers = {'Content-type': 'application/json'}
        r = requests.post(config['slack']['url'], headers=headers, data=payload)
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
    read_stdin()
