FROM jboss/wildfly as jboss-wildfly-install
ENV JBOSS_MODE standalone

USER root
RUN yum update -y
RUN yum install git -y 
RUN yum install maven -y
RUN yum install dos2unix -y

WORKDIR /app/
RUN git clone https://github.com/jboss-developer/ticket-monster.git
WORKDIR /app/ticket-monster/demo/
RUN mvn install
RUN cp /app/ticket-monster/demo/target/ticket-monster.war /opt/jboss/wildfly/standalone/deployments/

RUN /opt/jboss/wildfly/bin/add-user.sh admin Admin#70365 --silent
COPY customization /opt/jboss/wildfly/customization/
RUN chmod +x /opt/jboss/wildfly/customization/execute.sh
RUN /opt/jboss/wildfly/customization/execute.sh standalone 
RUN rm -rf /opt/jboss/wildfly/standalone/configuration/standalone_xml_history
RUN chown -R jboss:jboss /opt/jboss/wildfly/

USER jboss
# Expose the ports we're interested in
EXPOSE 8080 9990 8009
# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to external interface
CMD /opt/jboss/wildfly/bin/standalone.sh -b `hostname -i` -bmanagement `hostname -i` 



