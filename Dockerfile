FROM fedora:latest as clone-ticket-monster

RUN yum update -y
RUN yum install git -y 
WORKDIR /app
RUN git clone https://github.com/jboss-developer/ticket-monster.git

FROM maven:3.6.0-jdk-8-alpine as build-run-maven
COPY --from=clone-ticket-monster /app/ /app
WORKDIR /app/ticket-monster/demo/
#RUN mvn  
RUN mvn install 

FROM jboss/wildfly as jboss-wildfly-install
ENV JBOSS_MODE standalone
RUN /opt/jboss/wildfly/bin/add-user.sh admin Admin#70365 --silent
#RUN "mkdir /opt/jboss/wildfly/customization/"
WORKDIR /opt/jboss/wildfly/
COPY customization /opt/jboss/wildfly/customization/

USER root

# Run customization scripts as root
RUN chmod +x /opt/jboss/wildfly/customization/execute.sh
RUN /opt/jboss/wildfly/customization/execute.sh standalone standalone-ha.xml

COPY --from=build-run-maven /app/ticket-monster/demo/target/ticket-monster.war /opt/jboss/wildfly/standalone/deployments/

# Fix for Error: Could not rename /opt/jboss/wildfly/standalone/configuration/standalone_xml_history/current
RUN rm -rf /opt/jboss/wildfly/standalone/configuration/standalone_xml_history

RUN chown -R jboss:jboss /opt/jboss/wildfly/

USER jboss

# Expose the ports we're interested in
EXPOSE 8080 9990 8009

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to external interface
CMD /opt/jboss/wildfly/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 -c standalone-ha.xml




