HealthCare HL7 XML

Please, go through the following steps if you want to contribute to this project:

1. Report an issue. Describe it as much as you can, including how to reproduce it if possible.
2. Fork the repository, create a new branch
3. Develop your changes, make sure all unittests are still working. Add new unittests if needed.
4. Create a pull request

# Environment
Use the provided Docker container environment to develop your changes.

This environment includes:
* IRIS For Health (Community)
* IPM
* UnitTests

To start up you development environment:
```bash
docker compose build
docker compose up
```

Open terminal session:
```bash
docker compose exec -it iris-datapipe bash
iris session iris
```

Load local version:
```objectscript
zpm "load /app"
```

Run unittests:
```objectscript
zpm "healthcare-hl7-xml test -verbose"
```

You will have the following running:
* HL7XML: HealthCare HL7 XML installed in a regular way (no-zpm)
* HL7XML-ZPM: HealthCare HL7 XML installed using zpm

# Test publishing & deploying using IPM
See [Testing packages for ZPM](https://community.intersystems.com/post/testing-packages-zpm)

Load module from local dev environment:
```objectscript
zpm "load /app"
```

Set up testing IPM repository:
```objectscript
zpm "repo -n registry -r -url https://test.pm.community.intersystems.com/registry/ -user test -pass PassWord42"
```

Search packages already published in testing IPM repository:
```objectscript
zpm "search"
```

Test publishing process:
```objectscript
zpm "healthcare-hl7-xml publish -verbose"
```

Search published package in testing IPM repository:
```objectscript
zpm "search"
```

Run a container with an IRIS instance
```bash
docker run --name my-iris -d --publish 9091:51773 --publish 9092:52773 containers.intersystems.com/intersystems/irishealth-community:2023.1
```

Install ipm
```bash
docker exec -it my-iris iris session IRIS
set r=##class(%Net.HttpRequest).%New(),r.Server="pm.community.intersystems.com",r.SSLConfiguration="ISC.FeatureTracker.SSL.Config" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")
```

Change *superuser* default password using [Management Portal](http://localhost:9092/csp/sys/UtilHome.csp).

Set up testing IPM repository:
```objectscript
zpm "repo -n registry -r -url https://test.pm.community.intersystems.com/registry/ -user test -pass PassWord42"
```

Search published packages:
```objectscript
zpm "search"
```

Install the package:
```objectscript
zpm "install healthcare-hl7-xml"
```

Run unittests:
```objectscript
zpm "healthcare-hl7-xml test -verbose"
```
