#!/usr/bin/python3

import json
import pprint as pp
import requests
import sys

# simple python file containing webhook url in a 'url' variable
import slack_webhook

def check(j,ln,f):

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
    policies = j['auth']['policies']

    alert_msgs = []

    # Alert if polices from alert_policies are used
    for policy in policies:
        if policy in alert_policies:
            alert_msgs.append('%s policy used' % policy)

    # Alert if namespaces from alert_namespaces are used
    for alert_namespace in alert_namespaces:
        if namespace == alert_namespace:
            alert_msgs.append('%s namespace used' % namespace)

    if path.startswith('secret/data/emergency-only'):
            alert_msgs.append('sensitive path accessed: %s' % path)

    if namespace == 'prod/' and path.startswith('secret/data/never-use'):
            alert_msgs.append('namespace %s, path %s accessed' % ('prod',path))

    if namespace == 'prod-us/' and path.startswith('pki/issue/hashicorp-test-dot-com'):
            alert_msgs.append('namespace %s, path %s accessed' % ('prod-us',path))

    if alert_msgs:
        alert_slack(j,ln,alert_msgs)


def alert_slack(j,ln,alert_msgs):

    try:
        payload = '{"text":"ALERT: %s, request_id: %s "}' % (alert_msgs,j['request']['id'])
        headers = {'Content-type': 'application/json'}
        r = requests.post(slack_webhook.url, headers=headers, data=payload)

        # TODO - figure out how to post the full audit entry, nicely formatted
        #unquoted = ln.replace('"','')
        #payload = '{"text":"%s"}' % unquoted
        #r = requests.post(slack_webhook.url, headers=headers, data=payload)
    except Exception as e:
        print(e)


def read_stdin():
    with open('log.json', 'a') as f:

        ln = sys.stdin.readline().rstrip()
        while ln:
            try:
                j = json.loads(ln)
                check(j,ln,f)
            except Exception as e:
                pass
                #print(e)
            ln = sys.stdin.readline().rstrip()

if __name__ == '__main__':
    read_stdin()
