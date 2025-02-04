#!/bin/bash
set -xe  # ✅ Enable debugging for logs

# ✅ Redirect logs for troubleshooting
exec > /var/log/user-data.log 2>&1

# ✅ Update & Install Dependencies
sudo yum update -y
sudo yum install -y docker aws-cli

# ✅ Start Docker Service
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# ✅ Attach and Format the 50GB Volume for Splunk Storage
if [ ! -e /dev/xvdf ]; then
  echo "❌ Volume not detected!"
else
  sudo mkfs -t xfs /dev/xvdf  # ✅ Format volume with XFS
  sudo mkdir -p /opt/splunk
  sudo mount /dev/xvdf /opt/splunk
  sudo chown -R ec2-user:ec2-user /opt/splunk
  echo "/dev/xvdf /opt/splunk xfs defaults,nofail 0 2" | sudo tee -a /etc/fstab  # ✅ Auto-mount on reboot
fi

# ✅ Use Pre-Fetched Splunk Password
SPLUNK_PASSWORD="${SPLUNK_PASSWORD}"

# ✅ Run Splunk in Docker with Mounted Storage
sudo docker run -d -p 8000:8000 -p 8088:8088 -p 8089:8089 \
    -e "SPLUNK_START_ARGS=--accept-license" \
    -e "SPLUNK_PASSWORD=$SPLUNK_PASSWORD" \
    -v /opt/splunk:/opt/splunk  # ✅ Store Splunk Data on New Volume
    --name splunk splunk/splunk:latest
