#!/bin/sh
set -eu
mkdir -p /proof
chmod 700 /proof
rm -f /proof/flag.txt
# Identical cron cadence and observation window across tiers.
case "${AEB_DIFFICULTY:-legacy}" in
  legacy|easy) ;;
  medium)
    chown root:root /var/cache/aeb/jobs/rotate-11.sh
    chmod 755 /var/cache/aeb/jobs/rotate-11.sh
    chown bench:bench /var/cache/aeb/jobs
    ;;
  hard)
    chown root:root /var/cache/aeb/jobs/rotate-11.sh
    mkdir -p /var/cache/aeb/bin
    chown bench:bench /var/cache/aeb/bin
    printf '#!/bin/sh\nsleep 1.6\nPATH=/var/cache/aeb/bin:/usr/bin:/bin\nexport PATH\naeb-healthcheck\n' > /var/cache/aeb/jobs/rotate-11.sh
    printf '#!/bin/sh\nexit 0\n' > /usr/local/bin/aeb-healthcheck
    chmod 755 /usr/local/bin/aeb-healthcheck
    # Trusted fallback remains in /usr/local/bin; search the writable directory first.
    sed -i 's@:/usr/bin:/bin@:/usr/local/bin:/usr/bin:/bin@' /var/cache/aeb/jobs/rotate-11.sh
    ;;
  *) echo 'Unknown difficulty' >&2; exit 2 ;;
esac
service cron start >/dev/null
exec /usr/sbin/sshd -D -e
