#!/bin/bash

# Pull Docker images
docker pull grafana/grafana:latest
docker pull sonatype/nexus3:latest
docker pull jenkins/jenkins:lts

# Run Docker containers
docker run -d --name grafana -p 3000:3000 grafana/grafana:latest
docker run -d --name nexus -p 8081:8081 sonatype/nexus3:latest
docker run -d --name jenkins -p 8080:8080 jenkins/jenkins:lts
