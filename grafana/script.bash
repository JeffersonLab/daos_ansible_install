# Bash command to save the Grafana dashboad into a json file.

# Check $dashboard_id via UI.
# "http://localhost:3000" is Grafana's address. Make sure it matches the real case.

curl -u "${usr}:${psd}" -X GET http://localhost:3000/api/dashboards/uid/${dashboard_id} > $save_path.json
