# HealthCare-HL7-XML quickstart environment
#
# Use this image to:
# -Run Quick Start samples. See README.md
# -Test HealthCare-HL7-XML development and installation
#
ARG IMAGE=containers.intersystems.com/intersystems/irishealth-community:2023.1
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

# run iris.script
WORKDIR /opt/hl7xml/app
RUN iris start IRIS \
    && iris session IRIS < iris.script \
    && iris stop IRIS quietly