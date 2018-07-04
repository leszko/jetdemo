FROM openjdk:8u171-jre-alpine
ENV HZ_HOME "/opt/hazelcast"
RUN mkdir -p ${HZ_HOME}
WORKDIR ${HZ_HOME}
ARG HZ_KUBE_VERSION=1.1.0
ARG HZ_EUREKA_VERSION=1.0.2

# Install bash & curl
RUN apk add --no-cache bash curl \
 && rm -rf /var/cache/apk/*

COPY target/jet-demo-1.0-SNAPSHOT-jar-with-dependencies.jar ${HZ_HOME}/jet.jar
COPY hazelcast.xml ${HZ_HOME}/hazelcast.xml

# Download and install Hazelcast plugins (hazelcast-kubernetes and hazelcast-eureka) with dependencies
# Use Maven Wrapper to fetch dependencies specified in mvnw/dependency-copy.xml
RUN curl -svf -o ${HZ_HOME}/maven-wrapper.tar.gz \
         -L https://github.com/takari/maven-wrapper/archive/maven-wrapper-0.3.0.tar.gz \
 && tar zxf maven-wrapper.tar.gz \
 && rm -fr maven-wrapper.tar.gz \
 && mv maven-wrapper* mvnw
COPY mvnw ${HZ_HOME}/mvnw
RUN cd mvnw \
 && chmod +x mvnw \
 && sync \
 && ./mvnw -f dependency-copy.xml \
           -Dhazelcast-kubernetes-version=${HZ_KUBE_VERSION} \
           -Dhazelcast-eureka-version=${HZ_EUREKA_VERSION} \
           dependency:copy-dependencies \
 && cd .. \
 && rm -rf $HZ_HOME/mvnw \
 && rm -rf ~/.m2 \
 && chmod -R +r $HZ_HOME

CMD ["bash", "-c", "exec java -cp '*' HelloWorld"]
