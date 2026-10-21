# Linux Data Ingestion and LVM Monitoring

Bash scripts and submitted reports for a Linux administration project. A daily ingestion script downloads and compresses a dated CSV file, while two monitoring scripts check filesystem usage and attempt to grow the logical volumes used for ingestion and analysis. The reports record related storage, permissions, scheduling, and SELinux configuration work.

## What is implemented

- Download the current day's `DD-MM-YYYY.csv` from the source URL configured in `ingest.sh`.
- Require the ingestion directory to be mounted and cancel ingestion at 90% filesystem usage or above.
- Compress the downloaded CSV with gzip under `~/ingestion/data/`.
- Check logical-volume and mount paths before monitoring storage usage.
- At usage of 90% or above, calculate a 10% volume extension, check volume-group free space, and invoke LVM/ext4 utilities.

## Repository structure

| File | Purpose |
| --- | --- |
| [ingest.sh](ingest.sh) | Dated CSV download, mount/usage checks, and gzip compression. |
| [monitor_ingestion.sh](monitor_ingestion.sh) | Monitor the ingestion filesystem and attempt logical-volume growth. |
| [monitor_analyses.sh](monitor_analyses.sh) | Monitor the analyses filesystem and attempt logical-volume growth. |
| [abdelrahman_darwish_52_5930_wednesday_Project.pdf](abdelrahman_darwish_52_5930_wednesday_Project.pdf) | Submission screenshots for block devices, fstab, mounts, LVM, cron, scripts, SELinux contexts, and ingested files. |
| [submit.pdf](submit.pdf) | Screenshots of user/group setup, directories, permissions, sudo configuration, and scripts. |

## Requirements

Use a Linux environment with Bash, GNU filesystem utilities, `mountpoint`, `wget`, `gzip`, `bc`, LVM tools (`lvs`, `vgs`, `lvextend`), and ext4 tools (`e2fsck`, `resize2fs`). Volume management requires appropriate administrative privileges and available space in the volume group. No Linux distribution release is pinned in the scripts.

The scripts assume existing mounted storage; they do not provision disks, volume groups, logical volumes, or fstab entries. They also do not install cron jobs.

## Configure and run

Inspect and adapt the paths before use:

| Script | Checked-in paths |
| --- | --- |
| `ingest.sh` | `~/ingestion`, with output in `~/ingestion/data` |
| `monitor_ingestion.sh` | `/dev/vg_name/lv_ingestion` and `~/ingestion` |
| `monitor_analyses.sh` | `/dev/vg_data/lv_analyses` and `/root/analyses` |

`~` follows the account running the script. Use the intended account for ingestion, and choose explicit mount paths for administrative monitoring if needed.

Both monitor scripts currently call `e2fsck -f` after checking that the filesystem is mounted. Filesystem checking needs an appropriate unmounted maintenance procedure; revise that sequence before using the scripts to resize storage. Their commands change actual logical volumes and filesystems.

From the repository root, check Bash syntax without executing the scripts:

```bash
bash -n ingest.sh
bash -n monitor_ingestion.sh
bash -n monitor_analyses.sh
```

Once the mount configuration is in place, run ingestion:

```bash
bash ingest.sh
```

After adapting the monitor paths and filesystem-check sequence for your environment, run the monitors with administrative privileges:

```bash
sudo bash monitor_ingestion.sh
sudo bash monitor_analyses.sh
```

The ingestion source is [rh2-project-csvs](https://github.com/Badr-AL101/rh2-project-csvs), as configured in the script. A CSV for the current date must be available there. The script checks file existence after `wget`; it does not validate the HTTP response or CSV contents. Scheduling is documented in the submitted screenshots rather than supplied as an installable crontab.

## Outputs

Successful ingestion produces `~/ingestion/data/DD-MM-YYYY.csv.gz`. Monitor status and errors are printed to the terminal. The linked PDF reports preserve the submitted lab evidence; this repository does not include captured CSV downloads or a configured Linux machine image.

## Tech stack

Bash, GNU/Linux command-line tools, wget, gzip, LVM, ext4 utilities, cron, and SELinux configuration documented in the reports.

## Author

Abdelrahman Darwish ([GitHub @darwish012](https://github.com/darwish012)).
