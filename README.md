A React application containerized with Docker, built and deployed automatically by Jenkins, hosted on AWS EC2 and monitored with Uptime Kuma.

## Submission details

| Item | Value |
|------|-------|
| GitHub repo | https://github.com/abirami-0901/devops-build |
| Deployed site | http://100.48.10.146 |
| Docker Hub (dev, public) | https://hub.docker.com/r/abirami0901/dev (`abirami0901/dev`) |
| Docker Hub (prod, private) | https://hub.docker.com/r/abirami0901/prod (`abirami0901/prod`) |

## Architecture

```
GitHub (dev / master)
        |
        v   (Jenkins scans the repo every minute)
Jenkins server (EC2, port 8080)
        |-- dev branch    -> build image -> push to abirami0901/dev
        |-- master branch -> build image -> push to abirami0901/prod -> deploy over SSH
        v
App server (EC2 t2.micro, port 80)  <--  Uptime Kuma (port 3001) sends an email alert when the app is down
```

## Repository contents

| File | Purpose |
|------|---------|
| `build/` | Pre-built React application |
| `Dockerfile` | Serves the React build with nginx on port 80 |
| `docker-compose.yml` | Runs the image (`IMAGE` variable) on port 80 with a health check |
| `build.sh` | Builds the Docker image and tags it (`dev` or `prod`) |
| `deploy.sh` | Pulls the image on the server and starts it with docker compose |
| `Jenkinsfile` | Pipeline: build, push to Docker Hub, deploy (master only) |
| `.dockerignore` / `.gitignore` | Files excluded from the Docker build and from Git |
| `screenshots/` | Evidence for Jenkins, AWS, Docker Hub, the deployed site and monitoring |

## Run locally

```bash
export DOCKERHUB_USER=abirami0901
./build.sh dev
IMAGE=$DOCKERHUB_USER/dev:latest docker compose up -d
# open http://localhost
docker compose down
```

## Scripts

```bash
./build.sh dev     # builds abirami0901/dev:<commit> and abirami0901/dev:latest
./build.sh prod    # builds abirami0901/prod:<commit> and abirami0901/prod:latest
./deploy.sh prod   # run on the server: pulls abirami0901/prod:latest and starts it
```

## Docker Hub

- `dev`: public repo, receives images from builds of the `dev` branch.
- `prod`: private repo, receives images from builds of the `master` branch.
- Every image gets two tags: the short commit ID and `latest`.

## CI/CD with Jenkins

- Job type: Multibranch Pipeline, source `https://github.com/abirami-0901/devops-build.git`.
- Trigger: the repo is scanned every minute, and a new commit starts a build.
- Credentials stored in Jenkins: `dockerhub-creds` (Docker Hub username and access token) and `ec2-ssh-key` (SSH key for the app server).

| Branch | Result |
|--------|--------|
| `dev` | Builds the image and pushes it to `abirami0901/dev` |
| `master` (after merging `dev`) | Builds the image, pushes it to `abirami0901/prod`, then deploys it to the EC2 app server |

```bash
# promote dev to prod
git checkout master
git merge dev
git push origin master
```

## AWS

**App server** (EC2 t2.micro, Ubuntu 24.04), security group:

| Port | Source | Reason |
|------|--------|--------|
| 80 (HTTP) | 0.0.0.0/0 | Anyone with the IP can open the application |
| 22 (SSH) | my IP `/32` | Server login only from my IP |
| 22 (SSH) | Jenkins server IP `/32` | Lets Jenkins deploy |
| 3001 | my IP `/32` | Uptime Kuma dashboard |

**Jenkins server** (EC2 t3.small, Ubuntu 24.04): ports 22 and 8080 are open only to my IP.

## Monitoring

Uptime Kuma (open source) runs on the app server and checks `http://100.48.10.146` every 30 seconds. An email notification is sent when the application goes down.

```bash
docker run -d --restart=always -p 3001:3001 -v uptime-kuma:/app/data --name uptime-kuma louislam/uptime-kuma:1
```

To test the alert: `docker stop react-app`, wait for the DOWN email, then `docker start react-app`.
