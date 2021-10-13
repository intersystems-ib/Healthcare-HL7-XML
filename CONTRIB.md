# HealthCare HL7 XML

Please, go through the following steps if you want to contribute to this project:

1. Report an issue. Describe it as much as you can, including how to reproduce it if possible.
2. Fork the repository, create a new branch
3. Develop your changes, make sure all unittests are still working. Add new unittests if needed.
4. Create a pull request

## Environment
Use the provided Docker container environment to develop your changes.

This environment includes:
* IRIS For Health (Community)
* Installer and ZPM installer
* UnitTests

To start up you development environment:
```console
docker-compose build
docker-compose up
```

You will have the following running:
* HL7XML: HealthCare HL7 XML installed in a regular way (no-zpm)
* HL7XML-ZPM: HealthCare HL7 XML installed using zpm

## ZPM Package Manager
See [Testing packages for ZPM](https://community.intersystems.com/post/testing-packages-zpm) to learn about how to test zpm package publishing and deploying:

### Test publishing
Load module from local developing environment:
```
SER>zn "hl7xml-zpm"

HL7XML-ZPM>zpm

=============================================================================
|| Welcome to the Package Manager Shell (ZPM).                             ||
|| Enter q/quit to exit the shell. Enter ?/help to view available commands ||
=============================================================================
zpm:HL7XML-ZPM>load /app

[healthcare-hl7-xml]    Reload START (/app/)
[healthcare-hl7-xml]    Reload SUCCESS
[healthcare-hl7-xml]    Module object refreshed.
[healthcare-hl7-xml]    Validate START
[healthcare-hl7-xml]    Validate SUCCESS
[healthcare-hl7-xml]    Compile START
[healthcare-hl7-xml]    Compile SUCCESS
[healthcare-hl7-xml]    Activate START
[healthcare-hl7-xml]    Configure START
[healthcare-hl7-xml]    Configure SUCCESS
[healthcare-hl7-xml]    MakeDeployed START
[healthcare-hl7-xml]    MakeDeployed SUCCESS
[healthcare-hl7-xml]    Activate SUCCESS
```

Set up testing registry in order to test publishing:
```
zpm:HL7XML-ZPM>repo -n registry -r -url https://test.pm.community.intersystems.com/registry/ -user test -pass PassWord42

zpm:HL7XML-ZPM>search
registry https://test.pm.community.intersystems.com/registry/
```

Test publishing process:
```
zpm:HL7XML-ZPM>healthcare-hl7-xml publish -verbose
```

Test application is in the testing registry:
```
zpm:HL7XML-ZPM>search
registry https://test.pm.community.intersystems.com/registry/:
healthcare-hl7-xml 3.4.0
```

### Test deploying

Create an IRIS container:
```
docker run --name my-iris -d --publish 9091:51773 --publish 9092:52773 intersystemsdc/irishealth-community:2021.1.0.215.0-zpm
```

Change *superuser* default password using [Management Portal](http://localhost:9092/csp/sys/UtilHome.csp).

Open a terminal session:
```
docker exec -it my-iris iris session IRIS
````

Set up testing registry:
```
USER>zpm

=============================================================================
|| Welcome to the Package Manager Shell (ZPM).                             ||
|| Enter q/quit to exit the shell. Enter ?/help to view available commands ||
=============================================================================
zpm:USER>repo -n registry -r -url https://test.pm.community.intersystems.com/registry/ -user test -pass PassWord42

zpm:USER>search
registry https://test.pm.community.intersystems.com/registry/:
healthcare-hl7-xml 3.4.0
```

Install the package:
```
zpm:USER>install healthcare-hl7-xml

[healthcare-hl7-xml]    Reload START (/usr/irissys/mgr/.modules/USER/healthcare-hl7-xml/3.4.0/)
[healthcare-hl7-xml]    Reload SUCCESS
[healthcare-hl7-xml]    Module object refreshed.
[healthcare-hl7-xml]    Validate START
[healthcare-hl7-xml]    Validate SUCCESS
[healthcare-hl7-xml]    Compile START
[healthcare-hl7-xml]    Compile SUCCESS
[healthcare-hl7-xml]    Activate START
[healthcare-hl7-xml]    Configure START
[healthcare-hl7-xml]    Configure SUCCESS
[healthcare-hl7-xml]    MakeDeployed START
[healthcare-hl7-xml]    MakeDeployed SUCCESS
[healthcare-hl7-xml]    Activate SUCCESS
```


Run unittests:
```
zpm:USER>healthcare-hl7-xml test -verbose
```
