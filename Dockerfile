FROM alpine:3.9.4

MAINTAINER mora <morabatur@gmail.com>
LABEL Description="vsftpd Docker image based on Alpine. Supports passive and implicit mode, virtual users, custom certs." \
	License="GNU General Public License v3" \
	Usage="docker run -d  -p 990:990   -p 21100-21110:21100-21110   -e FTP_USER=ftpuser   -e FTP_PASS=ftppass123   -e FTP_MODE=ftps_implicit   -e PASV_ADDRESS=127.0.0.1 -e CERT_FILE_PATH=/etc/vsftpd/my-tls/server-cert.pem -e KEY_FILE_PATH=/etc/vsftpd/my-tls/server-key.pem -v ./tls/:/etc/vsftpd/my-tls/  -v $(pwd)/data:/home/ftpuser morarom/vsftpd-alpine:1.0.11" \
	Version="${VERSION}"

# RUN apk update and install dependencies
RUN apk update \
		&& apk upgrade \
		&& apk --update --no-cache add \
				bash \
				openssl \
				vsftpd 


RUN mkdir -p /home/vsftpd/
RUN mkdir -p /var/log/vsftpd
RUN chown -R ftp:ftp /home/vsftpd/
RUN mkdir -p /etc/vsftpd/custom-tls/

COPY vsftpd-base.conf /etc/vsftpd/vsftpd-base.conf
COPY vsftpd-ftp.conf /etc/vsftpd/vsftpd-ftp.conf
COPY vsftpd-ftps.conf /etc/vsftpd/vsftpd-ftps.conf
COPY vsftpd-ftps_implicit.conf /etc/vsftpd/vsftpd-ftps_implicit.conf
COPY vsftpd-ftps_tls.conf /etc/vsftpd/vsftpd-ftps_tls.conf
COPY run-vsftpd.sh /usr/sbin/

RUN chmod +x /usr/sbin/run-vsftpd.sh

EXPOSE 20-22 990 21100-21110

CMD /usr/sbin/run-vsftpd.sh
