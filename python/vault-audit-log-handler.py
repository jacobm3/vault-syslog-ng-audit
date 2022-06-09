#!/usr/bin/python3

import argparse
import configparser
import json
import pprint as pp
import requests
import sys
import traceback

def options():
    'Parse command line options with argparse.'

    global args,config
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", dest="debug", action='store_true', help="print debug information")
    parser.add_argument("-c", dest="configpath", help='config file path')
    args = parser.parse_args()

    # if not options.feedlistfile:
    #     print("\nError: Must specify -l <feed list file>\n")
    #     parser.print_help()
    #     sys.exit(1)

    config = configparser.ConfigParser()
    config.read(args.configpath)

def check(j,ln):

    # any audit log entries with these policies or namespaces will generate an alert
    alert_policies = ['root','some-other-policy']
    alert_namespaces = ['break-glass']

    # Parse commonly referenced parameters for easy reference
    path = j['request']['path']
    policies = j['auth']['policies']

    # Namespace section not present with Vault OSS
    namespace = None
    try:
        namespace = j['request']['namespace']['path']
    except Exception:
        pass

    path = j['request']['path']

    # Policies only present on authn calls
    policies = []
    try:
        policies = j['auth']['policies']
    except KeyError as e:
        pass

    alert_msgs = []

    # Alert if polices from alert_policies are used
    for policy in policies:
        if policy in alert_policies:
            alert_msgs.append('%s policy used' % policy)

    # Alert if namespaces from alert_namespaces are used
    for alert_namespace in alert_namespaces:
        if namespace == alert_namespace:
            alert_msgs.append('%s namespace used' % namespace)

    if path.startswith('sys/generate-root'):
            alert_msgs.append('Root token generation path accessed: %s' % path)

    if path.startswith('secret/data/emergency-only'):
            alert_msgs.append('sensitive path accessed: %s' % path)

    if namespace == 'prod/' and path.startswith('secret/data/never-use'):
            alert_msgs.append('namespace %s, path %s accessed' % ('prod',path))

    if namespace == 'prod-us/' and path.startswith('pki/issue/hashicorp-test-dot-com'):
            alert_msgs.append('namespace %s, path %s accessed' % ('prod-us',path))

    if alert_msgs:
        if args.debug: print('check():',alert_msgs)
        alert_slack(j,ln,alert_msgs)


def alert_slack(j,ln,alert_msgs):
    if args.debug: print('alert_slack():',alert_msgs)
    try:
        payload = '{"text":"ALERT: %s, request_id: %s "}' % (alert_msgs,j['request']['id'])
        headers = {'Content-type': 'application/json'}
        r = requests.post(config['slack']['url'], headers=headers, data=payload)

        # TODO - figure out how to post the full audit entry, nicely formatted
        #unquoted = ln.replace('"','')
        #payload = '{"text":"%s"}' % unquoted
        #r = requests.post(slack_webhook.url, headers=headers, data=payload)
    except Exception as e:
        pass
        #print(e)


def read_stdin():
    ln = sys.stdin.readline().rstrip()
    while ln:
        try:
            j = json.loads(ln)
            check(j,ln)
        except Exception as e:
            pass
            #traceback.print_exc()
        ln = sys.stdin.readline().rstrip()

if __name__ == '__main__':
    options()
    read_stdin()
