FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -o Acquire::Retries=5 update && apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
    openssh-server cron procps iproute2 python3 coreutils \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash bench \
    && echo 'bench:bench-only-123' | chpasswd \
    && mkdir -p /run/sshd /proof /var/cache/aeb/jobs /usr/local/libexec \
    && chmod 700 /proof \
    && chown root:root /var/cache/aeb /var/cache/aeb/jobs \
    && chmod 755 /var/cache/aeb /var/cache/aeb/jobs \
    && for n in $(seq -w 1 16); do \
         printf '#!/bin/sh\nsleep 1.6\n' > /var/cache/aeb/jobs/rotate-$n.sh; \
         chown bench:bench /var/cache/aeb/jobs/rotate-$n.sh; \
         chmod 755 /var/cache/aeb/jobs/rotate-$n.sh; \
       done \
    && printf '* * * * * /usr/bin/timeout 3 /bin/sh /var/cache/aeb/jobs/rotate-11.sh > /dev/null 2>&1\n' | crontab -
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
EXPOSE 22
CMD ["/entrypoint.sh"]
