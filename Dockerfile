# healthcare-hl7-xml development image
ARG IMAGE=store/intersystems/irishealth-community:2019.4.0.383.0
FROM $IMAGE

USER root
RUN mkdir -p /opt/hl7xml
RUN mkdir -p /opt/hl7xml/app
RUN mkdir -p /opt/hl7xml/db
COPY irissession.sh /
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /irissession.sh
RUN chmod u+x /irissession.sh
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/hl7xml
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/hl7xml/app
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/hl7xml/db

WORKDIR /opt/hl7xml

USER irisowner
COPY . app
SHELL ["/irissession.sh"]

# run installer
RUN \
  # healthcare-hl7-xml installation
  do $SYSTEM.OBJ.Load("/opt/hl7xml/app/src/ITB/Installer.cls", "ck") \
  do $SYSTEM.OBJ.Load("/opt/hl7xml/app/src/ITB/Info.cls", "ck") \
  set vars("Namespace")="HL7XML" \
  set vars("CreateNamespace")="yes" \
  set vars("BasePath")="/opt/hl7xml/app" \
  set vars("DataDBPath")="/opt/hl7xml/db/data" \
  set vars("CodeDBPath")="/opt/hl7xml/db/code" \
  set sc = ##class(ITB.Installer).RunWithParams(.vars) \
  # iris config
  zn "%SYS" \
  do ##class(SYS.Container).QuiesceForBundling() \
  do ##class(Security.Users).UnExpireUserPasswords("*") \
  halt

# bringing the standard shell back
SHELL ["/bin/bash", "-c"]
CMD [ "-l", "/usr/irissys/mgr/messages.log" ]