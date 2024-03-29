#
# HealthCare-HL7-XML sample environment
#
# Use this image to:
# -Run Quick Start samples. See README.md
# -Test HealthCare-HL7-XML developments and installation procedures.
#
ARG IMAGE=containers.intersystems.com/intersystems/irishealth-community:2022.1.0.209.0
FROM $IMAGE

USER root

# create directories for testing environment
RUN mkdir -p /opt/hl7xml/app /opt/hl7xml/db

# copy source code
WORKDIR /opt/hl7xml
COPY . app

# change ownership
RUN chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/hl7xml
USER ${ISC_PACKAGE_MGRUSER}

# download latest zpm version
RUN wget https://pm.community.intersystems.com/packages/zpm/latest/installer -O /tmp/zpm.xml

# run iris.script
WORKDIR /opt/hl7xml/app
RUN iris start IRIS \
    && iris session IRIS < iris.script \
    && iris stop IRIS quietly