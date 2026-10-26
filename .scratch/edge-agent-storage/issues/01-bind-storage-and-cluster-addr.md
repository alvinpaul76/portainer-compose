# Edge agent: bind-mounted storage and cluster addr

Status: resolved

- `agent_data` volume now bind-mounts `${DEFAULT_STORAGE_FOLDER}/agent_data`.
- Added required `AGENT_CLUSTER_ADDR` env passed to the agent.
- `.env.example` documents `DEFAULT_STORAGE_FOLDER` and `AGENT_CLUSTER_ADDR`.
