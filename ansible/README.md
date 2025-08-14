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
4. Start the daos_server service via [systemctl](./playbooks/systemd_start_server.yml).
5. On the Admin node, make sure the ownership of the certifications is set to `${USER}:scitestbed`.
6. On the Admin node:
    - Configure `daos_control.yml` under `/etc/daos` according to the server status.
    - Scan the storage: `dmg storage scan`. Make sure all the nodes get their corresponding 2 ranks.
    - Format (for the first time): `dmg storage format`. After this command, the system should already been started.
    - Check the system status: `dmg system query --verbose`. Make sure we get all the access points we want.
#### Add a node to the existing system.
1. Update `daos_server.yml`, `daos_agent.yml` and `daos_control.yml` across the system.
2. Configure the certification of the new storage node.
3. Format the new node's storage: `dmg storage format -l <new-node>`. *After a while*, check if the new node is in the system: `dmg system query --verbose`.

```bash
# On the DAOS Admin node
[xmei@daos-adm ~]$ dmg system query --verbose
Rank UUID                                 Control Address     Fault Domain       State  Reason 
---- ----                                 ---------------     ------------       -----  ------ 
0    81971ecf-59d8-47fc-acd2-fec985e4e3ed 129.57.178.24:10001 /daosfs01          Joined        
1    0387c89d-4736-4904-ace2-f40ffcb7e47d 129.57.178.24:10001 /daosfs01          Joined        
2    19595070-bd13-4fbe-8cd8-d37286ab9218 129.57.178.25:10001 /daosfs02.jlab.org Joined        
3    7ff3da9d-fd5a-4dbb-b86f-d15f704fef99 129.57.178.29:10001 /daosfs06.jlab.org Joined        
4    439ba6d3-5a0b-4294-9665-e65bf4ea366a 129.57.178.25:10001 /daosfs02.jlab.org Joined        
5    d54255cc-4927-469b-b579-8038e245217d 129.57.178.26:10001 /daosfs03.jlab.org Joined        
6    71920a92-abf7-4da6-8423-613bbb3af80c 129.57.178.27:10001 /daosfs04.jlab.org Joined        
7    26e5667e-92a7-4534-ad4d-02f6555641cf 129.57.178.29:10001 /daosfs06.jlab.org Joined        
8    0f725d69-ca99-4e51-9054-22c9b8def81a 129.57.178.26:10001 /daosfs03.jlab.org Joined        
9    800afc76-7958-49ce-8227-dd88fbfe3977 129.57.178.27:10001 /daosfs04.jlab.org Joined        
10   2d04a1b9-379d-4c5d-be24-e1771ffc66d4 129.57.178.28:10001 /daosfs05.jlab.org Joined        
11   cd5726ee-2f7c-48c6-9c15-723e2e15bf19 129.57.178.28:10001 /daosfs05.jlab.org Joined        
12   6936dc46-9f96-4b15-8a0c-a3956c6f19dd 129.57.178.30:10001 /daosfs07.jlab.org Joined        
13   87d79171-7b38-464e-84fa-f65718aacdc9 129.57.178.30:10001 /daosfs07.jlab.org Joined

[xmei@daos-adm ~]$ dmg storage scan
Hosts         SCM Total       NVMe Total             
-----         ---------       ----------             
daosfs01      0 B (0 modules) 32 TB (10 controllers)
daosfs03      0 B (0 modules) 32 TB (10 controllers)
daosfs04      0 B (0 modules) 32 TB (10 controllers)
daosfs06      0 B (0 modules) 32 TB (10 controllers)
daosfs07      0 B (0 modules) 32 TB (10 controllers)
daosfs[02,05] 0 B (0 modules) 32 TB (10 controllers)
```

```bash
# On the DAOS client side
[xmei@daosfs08 ~]$ daos pool autotest testpool  # pool test tool `autotest`
Step Operation                 Status Time(sec) Comment
...
 99  Tearing down DAOS          PASS    0.000  
All steps passed.

[xmei@daosfs08 ~]$ daos system query
connected to DAOS system:
	name: daos_server
	fabric provider: ofi+verbs;ofi_rxm
	access point ranks:
    ...
		rank[13]: ofi+verbs;ofi_rxm://172.19.27.56:32416
		rank[0]: ofi+verbs;ofi_rxm://172.19.27.19:32416
	rank URIs:
    ...
		rank[13]: ofi+verbs;ofi_rxm://172.19.27.56:32416
```

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
