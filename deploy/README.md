# VAPID keys + data key generation

This folder holds deployment files for a real server. The two secrets it needs
are generated here and must be kept: both are per-deployment and unrecoverable.

## Generate everything

```bash
./deploy/gen-secrets.sh
```

It prints a ready-to-fill `/etc/ratatosk/ratatosk.env`. Three rules:

- **`RATATOSK_DATA_KEY` must be backed up off the server together with a database
  backup.** It is the key to every record in `ratatosk.db`; without it the data is
  unreadable, and there is no recovery path. If you lose the server *and* this key,
  all history and photos are gone.
- **The VAPID pair must stay the same for the life of the deployment.** Changing
  it silently invalidates every device's existing notification subscription; users
  would have to re-enable notifications. It is not a secret worth rotating
  casually, and it is fine to treat it as public.
- **Never regenerate these on a server that already has data.** The script
  checks for a database (beside the env file, or in the `ratatosk` Docker
  volume) and refuses to run when one exists — generating a new data key would
  make it unreadable, and a new VAPID pair would silently invalidate every
  device's notification subscription. An env file with *no* data behind it is
  not a refusal: that is just a first deploy being retried.

## Placeholders the script fills in

```
RATATOSK_DATA_KEY=<64 hex chars>
RATATOSK_VAPID_PUBLIC_KEY=<base64url>
RATATOSK_VAPID_PRIVATE_KEY=<base64url>
RATATOSK_VAPID_CONTACT=mailto:you@example.org
```

Without the VAPID keys the server runs normally with notifications disabled; the
app says so instead of showing a button that cannot work.
