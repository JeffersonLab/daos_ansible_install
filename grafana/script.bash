# Bash command to save the Grafana dashboad into a json file.

# Check $dashboard_id via UI.
curl -u "${usr}:${psd}" -X GET http://localhost:3000/api/dashboards/uid/${dashboard_id} > $save_path.json
