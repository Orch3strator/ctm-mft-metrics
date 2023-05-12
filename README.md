# Manage Control-M MFT Metrics

## Export Metrics

The script **mps.export.metrics.sh** will export the MFT metrics from the EM database annd writes the entries to a local file.

### Example Usage

| Variable | Description | Example |
| -------------------------------- | -------------------------------- | -------------------------------- |
| Credentials | CTM EM Database Credentials | Username:Password |
| Environment | CTM Environment Name | test |
| Server | CTM EM Host Name and Database Port | server.domain:5432 |
| Database | CTM EM Database Name | emdb |
| Start | Date Time to start export from | 2023-03-15 11:00:00 |
| End | Date Time to end export from | 2023-03-15 12:00:00 |
| Past | Export data from last 'n' hour | 1 |

#### Example Commands

``` bash
    ./mps.export.metrics.sh --credentials Username:Password  --environment TryBMC --server server.name:port --database emdb --start '2023-03-15 11:00:00' --end '2023-03-15 12:00:00'
    ./mps.export.metrics.sh --credentials Username:Password  --environment TryBMC --server server.name:port --database emdb
    ./mps.export.metrics.sh --credentials Username:Password  --environment TryBMC --server server.name:port --database emdb --past 1
```

##  Export

The metrics are exported also in to a csv file. 

###  Example Output

``` bash
 CTM Working Dir     : /opt/bmcs/scripts/metrcis/20230511
 CTM Environment     : TryBMC
 ---------------------
 CTM Database Name   : emdb
 CTM Database Server : server.trybmc.local:5432
 CTM Database Port   : 5432
 CTM Database User   : ctm
 CTM Database Pwd    : ********
 CTM DB Connection   : true
 ---------------------
 Current Date Time   : 2023-05-11 20:35:05
 DB Export Interval  : 1 Hours
 DB Export Start     : 2023-05-11 19:35:05
 DB Export End       : 2023-05-11 20:35:05
 ---------------------
 CTM MFT Entries     : 0
 CTM Data Export CSV : /opt/bmcs/scripts/metrcis/20230511/mps.mft.entries.csv
```
