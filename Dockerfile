FROM openjdk:18-jdk-alpine AS builder
ARG SPIGOT_VERSION=1.19.2
RUN apk add git make gcc musl-dev \
    --update \
    --no-cache \
    --progress \
    -q
RUN wget -q https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
#RUN git config --global --unset core.autocrlf
RUN java -Xmx1024M -jar BuildTools.jar --rev ${SPIGOT_VERSION}

RUN git clone https://github.com/Tiiffi/mcrcon.git
RUN cd mcrcon && make && make install

FROM openjdk:18-jdk-alpine
ARG BUILD_DATE
ARG VCS_REF
ARG SPIGOT_VERSION=1.19.2
LABEL org.label-schema.schema-version="1.0.0-rc1" \
    maintainer="quentin.mcgaw@gmail.com" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/qdm12/spigot-docker" \
    org.label-schema.url="https://github.com/qdm12/spigot-docker" \
    org.label-schema.vcs-description="Lightweight Minecraft Spigot $SPIGOT_VERSION server container" \
    org.label-schema.vcs-usage="https://github.com/qdm12/spigot-docker/blob/master/README.md#setup" \
    org.label-schema.docker.cmd="docker run -d -p 25565:25565/tcp -v ./spigot:/spigot -e ACCEPT_EULA=true qmcgaw/spigot" \
    org.label-schema.docker.cmd.devel="docker run -it --rm -p 25565:25565/tcp -v ./spigot:/spigot -e ACCEPT_EULA=true qmcgaw/spigot" \
    org.label-schema.docker.params="ACCEPT_EULA=true or false to accept the EULA license,JAVA_OPTS=Java options to run the Spigot server" \
    org.label-schema.version="Spigot ${SPIGOT_VERSION}" \
    image-size="117MB" \
    ram-usage="500MB" \
    cpu-usage="Medium"
ENV JAVA_OPTS -Xms512m -Xmx1800m -XX:+UseConcMarkSweepGC \
    ACCEPT_EULA=false
COPY --from=builder "/spigot-${SPIGOT_VERSION}.jar" .
COPY --from=builder "/mcrcon/mcrcon" .
WORKDIR /spigot
ENTRYPOINT ln -sf "../spigot-${SPIGOT_VERSION}.jar" "spigot-${SPIGOT_VERSION}.jar" && \
    echo "eula=$ACCEPT_EULA" > eula.txt && \
    java -jar "spigot-${SPIGOT_VERSION}.jar" -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005 nogui
