<img src="./img/twitter_header_photo.png">

*Healthcare HL7 XML* (also known as *ITB* or *Ensemble HL7 XML*) is an application you can install in [InterSystems Healthcare products](https://www.intersystems.com) to handle HL7 v.2.x messages in XML format.

# What is included?
*Healthcare HL7 XML* includes *Business Services* and *Operations* you can use in your productions to handle *ER7* and *XML HL7 messages* in the same way.

<img src="./img/healthcare-hl7-xml-diagram.png" width="600px">

# Quick Start
Run a quick test using a test docker environment and have a look at the examples. You can use [VSCode](https://code.visualstudio.com), see some [tutorials](https://comunidadintersystems.com/videotutoriales).

1. Clone the repository:
```
git clone https://github.com/intersystems-ib/Healthcare-HL7-XML
```

2. Build and run the sample environment. This will run an [InterSystems IRIS For Health](https://www.intersystems.com/products/intersystems-iris-for-health/) with *Healthcare HL7 XML* installed
```bash
docker-compose build
docker-compose up
```

You can access now to the [Management Portal](http://localhost:52773/csp/sys/UtilHome.csp) using `superuser`/ `SYS`.

3. Go to [ITB.Production.TestXMLHL7File](http://localhost:52773/csp/hl7xml/EnsPortal.ProductionConfig.zen?PRODUCTION=ITB.Production.TestXMLHL7File) production and start the production.

4. Send some sample messages. In the directory you downloaded the code, copy some files from [/samples](./samples) into [/samples/input](./samples/input)

5. See the messages in the production and have a look at [/samples/output](./samples/output)


# Requirements
Healthcare HL7 XML supports only:
* **InterSystems IRIS For Health**.
* **Health Connect**.
* **Ensemble >=2016.2**

You can still download latest **deprecated** release [v.2.1](https://github.com/intersystems-ib/healthcare-hl7-xml/releases/tag/v2.1) (compatible with older Ensemble releases)

# Installation
* Go to [Releases](https://github.com/intersystems-ib/Healthcare-HL7-XML/releases) and download the latest version.

* Unzip it in a temporary directory (e.g. /tmp)

* Open an interactive session (terminal)

* Move to your namespace (e.g. TEST)
```
zn "TEST"
```

* Load installer from an interactive session (terminal):
```objectscript
do $system.OBJ.Load("/tmp/Healthcare-HL7-XML-master/src/ITB/Installer.cls","ck")
```

* Run installer:
```objectscript
do ##class(ITB.Installer).Run("/tmp/Healthcare-HL7-XML-master")
```

# Getting Started

## Simple Conversions
Conversions between ER7 and XML format can be made using `ITB.HL7.Util.Convert` class.

### ER7 to XML
```
TEST>set er7=##class(EnsLib.HL7.Message).ImportFromFile("/app/unittest/hl7/2.5_ORMO01.hl7", .sc)
TEST>set er7.DocType = er7.chooseDocType(.desc)
TEST>set xml = ##class(ITB.HL7.Util.Convert).ER7ToXML(er7,.sc)
TEST>write sc
1
TEST>write xml.Read()
<ORM_O01 xmlns="urn:hl7-org:v2xml"><MSH><MSH.1>|</MSH.1><MSH.2>^~\&amp;</MSH.2><MSH.3><HD.1>hphis</HD.1></MSH.3><MSH.4><HD.1>192.168.2.203</HD.1></MSH.4><MSH.5><HD.1>EPIC</HD.1></MSH.5><MSH.7><TS.1>20131011093851</TS.1></MSH.7><MSH.9><MSG.1>ORM</MSG.1><MSG.2>O01</MSG.2></MSH.9><MSH.10>14AAACVDD</MSH.10><MSH.11><PT.1>P</PT.1></MSH.11><MSH.12><VID.1>2.5</VID.1></MSH.12><MSH.15>AL</MSH.15><MSH.16>NE</MSH.16></MSH><ORM_O01.PATIENT><PID><PID.2><CX.1>241900</CX.1></PID.2><PID.4><CX.1>MAPO0371545477</CX.1></PID.4><PID.5><XPN.1><FN.1>MEDIANO</FN.1></XPN.1><XPN.2>FOUAZ</XPN.2><XPN.3>TEST</XPN.3></PID.5><PID.7><TS.1>19740602</TS.1></PID.7><PID.8>M</PID.8><PID.11><XAD.1><SAD.1>CARRETERA ENTORNO DE PRUEBAS</SAD.1></XAD.1><XAD.3>SANT VICENT DELS HORTS</XAD.3><XAD.4>8</XAD.4><XAD.5>08620</XAD.5><XAD.6>724</XAD.6><XAD.8>1</XAD.8></PID.11><PID.13><XTN.1>123456789</XTN.1></PID.13><PID.14><XTN.1>123456789</XTN.1></PID.14><PID.19>08/03072889-52</PID.19><PID.20><DLN.1>52912868B</DLN.1></PID.20><PID.28><CE.1>724</CE.1></PID.28><PID.30>no</PID.30></PID><ORM_O01.PATIENT_VISIT><PV1><PV1.1>1</PV1.1><PV1.4>O</PV1.4><PV1.7><XCN.1>1105</XCN.1><XCN.2><FN.1>TORRA</FN.1></XCN.2><XCN.3>SANZ</XCN.3><XCN.4>JOAN</XCN.4></PV1.7><PV1.7><XCN.1>1105</XCN.1></PV1.7><PV1.8><XCN.1>1105</XCN.1><XCN.2><FN.1>TORRA</FN.1></XCN.2><XCN.3>SANZ</XCN.3><XCN.4>JOAN</XCN.4></PV1.8><PV1.8><XCN.1>1105</XCN.1></PV1.8><PV1.10>DIGC</PV1.10><PV1.17><XCN.1>1105</XCN.1><XCN.2><FN.1>TORRA</FN.1></XCN.2><XCN.3>SANZ</XCN.3><XCN.4>JOAN</XCN.4></PV1.17><PV1.17><XCN.1>1105</XCN.1></PV1.17><PV1.19><CX.1>302141984</CX.1></PV1.19><PV1.44><TS.1>20131011104000</TS.1></PV1.44></PV1></ORM_O01.PATIENT_VISIT></ORM_O01.PATIENT><ORM_O01.ORDER><ORC><ORC.1>NW</ORC.1><ORC.2><EI.1>2089258</EI.1></ORC.2><ORC.4><EI.1>1760391</EI.1></ORC.4><ORC.5>HD</ORC.5><ORC.7><TQ.6>1</TQ.6></ORC.7><ORC.9><TS.1>20131011093800000</TS.1></ORC.9><ORC.12><XCN.1>2214</XCN.1><XCN.2><FN.1>SERRANO</FN.1></XCN.2><XCN.3>LAIA</XCN.3></ORC.12><ORC.13><PL.1>CIRC</PL.1></ORC.13><ORC.16><CE.2>Motivo 1</CE.2></ORC.16></ORC><ORM_O01.ORDER_DETAIL><ORM_O01.ORDER_CHOICE><OBR><OBR.2><EI.1>2089258</EI.1></OBR.2><OBR.4><CE.1>1</CE.1><CE.2>Interconsulta</CE.2></OBR.4><OBR.10><XCN.2><FN.1>S/I</FN.1></XCN.2><XCN.3>S/I</XCN.3></OBR.10><OBR.16><XCN.1>2214</XCN.1><XCN.2><FN.1>SERRANO</FN.1></XCN.2><XCN.3>LAIA</XCN.3></OBR.16><OBR.19>CIRC</OBR.19><OBR.21>DIGH</OBR.21><OBR.27><TQ.6>1</TQ.6></OBR.27><OBR.31><CE.1>Motivo 2</CE.1></OBR.31></OBR></ORM_O01.ORDER_CHOICE><NTE><NTE.3>Notas de prueba.</NTE.3></NTE></ORM_O01.ORDER_DETAIL></ORM_O01.ORDER></ORM_O01>
```

### XML To ER7
```
TEST>set xml = ##class(%Stream.FileCharacter).%New()
TEST>set xml.Filename="/app/unittest/2.5_OBX5-ST.hl7.xml"
TEST>set er7=##class(ITB.HL7.Util.Convert).XMLToER7(xml,.sc,"2.5")
TEST>write sc
1
TEST>write er7.OutputToString()
MSH|^~\&|hphis|192.168.2.203|EPIC||20131011093851||ORM^O01|ITM14AAACVDD|P|2.5|||
PID||241900||MAPO0370403001|TEST^TEST^TEST||19740602|M|||BARCELONA^^BARCELONA^8^
PV1|1|||O|||1105^TEST^TEST^TEST~1105|1105^TEST^TEST^TEST~1105||DIGC|||||||1105^T
ORC|NW|2089258||1760391|HD||^^^^^1||20131011093800000|||2214^TEST^LAIA|CIRC|||^R
OBR||2089258||1^INTERTEST||||||^S/I^S/I||||||2214^SERRANO^LAIA|||CIRC||DIGH|||||
OBX|1|ST|4|7|ABCD1234
```

## Test Productions
*Healthcare HL7 XML* includes different productions in `ITB.Production.*` package which can be used to test HL7 XML components in an *Interoperability* production.

| Production | Description |
| --------- | ----------- |
| ITB.Production.TestXMLHL7File | Transform HL7 Files using ER7 / XML format. Understand this production moving to more complex scenarios |
| ITB.Production.TestXMLHL7SOAP | Sample webservice that receives HL7 XML message as an incoming string |
| ITB.Production.TestXMLHL7HTTP | HL7 XML files sent/received through HTTP |
| ITB.Production.TestXMLHL7TCP | HL7 XML files sent/received through TCP |
| ITB.Production.TestXMLHL7TCPLoopback | HL7 XML files sent/received through TCP (loopback) |

# Advanced options
## Custom HL7 schemas
Lookup tables are used to map HL7 XML group names and EnsLib.HL7.Message group names:  
* *Healthcare HL7 XML* installation includes a lookup table for HL7 2.5 schema called *hl7_2.5*
* Each HL7 schema used in XML format must include a lookup table with the name *hl7_[schema]*
* For instance: if a custom HL7 schema called *CUSTOM* is used in XML format in a production, a *hl7_CUSTOM* lookup
table must be created containing all needed mappings.

# Segment fields with dynamic data structures
A segment field that has a dynamic data structure can be defined using a custom HL7 schema.  
For instance: if it's needed to have an OBX.5 field with a data structured defined by OBX.2 field:  
* Create a new HL7 schema copying *2.5.HL7* in Studio.  
* Mark the new HL7 schema as standard with std=1 to allow non-resolved data structure references.
```xml
<Category name="CUSTOM" std="1">
```
* Find OBX segment structure definition and change field 5 datatype to *@2* that means that it will take the datatype defined in OBX.2.
```xml
<SegmentSubStructure piece='5' description='Observation Value' datatype='@2' symbol='&' required='C' ifrepeating='1'/>
```

---
**NOTE**

*This application is an open-source add-on for InterSystems HealthCare products and does not form part of the official release. InterSystems WRC technical assistance will not attend issues related with this application.*

---
