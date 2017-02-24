#!/usr/bin/python
# -*- coding: utf8 -*-
#
# Ansible dynamic inventory script for reading from a Tower SCM project
# Requires: ansible, ansible-tower-cli
#
#    Copyright © 2016 Red Hat, Inc.
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

import os
import sys

import json
import urllib

from ansible.inventory import Group
from ansible.inventory.ini import InventoryParser as InventoryINIParser
from tower_cli import api


# Standard Tower project base path
BASE_PATH="/var/lib/awx/projects"

def rest_get(request):
    c = api.Client()
    response = c.get(request)
    if response.ok:
        j = response.json()
        if j.has_key('results'):
            return j['results'][0]
        else:
            return j
    else:
        return None

# Get ID from project name
def get_project_id(project):
    result = rest_get("projects/?name=%s" % (project,))
    if result:
        return result['id']
    else:
        return None

# If a project update is running, wait up two minutes for it to finish
def wait_for_project_update(project_id):
    retries = 120
    
    while retries > 0:
        result = rest_get("projects/%d" %(project_id,))
        if not result:
            return
        if not result['related'].has_key('current_update'):
            return
        sleep(1)
        retries = retries - 1
    return

# Find the toplevel path to the synced project's on-disk location
def get_file_path(project_id):
    result = rest_get("projects/%d" % (project_id,))
    if not result:
        return None
    return '%s/%s' % (BASE_PATH, result['local_path'])

# Read and parse inventory
def read_file(project_id, inv_file):
    file_path = get_file_path(project_id)
    if not file_path:
        return ""
    group = Group(name='all')
    groups = { 'all': group }
    parser = InventoryINIParser([], groups, filename = "%s/%s" %(file_path, inv_file))
    return groups

# Convert inventory structure to JSON
def dump_json(inventory):
    ret = {}
    for group in inventory.values():
        if group.name == 'all':
            continue
        g_obj = {}
        g_obj['children'] = []
        for child in group.child_groups:
            g_obj['children'].append(child.name)
        g_obj['hosts'] = []
        for host in group.hosts:
            g_obj['hosts'].append(host.name)
        g_obj['vars'] = group.vars
        ret[group.name] = g_obj
    meta = { 'hostvars': {} }
    for host in inventory['all'].get_hosts():
        if not meta['hostvars'].has_key(host.name):
            meta['hostvars'][host.name] = host.vars
        else:
            meta['hostvars'][host.name].update(host.vars)
    ret['_meta'] = meta
    return json.dumps(ret)

try:
    project_name=os.environ.get("PROJECT_NAME")
except:
    project_name="Test project"
try:
    file_name=os.environ.get("INVENTORY_FILE")
except:
    file_name="inventory"


if len(sys.argv) > 1 and sys.argv[1] == '--list':
    project_id = get_project_id(project_name)
    if not project_id:
        sys.stderr.write("Could not find project '%s'\n" %(project_name,))
        sys.exit(1)

    wait_for_project_update(project_id)

    inv_contents = read_file(project_id, file_name)
    if not inv_contents:
        sys.stderr.write("Parse of inventory file '%s' in project '%s' failed\n" %(file_name, project_name))
        sys.exit(1)

    json_inv = dump_json(inv_contents)
    print json_inv
    sys.exit(0)
