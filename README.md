# Manage Control-M MFT Metrics

## Export Metrics

The script **mps.export.metrics.sh** will export the MFT metrics from the EM database annd writes the entries to a local file.

### Example Usage

| Variable | Description | Example |
| -------------------------------- | -------------------------------- | -------------------------------- |
| Credentials | CTM EM Database Credentials | Username:Password |
| Environment | CTM Environment Name | test |
| Server | CTM EM Host Name  | server.domain |
| Database | CTM EM Database Name | emdb |
| Start | Date Time to start export from | 2023-03-15 11:00:00 |
| End | Date Time to end export from | 2023-03-15 12:00:00 |
| Past | Export data from last 'n' hour | 1 |


``` bash
    ./mps.export.metrics.sh --credentials Username:Password  --environment TryBMC --server ctmcore.trybmc.local:5432 --database emdb --start '2023-03-15 11:00:00' --end '2023-03-15 12:00:00'
    ./mps.export.metrics.sh --credentials Username:Password  --environment TryBMC --server ctmcore.trybmc.local:5432 --database emdb
    ./mps.export.metrics.sh --credentials Username:Password  --environment TryBMC --server ctmcore.trybmc.local:5432 --database emdb --past 1
```

