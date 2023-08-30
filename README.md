# VPN

Provision personal VPN server with Terraform(AWS)

## Components

1. EC2
2. RDS
3. Elasticache (redis)

### 1. EC2

Once EC2 is created, ssh into the vpn server by:

```bash
ssh -i vpn-server-key-pair.pem ubuntu@vpn.jinsungha.com
```

And run the following commands to spin up the ovpn server and create client:

```bash
# Initialize the $OVPN_DATA container that will hold the configuration files
# and certificates. The container will prompt for a passphrase to protect
# the private key used by the newly generated certificate authority.
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://vpn.jinsungha.com
docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki

# Start OpenVPN server process
docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

# Generate a client certificate without a passphrase
docker run -v $OVPN_DATA:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full jha nopass

# Retrieve the client configuration with embedded certificates
docker run -v $OVPN_DATA:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient jha > jha.ovpn
```

Then register and run the `.ovpn` file on a local machine to connect to the VPN.

### 2. RDS

Once created, look for rds_endpoint and try connecting to it.

### 3. Elasticache (redis)

Once created, look for redis_address and redis_port then try connecting to it.

## Deployment

Prepare `terraform.tfvars` then:

```bash
terraform init && terraform validate && terraform plan && terraform apply
```
