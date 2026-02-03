#!/bin/bash
set -e
 
apt-get update -y

# Instalar SSM Agent en Ubuntu
snap install amazon-ssm-agent --classic
systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service

apt-get install apache2 -y
apt-get install php php-common libapache2-mod-php php-bz2 php-gd php-mysql \
php-curl php-mbstring php-imagick php-zip php-common php-curl php-xml \
php-json php-bcmath php-xml php-intl php-gmp zip unzip wget -y
a2enmod env rewrite dir mime headers setenvif ssl
systemctl restart apache2
systemctl enable apache2
rm /var/www/html/index.html


#Instalar NFS, conectar a un volumen EFS y modificar el fstab para que se monte al iniciar
#El volumen EFS debe estar creado previamente
#El Volumen EFS debe tener un grupo de seguridad que permita el trafico NFS (puerto 2049) desde el grupo de seguridad de la instancia EC2
#El Volumen EFS debe estar en la misma region que la instancia EC2
sudo apt-get install -y nfs-common binutils build-essential
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0d52192e242379166.efs.us-east-1.amazonaws.com:/ /var/www/html
systemctl daemon-reload
echo fs-0d52192e242379166.efs.us-east-1.amazonaws.com:/ /var/www/html nfs4 nfsvers=4.1,_netdev 0 0 >> /etc/fstab


#Descarga y descomprime la ultima version del wordpress
#Se necesita un RDS para la bbdd
cd /home/ubuntu
wget https://wordpress.org/latest.zip -O latest.zip
unzip latest.zip
cd wordpress
cp -R . /var/www/html
cd ..
rm latest.zip
rm -R wordpress
chown -R www-data:www-data /var/www/html/

# Configurar CloudWatch Logs
LOG_GROUP="/ec2/ubuntu24"
REGION="us-east-1"
# Instalar CloudWatch Agent  INICIO #############################
# https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/download-CloudWatch-Agent-on-EC2-Instance-commandline-first.html
wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb           
dpkg -i amazon-cloudwatch-agent.deb
 
# Crear configuración del agente
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "region": "$REGION"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/apache2/access.log",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}-apache-access",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/apache2/error.log",
            "log_group_name": "$LOG_GROUP",
            "log_stream_name": "{instance_id}-apache-error",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
EOF
 
# Iniciar el agente
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s
 
# Habilitar el servicio
systemctl enable amazon-cloudwatch-agent
systemctl restart amazon-cloudwatch-agent

# IMPORTANTE
# Para que funcione el agente de CloudWatch debes tener conectividad a los endpoints de CloudWatch Logs
# Si estás en la red pública con IGW no hay problema
# Si estás en una VPC privada con NAT-GATEWAY tampoco hay problema
# Si estás en una VPC privada sin salida a Internet debes usar un ENDPOINT VPC
# Si sólo usas IPv6 sin NAT-GATEWAY debes abrir el puerto https ::0 en el grupo de seguridad entrante (y saliente si tienes reglas restrictivas)
# Parece que da problemas con la resolución DNS si no tienes IPv4
# Debes usar un ENDPOINT IPv6 para CloudWatch en tu región (AWS Services y buscar logs) 
# Instalar CloudWatch Agent  FIN #############################


#Mostrar informacion del ID de la instancia en un archivo PHP
cat > /var/www/html/instance.php <<'PHPEOF'
<?php
$token = trim(shell_exec('curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"'));
echo trim(shell_exec("curl -s -H 'X-aws-ec2-metadata-token: $token' http://169.254.169.254/latest/meta-data/instance-id"));
?>
PHPEOF

echo "Archivo instance.php creado correctamente"