# Easy deployment of EspoCRM

This repository aims to contain everything for making deployment of EspoCRM easier and include simple means of backup and restore.

When thing are up and running you will have an EspoCRM instance exposing port 80 and 443 serving over HTTPS. You will get daily backups, or according to you customization, stored to your configured places.

For custom backup settings, adjust `backup-configuration.env` and possibly the `backup` service in `docker-compose.yml` according to https://offen.github.io/docker-volume-backup/

# Bring up new system

Update relevant environment variables in `.env`. (Yes, it is just called `.env`, not `config.env` or anything like that.)

If have your own certificates you want to use, follow instructions in [Custom certificates](#custom-certificates).

Then run:

```bash
docker compose up -d
```

Docker compose now creates the necessary containers and volumes. They will by default autostart, even if you restart your computer as soon as the docker engine starts.

To shut the instance down in a normal way, and destroy the containers (not the data!), run:

```bash
docker compose down
```

To also destroy the data volumes, run:

```bash
# WARNING! This destroys your data!
docker compose down -v
```

## Custom certificates

Add your custom certificates to ./certs/ and update the corresponding lines in the file Caddyfile to correspond to the names of the certifikate files.

# Restore from backup

The backup can only be restored to a fresh system. That is, you have to shut down and remove the volumes of any system running that uses the same volume names as your intended new volumes.

First, point `RESTORE_POINT` to your backup in the `.env` file.

Then run

```bash
docker compose -f docker-compose-restore.yml up -d
```

A folder `restoration-status` is created, and after a while either `success.txt` or `failure.txt` appears in that folder. If `success.txt` appears, proceed as follows:

```bash
docker compose -f docker-compose-restore.yml down
docker compose up -d
```

The system is now restored and up and running.
