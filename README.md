Antoine gamain

Enzo Baldisserri


# Init des dockers

> Petite Astuce , il existe une interface Grafique pour gérer tous ses container : https://www.portainer.io/

les commandes pour lancer les différents docker :

En premier on créé un reseau pour que nos docker communiquent entre eux :

```bash
docker network create ndevops
```

## Postgres

### Docker File

```docker
FROM postgres

ENV POSTGRES_DB=db \
POSTGRES_USER=usr \
POSTGRES_PASSWORD=pwd

copy ./SQL /docker-entrypoint-initdb.d
```
> On spécifie les user/psw dans le dockerfile

### Commande bash

```bash
docker build . -t pg_devops 
docker run --name=pg_devops -v /tmp/data:/var/lib/postgresql/data --network ndevops -d  pg_devops
```
> On expose pas les ports car seul l'API y a accés via un network docker
> On stock les données dans un fichier exterieur au conteneur pour la persistance des données

## API Java

### Docker file

```docker
# Build
FROM maven:3.6.3-jdk-11 AS myapp-build
ENV MYAPP_HOME /opt/myapp
WORKDIR $MYAPP_HOME
COPY pom.xml .
RUN mvn dependency:go-offline

COPY src ./src
RUN mvn package -DskipTests

# Run
FROM openjdk:11-jre
ENV MYAPP_HOME /opt/myapp
WORKDIR $MYAPP_HOME
COPY --from=myapp-build $MYAPP_HOME/target/*.jar $MYAPP_HOME/myapp.jar

EXPOSE 8080

ENTRYPOINT java -jar myapp.jar
```
>On remarque qu'on utilise la jdk pour compiler mais que le conteneur sera fourni avec uniquement le jre

### Commande bash

```bash
docker build . -t docker_backend
docker run --name docker_backend --network ndevops -p  8080:8080 docker_backend
```

## Front Httpd 

### Docker file

```docker
FROM httpd

COPY src/*.html /usr/local/apache2/htdocs/
Copy src/*.conf /usr/local/apache2/conf/httpd.conf
```

### Commande bash
```bash
docker build . -t httpd-devops
docker run -dit --name my-running-app --network ndevops -p 80:80 httpd-devops
```

# Docker-compose : la libération

Au cour du Tp on a du retaper 10 000 fois les commande bash afin de build et de remonter les conteneurs , long et laborieux.

Il existe un moyen de simplifier cette opération à l'aide d'un docker-compose : 

```yml
version: '3'
services:
  docker_backend:
    build: ./simple-api/.
    networks : 
      - ndevops
    depends_on : 
      - pg_devops
  pg_devops:
    build: ./Bdd/. 
    networks : 
      - ndevops
    volumes : 
      - /tmp/data:/var/lib/postgresql/data 
  my-running-app : 
    build : ./Httpd/.
    ports : 
      - "80:80"
    networks : 
      - ndevops

networks : 
    ndevops :
```

# Travis

On peut declancher des traitement spécifique à la suite d'un push sur git ; pour cela on utilise un outil de CI/CD : travis (https://travis-ci.org/)

```yaml
language: java
sudo: false
install: true

service: 
  - docker

jobs:
  include:
    - stage: "Tests"                
      name: "Test"  
      if: branch = master          
      script:        
      - mvn clean verify
      - mvn package -DskipTests             
      - docker build sample-application-http-api-server/. -t $user/backend    
      - docker login -u $user -p $psw
      - docker push $user/backend        
      - docker build sample-application-db-changelog-job/. -t $user/db-changelog-job    
      - docker login -u $user -p $psw
      - docker push $user/db-changelog-job
      - docker build Bdd/. -t $user/bdd 
      - docker login -u $user -p $psw
      - docker push $user/bdd
      - docker build ./Httpd/. -t $user/reverseproxy 
      - docker login -u $user -p $psw
      - docker push $user/reverseproxy


cache:
  directories:
  - .autoconf
  - $HOME/.m2

```

## SonarCloud

Initialisation de SonarCloud:
- Création d'une organisation sur [SonarCloud](https://sonarcloud.io/)
- "Analyze new project" > "sample-application-students"
- Ajout du fichier vide nommé .sonarcloud.properties dans le dépôt git
- Fini !