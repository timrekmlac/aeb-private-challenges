FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssh-server iproute2 iputils-ping curl procps && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash foothold && echo 'foothold:lab-pivot-2026' | chpasswd \
 && mkdir -p /run/sshd && printf 'PasswordAuthentication yes\nAllowTcpForwarding yes\nGatewayPorts no\nPermitRootLogin no\n' > /etc/ssh/sshd_config.d/bench.conf
CMD ["/usr/sbin/sshd", "-D", "-e"]
