# A Dockerized NGINX Reverse Proxy

[![](https://images.microbadger.com/badges/image/newtonsystems/docker-nginx-reverse-proxy.svg)](https://microbadger.com/images/newtonsystems/docker-nginx-reverse-proxy "Get your own image badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/newtonsystems/docker-nginx-reverse-proxy.svg)](https://microbadger.com/images/newtonsystems/docker-nginx-reverse-proxy "Get your own version badge on microbadger.com")

Available from docker hub as [newtonsystems/tools/docker-grpc-tools](https://hub.docker.com/r/newtonsystems/docker-nginx-reverse-proxy/)

#### Supported tags and respective `Dockerfile` links

-    [`v0.1.0`, `latest` (/Dockerfile*)](https://github.com/newtonsystems/docker-nginx-reverse-proxy/blob/master/Dockerfile)


# What is docker-nginx-reverse-proxy?

- Reverse Proxy using NGINX
- HTTPs support via (letsencrypt/certbot)
- Automatic cert renewal via (letsencrypt/certbot)
- Uses Supervisor to control multiple processes
- Mattermost webhook error message


## Why do you need this?
- Often Docker services will run on different post on a host but we want it
 running on 80 (HTTP) so it will be accessible from a web browser.
- This docker image acts as a reverse proxy to a port you specify
- While HTTP is nice it is not secure so we add HTTPS support via Lets Encrypt


## Limitations
- As we use Lets Encrypt to create our certificates this docker image MUST be
 run on the host with the supplied DNS (env `DOMAIN_NAME`). It will therefore not
 work locally unless you have a DNS name and you own it.
- Supports only ONE server behind the reverse proxy


## Prerequisites 
- You must run this from your domain host which you own! (YOU CANNOT USE IP ADDRESS)
- It is assumed you are running your server (to be reverse proxy) in a Docker container


## How to Build the Docker Image
- Run docker build (Note: the domain must be valid and you must own it)

```bash
	docker build -t docker-nginx-reverse-proxy:latest .
```


## How to Run the Docker Image
- you MUST link the server connected to the reverse proxy via the docker run option
 `--link`. This is performed by set the name option in the docker  `--name`

e.g reverse proxy for rancher
```bash
	sudo docker run -d --restart=unless-stopped --name=rancher-server -v /vol/mysql:/var/lib/mysql -p 8080:8080 rancher/server
	docker run --restart=unless-stopped  --link rancher-server:webserver -p 80:80 -p 443:443 --env ENFORCE_HTTPS=TRUE --env DOMAIN_NAME=rancher.tetherboxapp.com --env MATTERMOST_WEBHOOK_URL=http://mattermost.example.com:8065/hooks/aj8agnqi6fbhjm165u8297th3a -d  docker-nginx-reverse-proxy:latest
```

- Then check the docker logs to ensure the initialise set up as been completed successfully. You then check the HTTPs via SSLLabs.

### What about logs
- Most of the info should be out'd to standard output
- There are two useful folders with logs within the docker container:
	- supervisor logs
	- app logs
- You can mount the volumes for access

Example
```bash
	docker run --restart=unless-stopped 
		--link rancher-server:webserver 
		-p 80:80 -p 443:443 
		-v /vol/nginx-rev-proxy/letsencrypt:/etc/letsencrypt 
		-v /vol/nginx-rev-proxy/pki:/etc/pki/nginx 
		-v /vol/nginx-rev-proxy/logs/app:/var/log/app 
		--env ENFORCE_HTTPS=TRUE 
		--env DOMAIN_NAME=rancher.newtonsystems.co.uk 
		--env MATTERMOST_WEBHOOK_URL=https://mattermost.newtonsystems.co.uk/hooks/9eypzzfrrjy9dyptf6s6otchie 
		-d 
		docker-nginx-reverse-proxy:0.1.0
```

## How to do a release
- Make sure you are using docker-utils 
i.e.

```bash
export PATH="~/<LOCATION>/docker-utils/bin:$PATH"
```

```
build-tag-push-dockerfile.py  --image "newtonsystems/docker-nginx-reverse-proxy" --version 0.1.0 --dockerhub_release --github_release
```

## Future

- The Docker Image is rather large should do an alpine version.
- Support for multi backend servers. 

## User Feedback

Any feedback or comments  would be greatly appreciated: <james.tarball@newtonsystems.co.uk>


### Issues

If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/newtonsystems/docker-nginx-reverse-proxy/issues).

You can also reach me by email. I would be happy to help  <james.tarball@newtonsystems.co.uk>








