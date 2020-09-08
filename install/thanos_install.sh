#!/bin/bash
# Purpose : Installation of Thanos(latest)
# This performs all required steps on server .
sudo useradd --no-create-home --shell /bin/false prometheus

echo "Thanos Download is in progress .."
cd /tmp
url="$(curl -s https://github.com/thanos-io/thanos/releases | grep 'thanos-.*.linux-amd64.tar.gz' | grep -v 'rc' | awk '{print $2}' | cut -d '"' -f2 |head -1)"
sleep 2
curl -sLo /tmp/thanos.tar.gz https://github.com/${url}


echo "Thanos Installation in progress .."
sleep 2
tar -xzf /tmp/thanos.tar.gz

mv thanos*linux-amd64 thanos
sudo cp /tmp/thanos/thanos /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/thanos

echo "Thanos Service create progress .. "
sudo cat << EOF > /etc/systemd/system/thanos.service
[Unit]
Description=Thanos
Wants=network-online.target
After=network-online.target
[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/thanos sidecar \
    --prometheus.url http://localhost:9090 \
	--http-address 0.0.0.0:9191 \
	--grpc-address 0.0.0.0:19090 \
    --tsdb.path /opt/prometheus/data/

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling Thanos service to start at server reboot .."

sudo systemctl daemon-reload
sudo systemctl enable thanos > /dev/null 2>&1
echo "Thanos start in progress .."
sudo systemctl start thanos
sleep 2
echo "Thanos Status .."
sudo systemctl status thanos

# Cleanup 
rm -rf /tmp/thanos /tmp/thanos.tar.gz