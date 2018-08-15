#!/usr/bin/env python
""" Node label check for OpenShift V3 """

# Adding the ignore because it does not like the naming of the script
# to be different than the class name
# pylint: disable=invalid-name

# pylint: disable=wrong-import-position
# pylint: disable=broad-except
# pylint: disable=line-too-long

import argparse
import time

import logging
logging.basicConfig(
    format='%(asctime)s - %(relativeCreated)6d - %(levelname)-8s - %(message)s',
)
logger = logging.getLogger()
logger.setLevel(logging.WARN)

# Our jenkins server does not include these rpms.
# In the future we might move this to a container where these
# libs might exist
#pylint: disable=import-error

from openshift_tools.monitoring.ocutil import OCUtil
from openshift_tools.monitoring.metric_sender import MetricSender

ocutil = OCUtil()

def runOCcmd(cmd, base_cmd='oc'):
    """ log commands through ocutil """
    logger.info(base_cmd + " " + cmd)
    oc_time = time.time()
    oc_result = ocutil.run_user_cmd(cmd, base_cmd=base_cmd, )
    logger.info("oc command took %s seconds", str(time.time() - oc_time))
    return oc_result

def runOCcmd_yaml(cmd, base_cmd='oc'):
    """ log commands through ocutil """
    logger.info(base_cmd + " " + cmd)
    ocy_time = time.time()
    ocy_result = ocutil.run_user_cmd_yaml(cmd, base_cmd=base_cmd, )
    logger.info("oc command took %s seconds", str(time.time() - ocy_time))
    return ocy_result

def get_type(hostname):
    """get the host type , is the host is a master or node or a infra"""
    host_type = 'compute'
    if 'master' in hostname:
        host_type = 'master'
    elif 'infa' in hostname:
        host_type = 'infra'
    else:
        host_type = 'compute'

    return host_type

def check_label_on_host(labels):
    """according to the host type to check if the host missed any labels"""
    result = True
    hostname = labels['hostname']
    host_type = labels['type']
    # if the node miss the hostname and type label
    if hostname and host_type:
        pass
    else:
        return False

    # the next step is make sure all the node have all the label that in the directory
    need_labels = {}
    ban_labels = {}
    if host_type == 'master':
        need_labels = {
            #'beta.kubernetes.io/arch':'amd64',
            #'beta.kubernetes.io/instance-type': 'm4.xlarge',
            #'beta.kubernetes.io/os': 'linux',
            #'failure-domain.beta.kubernetes.io/region': 'us-east-1',
            #'failure-domain.beta.kubernetes.io/zone': 'us-east-1a',
            'hostname': 'zz-test-master-12356',
            'kubernetes.io/hostname': 'ip-10-147-203-48.ec2.internal',
            #'network.openshift.io/not-enforcing-egress-network-policy':'true',
            'node-role.kubernetes.io/master': "true",
            'region': 'us-east-1',
            'type': 'master',
        }

        ban_labels = {
            #'node-role.kubernetes.io/master': "true",
            'node-role.kubernetes.io/infra': "true",
            'node-role.kubernetes.io/compute': "true",
        }
    elif host_type == 'infra':
        # seems the infra node and compute node have the same labels
        need_labels = {
            #'beta.kubernetes.io/arch': 'amd64',
            #'beta.kubernetes.io/instance-type': 'r4.xlarge',
            #'beta.kubernetes.io/os': 'linux',
            #'failure-domain.beta.kubernetes.io/region': 'us-east-1',
            #'failure-domain.beta.kubernetes.io/zone': 'us-east-1a',
            'hostname': 'zz-node-infra-234df',
            'kubernetes.io/hostname': 'ip-10-147-203-16.ec2.internal',
            #'logging-infra-fluentd': "true",
            'node-role.kubernetes.io/infra': "true",
            'region': 'us-east-1',
            'type': 'infra',
        }

        ban_labels = {
            'node-role.kubernetes.io/master': "true",
            #'node-role.kubernetes.io/infra': "true",
            'node-role.kubernetes.io/compute': "true",
        }
    else:
        # seems the infra node and compute node have the same labels
        need_labels = {
            #'beta.kubernetes.io/arch': 'amd64',
            #'beta.kubernetes.io/instance-type': 'r4.xlarge',
            #'beta.kubernetes.io/os': 'linux',
            #'failure-domain.beta.kubernetes.io/region': 'us-east-1',
            #'failure-domain.beta.kubernetes.io/zone': 'us-east-1a',
            'hostname': 'zz-node-infra-234df',
            'kubernetes.io/hostname': 'ip-10-147-203-16.ec2.internal',
            #'logging-infra-fluentd': "true",
            'node-role.kubernetes.io/compute': "true",
            'region': 'us-east-1',
            'type': 'compute',
        }

        ban_labels = {
            'node-role.kubernetes.io/master': "true",
            'node-role.kubernetes.io/infra': "true",
            #'node-role.kubernetes.io/compute': "true",
        }

    for key, value in need_labels.iteritems():
        # check if this node current has all the key we need
        logger.debug("-----> checking the label: [" + key + "]")
        if labels.has_key(key):
            logger.debug("Reuslt: [" + str(labels.has_key(key)) + "] Current node Value: [" + labels[key] + "] Target value: [" + value + "]")
        else:
            # as long as one key is missed ,we think this node is wrong
            logger.info('This node '+ hostname + ' lack of label: [' + key + ']')
            result = False

    for key, value in ban_labels.iteritems():
        # check if this node current has all the key we need
        logger.debug("-----> checking the label: [" + key + "]")
        if labels.has_key(key):
            # as long as one key is missed ,we think this node is wrong
            logger.info('This node '+ hostname + ' lack of label: [' + key + ']')
            result = False
        else:
            logger.debug("Reuslt: [" + str(labels.has_key(key)) + "] Current node Value: [" + labels[key] + "] Target value: [" + value + "]")

    return result

def parse_args():
    """ parse the args from the cli """
    parser = argparse.ArgumentParser(description='Check all the nodes label Status')
    parser.add_argument('-v', '--verbose', action='count', default=0,
                        help='verbosity level, specify multiple')
    parser.add_argument('--namespace', default="default", help='service namespace')

    args = parser.parse_args()

    if args.verbose > 0:
        logger.setLevel(logging.INFO)

    if args.verbose > 1:
        logger.setLevel(logging.DEBUG)

    return args

def check_label_status():
    """get all the info of all node """
    result_ip = 0
    result_status = 0
    label_info = runOCcmd_yaml("get node ")
    for item in label_info['items']:
        labels = item['metadata']['labels']

        #if the check result shows this node have all the label
        if check_label_on_host(labels):
            pass
        else:
            result_status = result_status + 1

    #if everything fine , result_ip and result_status both should 0 , if not 0 , means something wrong
    return result_ip + result_status

def main():
    """ check all the node labels see if anything miss """
    args = parse_args()
    logger.debug("args: ")
    logger.debug(args)

    #result = test_saml_pod(args=args, )
    label_status = check_label_status()

    #send the value to zabbix
    mts = MetricSender(verbose=args.verbose)
    mts.add_metric({'openshift.nodes.label.status': label_status})
    mts.send_metrics()

if __name__ == "__main__":
    main()
