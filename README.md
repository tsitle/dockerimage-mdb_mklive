# Docker Image sources for mdb-mklive

Docker Image for building the **mdb-live** Docker Image.

The **mdb-live** Docker Image provides a fully featured dockerized Mailserver including

- Modoboa Webinterface for  
	- domain and user management
	- webmailer
	- managing calenders and contacts
	- managing autoresponse emails
- SpamAssassin Anti-Spam-Filter
- Postfix SMTP Server
- Dovecot IMAP Server
- ClamAV Virus Scanner
- AutoMX for automated mail account configuration in email clients
- Radicale CalDAV and CardDAV Server
- MariaDB Database Server
- OpenDKIM for automaticly signing outgoing emails to reduce risk of emails being falsely classified as spam
- Apache Webserver for handling requests to the Modoboa Webinterface, AutoMX and Radicale within the Docker Container running **mdb-live**
- Nginx Reverse Proxy for forwarding requests from the outside world to the Apache Webserver

In order to use this Docker Image you should also get a copy of the Docker Container Repository **mdb-dc-mklive** (see below).

## Links
### GitHub
- GitHub Repository for Docker Image [mdb-mkinstall](https://github.com/tsitle/dockerimage-mdb_mkinstall)
- GitHub Repository for Docker Container [mdb-dc-mkinstall](https://github.com/tsitle/dockercontainer-mdb_dc_mkinstall)
- GitHub Repository for Docker Container [mdb-dc-mklive](https://github.com/tsitle/dockercontainer-mdb_dc_mklive)

### Docker Hub
- [mdb-mkinstall](https://hub.docker.com/r/tsle/mdb-mkinstall "Docker Hub Repository for Docker Image mdb-mkinstall")
- [mdb-install](https://hub.docker.com/r/tsle/mdb-install "Docker Hub Repository for Docker Image mdb-install")
- [mdb-mariadb](https://hub.docker.com/r/tsle/mdb-mariadb "Docker Hub Repository for Docker Image mdb-mariadb")
- [mdb-nginx](https://hub.docker.com/r/tsle/mdb-nginx "Docker Hub Repository for Docker Image mdb-nginx")
- [mdb-mklive](https://hub.docker.com/r/tsle/mdb-mklive "Docker Hub Repository for Docker Image mdb-mklive")
