## Manage DAOS system with Ansible

### Ansible

Ansible is used to upload files to or run the same command on all the nodes  simultaneously.

Assume the current path is `ansible/playbooks`.

Dry run:
`ansible-playbook -i ../daos.ini <playbook>.yml --check`

Real Run:
`ansible-playbook -i ../daos.ini <playbook>.yml`

### Bring up the DAOS storage nodes
#### Start from a fresh state
1. Install daos_server on all the nodes. Make sure IPoIB and [95-daos.conf](../daos/95-daos.conf) are configured.
2. Sync the DAOS server configuration file [daos_server.yml](../daos/daos_server.yml) across all the storage nodes.
3. Ensure the certification files under `/etc/daos/certs` are owned by `daos_server:daos_server`.
4. Start the daos_server service via [systemctl](./playbooks/sync_server_config.yml).
5. On the Admin node, make sure the ownership of the certifications is set to `${USER}:scitestbed`.
6. On the Admin node:
    - Configure `daos_control.yml` under `/etc/daos` according to the server status.
    - Scan the storage: `dmg storage scan`. Make sure all the nodes get their corresponding 2 ranks.
    - Format (for the first time): `dmg storage format`. After this command, the system should already been started.
    - Check the system status: `dmg system query --verbose`. Make sure we get all the access points we want.
#### Add a node to the existing system.
1. Update `daos_server.yml`, `daos_agent.yml` and `daos_control.yml` across the system.
2. Configure the certification of the new storage node.
3. Format the new node's storage: `dmg storage format -l <new-node>`. After a while, check if the new node is in the system: `dmg system query --verbose`.

#### Common bugs 

If `daos_server` is running correctly, the output of `sudo systemctl status daos_server` looks like below:
```
[xmei@daosfs01 ~]$ sudo systemctl status daos_server
● daos_server.service - DAOS Server
   Loaded: loaded (/usr/lib/systemd/system/daos_server.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2025-02-14 21:07:46 EST; 2h 3min ago
 Main PID: 77756 (daos_server)
    Tasks: 87 (limit: 3296357)
   Memory: 19.3G
   CGroup: /system.slice/daos_server.service
           ├─77756 /usr/bin/daos_server start
           ├─79796 /usr/bin/daos_engine -t 16 -x 4 -g daos_server -d /var/run/daos_server -T 3 -n /home/daos_server/control_meta/daos_control/engine0/daos_nvm>
           └─79803 /usr/bin/daos_engine -t 16 -x 4 -g daos_server -d /var/run/daos_server -T 3 -n /home/daos_server/control_meta/daos_control/engine1/daos_nvm>

```
Other outputs are suspicious. If `/tmp/daos_server.log` does not have error information, check `/tmp/daos_engine_x.log`.

Common issues are related to:
- NUMA setting.
- IPoIB addresses. IB devices.
- Ownership of the files at `/var/run/daos_server`, `/home/daos_server`, `/tmp/daos_xxx.log`, etc.

### References
- [My longer note](https://docs.google.com/document/d/1upT924JX0lXoRmV8sSkYTpu0KBJv6O16h5nIkbPeKbg/edit?usp=sharing)
- DAOS official document: https://docs.daos.io/v2.6/QSG/setup_rhel/
