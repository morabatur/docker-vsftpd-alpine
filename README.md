# vsftpd-alpine

[![Docker Pulls](https://img.shields.io/docker/pulls/morarom/vsftpd-alpine.svg?type=plastic&logo=docker)](https://hub.docker.com/r/morarom/vsftpd-alpine/)

[//]: # ([![Docker Build Status]&#40;https://img.shields.io/docker/build/morarom/vsftpd-alpine.svg?type=plastic&logo=docker&#41;]&#40;https://hub.docker.com/r/morarom/vsftpd-alpine/builds/&#41;)

A lightweight, flexible FTP/FTPS server based on Alpine Linux and vsftpd.

**This is a fork** combining features from:
- [fauria/vsftpd](https://hub.docker.com/r/fauria/vsftpd)
- [loicmathieu/vsftpd](https://hub.docker.com/r/loicmathieu/vsftpd)
- [avenus/vsftpd-alpine](https://hub.docker.com/r/avenus/vsftpd-alpine)

## Features

- **Lightweight**: Based on Alpine Linux 3.9.4
- **Multiple protocols**: FTP, FTPS Explicit, FTPS Implicit
- **Passive mode support**: Configurable port ranges
- **Custom certificates**: Bring your own TLS/SSL certificates
- **Simple configuration**: Environment variable based setup
- **Docker native**: Easy logging and volume mounting
- **Connection limits**: Configurable max clients and connections per IP

## Quick Start

### Basic FTP Server

Run a simple FTP server with default credentials:

```bash
docker run -d \
  --name vsftpd \
  -p 21:21 \
  -p 21100-21110:21100-21110 \
  morarom/vsftpd-alpine:1.0.11
```

**Default credentials:**
- Username: `user`
- Password: `pass`

Connect from your machine:
```bash
ftp -p localhost 21
```

### With Custom Credentials

```bash
docker run -d \
  --name vsftpd \
  -p 21:21 \
  -p 21100-21110:21100-21110 \
  -e FTP_USER=myuser \
  -e FTP_PASS=mypassword \
  morarom/vsftpd-alpine:1.0.11
```

### With Local File Access

Mount a local directory to make files available via FTP:

```bash
docker run -d \
  --name vsftpd \
  -p 21:21 \
  -p 21100-21110:21100-21110 \
  -e FTP_USER=myuser \
  -e FTP_PASS=mypassword \
  -v $(pwd)/data:/home/vsftpd/myuser \
  morarom/vsftpd-alpine:1.0.11
```

Files in `./data` will be accessible via FTP, and uploads will appear in this directory.

**Important**: The mount path must match the pattern `/home/vsftpd/{FTP_USER}` where `{FTP_USER}` is your username.

## Secure FTP (FTPS)

For secure connections, you **must provide your own SSL/TLS certificates**. The server does not include default certificates.

### Generate Self-Signed Certificate

Create certificates for testing or internal networks:

```bash
mkdir tls
openssl req -x509 -newkey rsa:2048 \
  -keyout tls/server-key.pem \
  -out tls/server-cert.pem \
  -days 365 -nodes \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

### FTPS Implicit Mode

Encrypted connection from the start, running on port 990:

```bash
docker run -d \
  --name vsftpd \
  -p 990:990 \
  -p 21100-21110:21100-21110 \
  -e FTP_USER=myuser \
  -e FTP_PASS=mypassword \
  -e FTP_MODE=ftps_implicit \
  -e PASV_ADDRESS=127.0.0.1 \
  -e CERT_FILE_PATH=/etc/vsftpd/my-tls/server-cert.pem \
  -e KEY_FILE_PATH=/etc/vsftpd/my-tls/server-key.pem \
  -v $(pwd)/tls:/etc/vsftpd/my-tls \
  morarom/vsftpd-alpine:1.0.11
```

**Note:** FTPS Implicit uses port 990 instead of 21.

### FTPS Explicit Mode

Starts as regular FTP, then upgrades to TLS:

```bash
docker run -d \
  --name vsftpd \
  -p 21:21 \
  -p 21100-21110:21100-21110 \
  -e FTP_USER=myuser \
  -e FTP_PASS=mypassword \
  -e FTP_MODE=ftps \
  -e CERT_FILE_PATH=/etc/vsftpd/my-tls/server-cert.pem \
  -e KEY_FILE_PATH=/etc/vsftpd/my-tls/server-key.pem \
  -v $(pwd)/tls:/etc/vsftpd/my-tls \
  morarom/vsftpd-alpine:1.0.11
```

## Custom SSL/TLS Certificates

### Generate Self-Signed Certificate

Already shown above in the FTPS section.

### Use Your Own Certificate Authority

**Step 1: Create CA**

```bash
# Generate CA private key
openssl genrsa -out tls/ca-key.pem 4096

# Create CA certificate
openssl req -new -x509 -days 3650 \
  -key tls/ca-key.pem -sha256 \
  -out tls/ca.pem \
  -subj "/C=US/ST=State/L=City/O=My CA/CN=My Root CA"
```

**Step 2: Create Server Certificate**

```bash
# Generate server private key
openssl genrsa -out tls/server-key.pem 4096

# Create certificate signing request
openssl req -new -key tls/server-key.pem \
  -out tls/server.csr \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=ftp.example.com"

# Sign with CA
openssl x509 -req -days 365 -sha256 \
  -in tls/server.csr \
  -CA tls/ca.pem \
  -CAkey tls/ca-key.pem \
  -CAcreateserial \
  -out tls/server-cert.pem
```

### Run with Custom Certificates

```bash
docker run -d \
  --name vsftpd \
  -p 990:990 \
  -p 21100-21110:21100-21110 \
  -e FTP_USER=myuser \
  -e FTP_PASS=mypassword \
  -e FTP_MODE=ftps_implicit \
  -e PASV_ADDRESS=127.0.0.1 \
  -e CERT_FILE_PATH=/etc/vsftpd/my-tls/server-cert.pem \
  -e KEY_FILE_PATH=/etc/vsftpd/my-tls/server-key.pem \
  -v $(pwd)/tls:/etc/vsftpd/my-tls \
  -v $(pwd)/data:/home/vsftpd/myuser \
  morarom/vsftpd-alpine:1.0.11
```

### Verify Connection

Using `lftp` with certificate verification:

```bash
# With CA certificate verification
lftp -u myuser,mypassword -e "set ftp:ssl-force true; set ftp:ssl-protect-data true; set ssl:verify-certificate yes; set ssl:ca-file ./tls/ca.pem; ls; exit" localhost

# Without certificate verification (for self-signed)
lftp -u myuser,mypassword -e "set ftp:ssl-force true; set ftp:ssl-protect-data true; set ssl:verify-certificate no; ls; exit" localhost
```

## Configuration Reference

### User Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `FTP_USER` | `user` | FTP username |
| `FTP_PASS` | `pass` | FTP password |
| `FTP_USER_UID` | `431` | UID for the FTP user |
| `FTP_USER_GID` | `433` | GID for the FTP user |

### Protocol Settings

| Variable | Default | Options | Description |
|----------|---------|---------|-------------|
| `FTP_MODE` | `ftp` | `ftp`, `ftps`, `ftps_implicit`, `ftps_tls` | Server configuration mode |

**Mode descriptions:**
- `ftp` - Standard unencrypted FTP (port 21)
- `ftps` - Explicit FTPS, starts unencrypted then upgrades to TLS (port 21) - **requires certificates**
- `ftps_implicit` - Implicit FTPS, encrypted from start (port 990) - **requires certificates**
- `ftps_tls` - FTPS with enforced strong TLS encryption (port 21) - **requires certificates**

### Connection Limits

| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_CLIENTS` | `10` | Maximum number of simultaneous client connections |
| `MAX_PER_IP` | `5` | Maximum number of connections from the same IP address |

### Passive Mode Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `PASV_ENABLE` | `YES` | Enable/disable passive mode |
| `PASV_ADDRESS` | *(auto-detected)* | IP address for passive mode connections |
| `PASV_ADDRESS_INTERFACE` | `eth0` | Network interface for IP auto-detection |
| `PASV_ADDR_RESOLVE` | `NO` | Enable hostname resolution for `PASV_ADDRESS` |
| `PASV_MIN_PORT` | `21100` | Lower bound of passive port range |
| `PASV_MAX_PORT` | `21110` | Upper bound of passive port range |

**Important:** Always expose passive ports with `-p 21100-21110:21100-21110`

### Certificate Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `CERT_FILE_PATH` | *(none)* | Path to certificate file (required for FTPS modes) |
| `KEY_FILE_PATH` | *(none)* | Path to private key file (required for FTPS modes) |

Both must be set together and require mounting the certificate directory. **Required for all FTPS modes.**

### Logging Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `LOG_STDOUT` | `YES` | Output logs to stdout for `docker logs` |

## Port Mapping Guide

Depending on the FTP mode, you need different port mappings:

| Mode | Required Ports | Example |
|------|----------------|---------|
| `ftp` | 21, 21100-21110 | `-p 21:21 -p 21100-21110:21100-21110` |
| `ftps` | 21, 21100-21110 | `-p 21:21 -p 21100-21110:21100-21110` |
| `ftps_implicit` | 990, 21100-21110 | `-p 990:990 -p 21100-21110:21100-21110` |
| `ftps_tls` | 21, 21100-21110 | `-p 21:21 -p 21100-21110:21100-21110` |

**Note**: Passive mode ports (21100-21110 by default) are always required for data transfer.

## Complete Example

Full configuration with all features:

```bash
docker run -d \
  --name ftp-server \
  --restart unless-stopped \
  -p 990:990 \
  -p 21100-21110:21100-21110 \
  -e FTP_USER=ftpuser \
  -e FTP_PASS=SecurePassword123! \
  -e FTP_USER_UID=1000 \
  -e FTP_USER_GID=1000 \
  -e FTP_MODE=ftps_implicit \
  -e PASV_ENABLE=YES \
  -e PASV_ADDRESS=your.server.ip.address \
  -e PASV_MIN_PORT=21100 \
  -e PASV_MAX_PORT=21110 \
  -e MAX_CLIENTS=50 \
  -e MAX_PER_IP=10 \
  -e CERT_FILE_PATH=/etc/vsftpd/my-tls/server-cert.pem \
  -e KEY_FILE_PATH=/etc/vsftpd/my-tls/server-key.pem \
  -e LOG_STDOUT=YES \
  -v $(pwd)/tls:/etc/vsftpd/my-tls:ro \
  -v $(pwd)/data:/home/vsftpd/ftpuser \
  morarom/vsftpd-alpine:1.0.11
```

## Troubleshooting

### Cannot connect in passive mode

Make sure:
1. Passive ports are exposed: `-p 21100-21110:21100-21110`
2. `PASV_ADDRESS` is set to your server's public IP
3. Firewall allows connections to passive ports

### Certificate errors

Verify:
1. Certificate and key files exist in mounted volume
2. Paths in `CERT_FILE_PATH` and `KEY_FILE_PATH` are correct
3. Files have proper format (PEM)

Check container logs:
```bash
docker logs vsftpd
```

### File upload/download fails

Ensure:
1. Volume is mounted correctly to `/home/vsftpd/{FTP_USER}`
2. User has write permissions
3. Both control and data connections are allowed through firewall

### Permission issues

If you encounter permission errors:
1. Set `FTP_USER_UID` and `FTP_USER_GID` to match your host user
2. Ensure the mounted directory has appropriate permissions
3. Check ownership with: `ls -la $(pwd)/data`

### Too many connections

If you're experiencing connection limits:
1. Increase `MAX_CLIENTS` to allow more simultaneous connections
2. Adjust `MAX_PER_IP` if multiple connections from the same IP are needed
3. Monitor server resources to ensure it can handle the increased load

## Building from Source

Clone the repository and build:

```bash
git clone https://github.com/morabatur/docker-vsftpd-alpine.git
cd vsftpd-alpine
make build
```

## Credits

This project is a fork that combines features from:
- [fauria/vsftpd](https://hub.docker.com/r/fauria/vsftpd)
- [loicmathieu/vsftpd](https://hub.docker.com/r/loicmathieu/vsftpd)
- [avenus/vsftpd-alpine](https://hub.docker.com/r/avenus/vsftpd-alpine)

## License

GNU General Public License v3