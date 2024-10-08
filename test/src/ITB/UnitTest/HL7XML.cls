Include ITB

/// Test cases for HL7 ER7/XML basic conversions.
Class ITB.UnitTest.HL7XML Extends %UnitTest.TestCase
{

/// Past to test files
Property HL7Path As %String;

/// Initialize 
Method OnBeforeAllTests() As %Status
{
	set ret = $$$OK
	try {
		// normalize path
		set base=^UnitTestRoot
		if base="" $$$ThrowStatus($$$ERROR($$$GeneralError,"^UnitTestRoot cannot be empty"))
		
		set base=##class(%File).NormalizeDirectory("../../../..", base)
		if base="" $$$ThrowStatus($$$ERROR($$$GeneralError,"^UnitTestRoot path incorrect"))
		
		set ..HL7Path=##class(%File).SubDirectoryName(base,"unittest/hl7",1)
		if ..HL7Path="" $$$ThrowStatus($$$ERROR($$$GeneralError,"^UnitTestRoot TestPath path incorrect"))
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// HL7 ER7 to XML conversions
Method TestER7ToXML()
{
	set rs = ##class(%ResultSet).%New("%File:FileSet")
 	set sc = rs.Execute(..HL7Path,"*.hl7")
 	do $$$AssertStatusOK(sc,"Looping over *.hl7 files in "_..HL7Path)
	while (rs.Next()) {
		set er7path = rs.Data("Name")
		set er7name = ##class(%File).GetFilename(er7path)
		set schema = $piece(er7name,"_",1)
		set xmlpath = er7path_".xml"
		
		// check that reference HL7 XML file exists
		set sc = ##class(%File).Exists(xmlpath)
		do $$$AssertEquals(sc, 1, er7name_": reference HL7 XML file exists")
		
		// read reference HL7 XML file
		set xmlfile = ##class(%Stream.FileCharacter).%New()
		set xmlfile.Filename = xmlpath
		// -> as HL7 XML files were created in Windows, handle LineTerminator conversions if is a Unix
		if $$$isUNIX {
			set tmp = ##class(%Stream.GlobalCharacter).%New()
			while 'xmlfile.AtEnd {
				set buf = $replace(xmlfile.Read(),$c(13,10),$c(10))
				do tmp.Write(buf)
			}
			set xmlfile = tmp
		}
		// -> handle line terminator differences when using files downloaded from source code repo. 
		else {
			set tmp = ##class(%Stream.GlobalCharacter).%New()
			while 'xmlfile.AtEnd {
				set buf = $replace(xmlfile.Read(),$c(10),$c(13,10))
				do tmp.Write(buf)
			}
			set xmlfile = tmp
		}
		
		// import er7 file
		set er7 = ##class(EnsLib.HL7.Message).ImportFromFile(er7path,,.sc)
		do $$$AssertStatusOK(sc, er7name_": import er7 file")
		
		// set hl7 doctype
		set er7.DocType = ##class(ITB.HL7.Util.Convert).CalculateDocType(er7,schema)
		do $$$AssertStatusOK(er7.BuildMap(), er7name_": doctype="_er7.DocType)
		
		// convert to xml format
		set xmlitb = ##class(ITB.HL7.Util.Convert).ER7ToXML(er7,.sc)
		do $$$AssertStatusOK(sc, er7name_": ER7ToXML")
		
		// check that converted xml and reference xml are equal
		set hash1 = $system.Encryption.SHA1HashStream(xmlfile)
		set hash2 = $system.Encryption.SHA1HashStream(xmlitb)
		do $$$AssertEquals(hash1, hash2, er7name_": XML conversion")
	}
}

/// HL7 ER7 to XML conversions
Method TestXMLToER7()
{
	set rs = ##class(%ResultSet).%New("%File:FileSet")
 	set sc = rs.Execute(..HL7Path,"*.hl7.xml")
 	do $$$AssertStatusOK(sc,"Looping over *.hl7.xml files in "_..HL7Path)
	while (rs.Next()) {
		set xmlpath = rs.Data("Name")
		set xmlname = ##class(%File).GetFilename(xmlpath)
		set schema = $piece(xmlname,"_",1)
		set er7path = $replace(xmlpath,".xml","")
		
		// check that reference HL7 ER7 file exists
		set sc = ##class(%File).Exists(er7path)
		do $$$AssertEquals(sc, 1, xmlname_": reference HL7 ER7 file exists")
		
		// read reference er7 file
		set er7file = ##class(EnsLib.HL7.Message).ImportFromFile(er7path,,.sc)
		do $$$AssertStatusOK(sc, xmlname_": import er7 file")
		
		// set hl7 doctype
		set er7file.DocType = ##class(ITB.HL7.Util.Convert).CalculateDocType(er7file,schema)
		do $$$AssertStatusOK(er7file.BuildMap(), xmlname_": doctype="_er7file.DocType)
		
		// read xml hl7 file
		set xml = ##class(%Stream.FileCharacter).%New()
		set xml.Filename=xmlpath
		
		// convert xml to er7 format
		#dim er7itb As EnsLib.HL7.Message = ##class(ITB.HL7.Util.Convert).XMLToER7(xml,.sc, schema)
		do $$$AssertStatusOK(sc, xmlname_": XMLToER7")
		
		// check that converted er7 and reference er7 are equal
		set er7fileStream = ##class(%Stream.GlobalCharacter).%New()
		do er7file.OutputToLibraryStream(er7fileStream)
		
		set er7itbStream = ##class(%Stream.GlobalCharacter).%New()
		do er7itb.OutputToLibraryStream(er7itbStream)
		
		set hash1 = $system.Encryption.SHA1HashStream(er7fileStream)
		set hash2 = $system.Encryption.SHA1HashStream(er7itbStream)
		do $$$AssertEquals(hash1, hash2, xmlname_": ER7 conversion")
	}
}

/// HL7 field greater than 32K
Method TestBigField()
{
	#if $$$ITB32K	
		#define BufSize 32000
		#define FieldPath "ORCgrp(1).OBRuniongrp.OBXgrp(3).OBX:5"
		
		// generate a big stream of data
		set buf = ""
		for i=1:1:$$$BufSize set buf=buf_"A"
		set big = ##class(%Stream.GlobalCharacter).%New()
		for i=1:1:200 {
			do big.Write(buf)
		}
		
		do $$$AssertEquals(big.Size, 200*$$$BufSize, "generated big stream of "_(big.Size\1024)_" KB")
		
		// array to hold size of data before / after conversion
		set size(0)=big.Size
		set size(1)=""
		
		// load er7 message
		set er7 = ##class(EnsLib.HL7.Message).ImportFromFile(..HL7Path_"ITB_OBX5.hl7")
		set er7.DocType = "ITB:ORM_O01"
		
		// write buffer in OBX:5
		do big.Rewind()
		do er7.StoreFieldStreamRaw(big, $$$FieldPath)

		// test standard StoreFieldStreamRaw / GetFieldStreamRaw
		do er7.GetFieldStreamRaw(.bigEr7, $$$FieldPath)
		set size(1) = bigEr7.Size
		do $$$AssertEquals(size(0), size(1), "("_er7.DocType_") ER7 StoreFieldStreamRaw / GetFieldStreamRaw: "_size(0)_", "_size(1))

		// convert er7 message to xml message
		set xml = ##class(ITB.HL7.Util.Convert).ER7ToXML(er7,.sc)
		do $$$AssertStatusOK(sc, "er7->xml")
		
		// convert xml message back to er7 message
		do xml.Rewind()
		set er7itb = ##class(ITB.HL7.Util.Convert).XMLToER7(xml,.sc,"ITB")
		do $$$AssertStatusOK(sc, "xml->er7")
		
		// extract OBX:5 from converted message
		do er7itb.GetFieldStreamRaw(.bigOutput, $$$FieldPath)
		set size(1) = bigOutput.Size
		
		do $$$AssertEquals(size(0), size(1), "("_er7itb.DocType_") big stream with same size: "_size(0)_", "_size(1))
	#else
		quit
	#endif
}

/// HL7 field with embedded XML greater than 32K
Method TestBigXMLEmbeddedField()
{
	#if $$$ITB32K	
		#define BufSize 32000
		#define FieldPath "ORCgrp(1).OBRuniongrp.OBXgrp(3).OBX:5"
		
		// generate a big stream of data
        set buf=""
		set cdata = "<![CDATA[<dat>"
		for i=1:1:$$$BufSize-1 set buf=buf_"A"
		set buf=buf_"B"
		//for i=1:1:100 set buf=buf_"A"
		set big = ##class(%Stream.GlobalCharacter).%New()
		do big.Write(cdata)
		for i=1:1:200 {
			do big.Write(buf)
		}
		do big.Write("</dat>]]>")
		
		// array to hold size of data before / after conversion
		set size(0)=big.Size
		set size(1)=""
		
		// load er7 message
		set er7 = ##class(EnsLib.HL7.Message).ImportFromFile(..HL7Path_"ITB_OBX5.hl7")
		set er7.DocType = "ITB:ORM_O01"
		
		// write buffer in OBX:5
		do big.Rewind()
		do er7.StoreFieldStreamRaw(big, $$$FieldPath)
		
		// convert er7 message to xml message
		set xml = ##class(ITB.HL7.Util.Convert).ER7ToXML(er7,.sc)
		do $$$AssertStatusOK(sc, "er7->xml")
		
		// convert xml message back to er7 message
		do xml.Rewind()
		set er7itb = ##class(ITB.HL7.Util.Convert).XMLToER7(xml,.sc,"ITB")
		do $$$AssertStatusOK(sc, "xml->er7")
		
		// extract OBX:5 from converted message
		do er7itb.GetFieldStreamRaw(.bigOutput, $$$FieldPath)
		set size(1) = bigOutput.Size
		
		do $$$AssertEquals(size(0), size(1), "big stream with same size")
	#else
		quit
	#endif
}

}
