# Restic Backup with Docker Compose

This setup uses `restic` within a Docker container to provide versioned, encrypted, and deduplicated backups of your important directories to a NAS or other storage location.

> This was the first setup of my restic backup, but I will try to simplify away from compose so that we can use temporal for this in a more natural way

## Prerequisites

- Docker
- Docker Compose

## 1. Configuration

This setup connects to your NAS via SFTP (SSH). You will need to configure the connection details and generate a dedicated SSH key for security.

### a. Prepare Your SSH Key

1. **Identify or Generate an SSH Key:** You can use an existing SSH key or generate a new one specifically for backups. Make sure the public key is added to the `~/.ssh/authorized_keys` file for the appropriate user on your **NAS**.

2. **Copy the Private Key:** Copy the private key you want to use into the local `.ssh` directory and name it `id_rsa`. This key will be used by the container to connect to your NAS.

    ```bash
    # Example using an existing key
    cp /path/to/your/private_key /home/nic/dotfiles/nas-backup/docker/.ssh/id_rsa
    ```

3. **Set Permissions:** SSH requires that the private key file has strict permissions. Set them now.

    ```bash
    chmod 600 /home/nic/dotfiles/nas-backup/docker/.ssh/id_rsa
    ```

### b. Create and Configure Environment Files

1. **Create a `.env` file:** Copy the `.env.example` to `.env`:

    ```bash
    cp .env.example .env
    ```

2. **Edit `.env`:** Open the `.env` file and set the following variables:

    - `BACKUP_SOURCE`: The absolute path to the directory you want to back up (e.g., `/home/nic`).
    - `SFTP_USER`: The username for SSH access to your NAS.
    - `SFTP_HOST`: The IP address or hostname of your NAS.
    - `SFTP_PATH`: The absolute path on the NAS where the backup repository will be stored (e.g., `/volume1/backups/restic`).
    - `RESTIC_PASSWORD_FILE`: The path to the file containing your restic repository password (see next step).

3. **Create the Restic Password File:**

    ```bash
    # Use a strong, unique password
    echo "your-super-secret-password" > /home/nic/dotfiles/nas-backup/docker/.restic-password
    # Set permissions to be safe
    chmod 600 /home/nic/dotfiles/nas-backup/docker/.restic-password
    ```

    Ensure the `RESTIC_PASSWORD_FILE` variable in your `.env` file points to this file.

## 2. Initial Setup

With your configuration in place, you need to initialize the `restic` repository on your NAS. This only needs to be done once. The command constructs the repository path from your `.env` variables.

```bash
docker-compose run --rm --entrypoint restic backup init -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}
```

## 2. Automation with systemd

This setup includes `systemd` unit files to automate your backups. This is the recommended way to run scheduled jobs on a modern Linux system.

### a. Installation

1.  **Copy the Unit Files**: Copy the provided `.service` and `.timer` files to your systemd user directory.

    ```bash
    mkdir -p ~/.config/systemd/user
    cp /home/nic/dotfiles/nas-backup/docker/systemd/nas-backup.* ~/.config/systemd/user/
    ```

2.  **Reload the systemd Daemon**: Tell systemd to pick up the new files.

    ```bash
    systemctl --user daemon-reload
    ```

3.  **Enable and Start the Timer**: This command enables the timer to start automatically on boot and starts it right away.

    ```bash
    systemctl --user enable --now nas-backup.timer
    ```

### b. Managing the Backup Job

-   **Check Timer Status**: To see when the next backup is scheduled to run, use:
    ```bash
    systemctl --user list-timers
    ```

-   **View Logs**: To see the logs from the last backup run, use the `journalctl` command:
    ```bash
    journalctl --user -u nas-backup.service
    ```

-   **Run a Manual Backup**: If you want to trigger a backup manually right now, you can start the service directly:
    ```bash
    systemctl --user start nas-backup.service
    ```

## 3. Automated Backup & Prune

This setup is now automated. Running the `backup` service will perform two actions in sequence:

1. **Backup**: It backs up the `BACKUP_SOURCE` directory.
2. **Prune**: It applies a retention policy to historical snapshots (keeps the last 7 daily, 4 weekly, and 6 monthly) and deletes any data that is no longer needed.

To run the automated process, simply execute:

```bash
docker-compose run --rm backup
```

## 4. Manual Operations

If you need to perform a manual operation (like listing snapshots or restoring a file), you must override the entrypoint to run `restic` directly. You can do this with the `--entrypoint` flag:

### Listing Snapshots

To see all the snapshots in your repository:

```bash
docker-compose run --rm --entrypoint restic backup snapshots -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}
```

### Restoring Files

To restore a file or directory from a backup, you need the snapshot ID (from the `snapshots` command). To restore the latest snapshot:

```bash
# Create a directory to restore to
- mkdir -p /tmp/restore

# Restore the latest snapshot to /tmp/restore
docker-compose run --rm -v /tmp/restore:/restore_target backup restore latest --target /restore_target -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}
```

To restore a specific file from the latest snapshot:

```bash
docker-compose run --rm -v /tmp/restore:/restore_target backup restore latest --target /restore_target --path "/source/path/to/your/file" -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}
```

### Comparing Snapshots (Diff)

To see the exact changes between any two snapshots, you can use the `diff` command. You will need the IDs of the two snapshots you want to compare, which you can get from the `snapshots` command.

```bash
# Compare snapshot-ID-1 with snapshot-ID-2
docker-compose run --rm backup diff <snapshot-ID-1> <snapshot-ID-2> -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}
```

### Verifying Your Backup

It's important to be confident that your backups are working correctly. Here are a few commands to verify the integrity and content of your repository.

**1. Check Repository Integrity**

The `check` command scans the repository for internal errors and ensures all data is correctly stored and readable.

```bash
docker-compose run --rm backup check -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}
```

**2. List Files in a Snapshot**

You can list all the files in your latest backup to ensure everything you intended to back up is there.

```bash
docker-compose run --rm backup ls latest -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}
```

**3. Restore a Test File**

The ultimate test is to restore a file. Create a temporary directory and restore a single file to confirm it's readable and correct.

```bash
# Create a temporary directory on your host
mkdir -p /tmp/restore

# Restore a specific file (e.g., your README) to that directory
docker-compose run --rm -v /tmp/restore:/restore_target backup restore latest --target /restore_target --path "/source/README.md" -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}

# Check the restored file on your host
cat /tmp/restore/source/README.md
```

### Forgetting and Pruning Old Snapshots

To manage your backup history (e.g., keep the last 7 daily, 4 weekly, and 6 monthly snapshots):

```bash
docker-compose run --rm backup forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH}
```

## 4. Automation (Optional)

You can automate your backups using a `cron` job or a `systemd` timer on your host machine to run the backup command periodically.

Example `cron` job to run a backup every day at 2 AM:

```cron
0 2 * * * cd /home/nic/dotfiles/nas-backup/docker && /usr/bin/docker-compose run --rm backup backup /source -r sftp:${SFTP_USER}@${SFTP_HOST}:${SFTP_PATH} >> /var/log/restic-backup.log 2>&1
```
