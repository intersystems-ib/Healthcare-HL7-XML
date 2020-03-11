Class ITB.ADP Extends %RegisteredObject
{

ClassMethod TestBigXML(msj As %String = "/app/unittest/hl7/ITB_OBX5.hl7") As %Status
{
		#define BufSize 32000
		#define FieldPath "ORCgrp(1).OBRuniongrp.OBXgrp(2).OBX:5"
		
		// generate a big stream of data
        set buf=""
		set cdata = "<![CDATA[<dat>"
		for i=1:1:$$$BufSize-100 set buf=buf_"A"
		set buf=buf_"B"
		//for i=1:1:100 set buf=buf_"A"
		set big = ##class(%Stream.GlobalCharacter).%New()
		do big.Write(cdata)
		for i=1:1:125 { //112 is the max for not using long strings.
			do big.Write(buf)
		}
		do big.Write("</dat>]]>")
		
		// array to hold size of data before / after conversion
		set size(0)=big.Size
		set size(1)=""
		
		// load er7 message
		set er7 = ##class(EnsLib.HL7.Message).ImportFromFile(msj)
		set er7.DocType = "ITB:ORM_O01"
		
		// write buffer in OBX:5
		do big.Rewind()
		do er7.StoreFieldStreamRaw(big, $$$FieldPath)
		
		do er7.OutputToFile("/opt/hl7xml/big.hl7")
		// convert er7 message to xml message
		set xml = ##class(ITB.HL7.Util.Convert).ER7ToXML(er7,.sc)

		// convert xml message back to er7 message
		do xml.Rewind()
		set xmlfile = ##class(%Stream.FileCharacter).%New()
		set xmlfile.Filename = "/opt/hl7xml/big.xml"
		do xmlfile.CopyFrom(xml)
        do xmlfile.%Save()

		set er7itb = ##class(ITB.HL7.Util.Convert).XMLToER7(xml,.sc,"ITB")
        // when the size of the OBX is longer than long-strings 3.5MB, the OBX value gets duplicated in the next OBX
		do er7itb.OutputToFile("/opt/hl7xml/big2.hl7")

		// extract OBX:5 from converted message
		do er7itb.GetFieldStreamRaw(.bigOutput, $$$FieldPath)
		set size(1) = bigOutput.Size
		
		zw size
    quit 1
}

}
