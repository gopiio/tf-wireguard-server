[Interface]
# Name = server ${name}
Address = ${address}
ListenPort = 51820
MTU = ${mtu}

#TODO: Think about to have this as an option
### Rules for bounce server
# PostUp = iptables -A FORWARD -i ${interface_name} -j ACCEPT; iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
# PostDown = iptables -D FORWARD -i ${interface_name} -j ACCEPT; iptables -t nat -D POSTROUTING -o ens5 -j MASQUERADE
###

PreUp = aws s3 cp s3://${s3_bucket_name}/${interface_name}.conf  /etc/wireguard/ --region ${region}
PostUp = iptables -t nat -A POSTROUTING -s ${cidr} -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -s ${cidr} -o eth0 -j MASQUERADE

PrivateKey = ${private_key}
DNS = ${dns_server}

%{ for peer, config in peers ~}
[Peer]
# Name = ${peer}
PublicKey = ${config.public_key}
AllowedIPs = ${config.allowed_ips}
PersistentKeepalive = 25

%{ endfor ~}
