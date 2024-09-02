Include (EnsHL7, ITB)

/// <h3>Format HL7 from ER7 to XML and viceversa</h3>
/// 
/// <p>LookUp tables with mappings from Ensemble XML groups to HL7 XML group names are <b>REQUIRED</b> to generate valid HL7 XML files 
/// See <class>ITK.HL7.Util.XSDParser</class></p>
/// 
/// <p>Use <class>ITB.HL7.Util.Convert</class> to convert HL7 messages.</p>
/// 
/// <p>Based on <class>EnsLib.ITK.HL7.FormatXMLv2</class> by Rajiv Bhatia</p>
/// 
/// Changes:
/// <ul>
///   <li> 2018-11-08, duquesno: Remove $ZSTRIP(,"*C") from XML elements, to keep LineFeeds (allow $c(10) to reach XMLEscape() function)</li>
/// </ul>
Class ITB.HL7.Format.HL7XMLv2 Extends (%XML.SAX.ContentHandler, EnsLib.EDI.IOFormatInterface) [ System = 4 ]
{

Parameter ChildLinks = 10;

/// Return 1 if we took care of the whole document or got an error. Returning 0 means the caller will continue doing component segments as usual.
/// Change Log:
/// Base Release: Rajiv Bhatia
ClassMethod OutputDocument(pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String, pSequenceNumber As %String) As %Boolean
{
	set pStatus=$$$OK
	
	Set tName=$piece(pDocObj.Name,"_",1,2)
	
	set tCat=pDocObj.DocTypeCategory
	//ITB+
	#if $$$ITBDebug 
		kill ^zitb
	#endif
	//set tSchemaDescription=$tr(^EnsHL7.Description(tCat),"'","""")
	//ITB-
	
	// TI 50815 - The Root Tag is derived from the DocType of the message
	Set tRootTag = $P(pDocObj.DocType, ":", 2)
	//ITB+
	/*
	set tNS=$piece($piece(tSchemaDescription,"="),"xmlns:",2)_":"
	Set tDescription=##class(EnsLib.HL7.Schema).GetDescription("MT:"_tCat_":"_tName)
	set tDescription=$tr(tDescription,"'","""")
	//set tTopLevelTag=tNS_tRootTag_" "_tSchemaDescription_" "_tDescription
	set tTopLevelTag=tNS_tRootTag_" "_tSchemaDescription
	*/
	set tTopLevelTag=tRootTag
	set tStripNamespace = $get(^||%itb("ER7ToXML","StripNamespace"),"0")
	set tNamespace = $select(tStripNamespace=0:" xmlns=""urn:hl7-org:v2xml""", 1:"")
	Do pIOStream.Write("<"_tTopLevelTag_tNamespace_">")  Quit:$$$ISERR(pStatus) 1
	//ITB-
	Quit 0 ; let the caller iterate the segments
}

ClassMethod OutputDocumentEnd(pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String, pSequenceNumber As %String)
{
	
	Set tName=$piece(pDocObj.Name,"_",1,2)
	set tCat=pDocObj.DocTypeCategory
	//ITB+
	//set tSchemaDescription=$tr(^EnsHL7.Description(tCat),"'","""")
	//set tNS=$piece($piece(tSchemaDescription,"="),"xmlns:",2)_":"
	set tNS=""
	//ITB-
	
	// TI 50815 - The Root Tag is derived from the DocType of the message
	Set tRootTag = $P(pDocObj.DocType, ":", 2)
	Do pIOStream.WriteLine("</"_tNS_tRootTag_">",,.pStatus)
	
	Quit ; no return value
}

/// Return 1 if we took care of the segment or got an error. Returning 0 means the caller will output the segment as usual.
/// Change Log:
/// Base Release: Rajiv Bhatia
ClassMethod OutputSegment(pSegObj As EnsLib.EDI.Segment, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, pSeparators As %String, pSegNum As %String, pSegPath As %String, pParentDoc As EnsLib.EDI.Document, ByRef pSequenceNumber As %String) As %Boolean
{
	//ITB+
	//hardcoded for now
	//set tNS="hl7"_":"
	//Do pSegObj.decompose()
	set tNS=""
	//ITB-
	
	Set tName=pSegObj.Name
	If ""=tName Set pStatus=$$$ERROR($$$EnsErrGeneral,"Can't do SimpleHL7v2 XML output of a segment with no name: '"_$E(pSegObj.GetValueAt(),1,1000)_"'") Quit 1
	Set tDocType=pParentDoc.DocType
	//Set pSegPath=$G(pSegPath) Set:pSegPath=pSegNum pSegPath=""
	
	//ITB+
	do ..IsGroupStart(pSegObj, pIOStream, pSegNum, pSegPath, pParentDoc)
	//ITB-
	
	if '$get(pSeparators) s pSeparators=pSegObj.Separators

	Set tReplaceSpec(" ")="&nbsp;"
	Set tReplaceSpec($C(9))="\t"
	Set tReplaceSpec($C(13))="\r"
	Set tReplaceSpec($C(10))="\n"

	Set iCat=$P(tDocType,":"), iSeg=tName
	
	if '##class(EnsLib.HL7.Schema).ElementExists("SS:"_iCat_":"_iSeg) set pStatus=1 quit 1
	Set tDescription=##class(EnsLib.HL7.Schema).GetDescription("SS:"_iCat_":"_iSeg)
	Set iCnt=pSegObj.GetValueAt("*",pSeparators)
	Do pIOStream.Write("<"_tNS_tName_">",,.pStatus)  Quit:$$$ISERR(pStatus)
	
	//Set tIndent=pIOStream.LineTerminator_$C(9), tElem=0
	//indentation taken out to make file comparisons easier
	Set tIndent=pIOStream.LineTerminator, tElem=0
	// TPS: Closing indent added to use when terminating elements (aim to stop line breaks in element values)
	Set tIndent=""
	set tClosingIndent=""
	

	For i=1:1:iCnt {
		set tTag1=tName_"."_i
		continue:""=pSegObj.GetValueAt(i)
		
		Do pIOStream.Write(tIndent_"<"_tNS_tTag1_">",,.pStatus)  Quit:$$$ISERR(pStatus)
		
		Set rCnt=+(pSegObj.GetValueAt(i_"(*)"))
		if tTag1="MSH.1" s rCnt=1
		if tTag1="MSH.2" s rCnt=1
		//Set:rCnt>1 tIndent=tIndent_$C(9)
		
		// this deals with single or repeating values without subtypes
		for r=1:1:rCnt {
			Set rAlias=i_"("_r_")"
			
			//ITB+
			set tTag2=$piece($lg($lg($$$vaSchemaGbl(iCat,"SS",tName),i)),":",2)
			if tTag2'="",tTag2'["@",..IsDTSimple(iCat,tTag2) set tTag2=""
			//ITB-
			
			continue:tTag2'=""
			Continue:""=pSegObj.GetValueAt(rAlias)
			
			do ..WriteSegmentField(pIOStream, pSegObj, rAlias, .pStatus) Quit:$$$ISERR(pStatus)
		}
		// this loop deals with datatypes
		For r=1:1:rCnt {
			Set rAlias=i_"("_r_")"
			
			//ITB+
			set tTag2=$piece($lg($lg($$$vaSchemaGbl(iCat,"SS",tName),i)),":",2)
			if tTag2'="",tTag2'["@",..IsDTSimple(iCat,tTag2) set tTag2=""
			//ITB-
			
			//ITB+
			// Segments with datastructure like "@i": will take datastructure definition from "i" field in segment
			if tTag2["@" {
				set tField = $piece(tTag2,"@",2)
				set tDS = ..UnescapeXML(pSegObj.GetValueAt(tField),pSegObj.Separators)
				set tTag2 = $select($length(tDS):tDS, 1:"")
				
				// if no datastructure (only one node) or it does not exist, write field value "as is".
				if ((tTag2="")||(..IsDTSimple(iCat,tTag2))) {
					do ..WriteSegmentField(pIOStream, pSegObj, rAlias, .pStatus) Quit:$$$ISERR(pStatus)
					continue
				}
			}
			//ITB-
			
			continue:tTag2=""
			Continue:""=pSegObj.GetValueAt(rAlias)
			set tRepeating=$lg($lg($$$vaSchemaGbl(iCat,"SS",tName),i),2)

			Set cCnt=pSegObj.GetValueAt(i_"("_r_").*")
			if cCnt>1 {
				//s tIndent=tIndent_$C(9)
			}
	
			For c=1:1:cCnt {
				Set cAlias=rAlias_"."_c
				//ITB+
				set tTag3=$Select($D($$$vaSchemaGbl(iCat,"DT",$piece(tTag2,"."))):$piece($lg($lg($$$vaSchemaGbl(iCat,"DT",$piece(tTag2,".")),c)),":",2),1:$piece($lg($$$vaSchemaGbl(iCat,"DS",$piece(tTag2,".")),c),":",2))
				if tTag3'="",..IsDTSimple(iCat,tTag3) set tTag3=""
				//ITB-
				Continue:""=pSegObj.GetValueAt(cAlias,pSeparators)
				If (tTag3'="") {
						Set sCnt=pSegObj.GetValueAt(cAlias_".*",pSeparators)
						//Set:sCnt>1 tIndent=tIndent_$C(9)
						Do pIOStream.Write(tIndent_"<"_tNS_tTag2_"."_c_">",,.pStatus)  Quit:$$$ISERR(pStatus)

						// last loop is many items or subcomponents
						//ITB+
						set tTag4=$Select($D($$$vaSchemaGbl(iCat,"DT",$piece(tTag3,"."))):$piece($lg($lg($$$vaSchemaGbl(iCat,"DT",$piece(tTag3,".")))),":",2),1:$piece($lg($$$vaSchemaGbl(iCat,"DS",$piece(tTag3,".")),1),":",2))	
						if tTag4'="",..IsDTSimple(iCat,tTag4) set tTag4=""
						//ITB-
						
						if (tTag4'="") {
							set tTag3=$piece(tTag3,".")_"."_1
							
							Do pIOStream.Write(tIndent_"<"_tNS_tTag3_">",,.pStatus)  Quit:$$$ISERR(pStatus)
							
							for sub=1:1:sCnt {
								set tTag4=$piece(tTag4,".")_"."_sub
								Set sAlias=cAlias_"."_sub
								Do pIOStream.Write(tIndent_"<"_tNS_tTag4_">",,.pStatus)  Quit:$$$ISERR(pStatus)							
								do ..WriteSegmentField(pIOStream, pSegObj, sAlias, .pStatus) Quit:$$$ISERR(pStatus)
								Do pIOStream.Write(tClosingIndent_"</"_tNS_tTag4_">",,.pStatus)  Quit:$$$ISERR(pStatus)									
							}
							Do pIOStream.Write(tClosingIndent_"</"_tNS_tTag3_">",,.pStatus)  Quit:$$$ISERR(pStatus)
							Do pIOStream.Write(tClosingIndent_"</"_tNS_tTag2_"."_c_">",,.pStatus)  Quit:$$$ISERR(pStatus)
						}
						else {	
								
						For s=1:1:sCnt {
							Set sAlias=cAlias_"."_s
							Set tVal=pSegObj.GetValueAt(sAlias,pSeparators)
							Continue:""=tVal
							
							set tTag3=$piece(tTag3,".")_"."_s
							Do pIOStream.Write(tIndent_"<"_tNS_tTag3_">",,.pStatus)  Quit:$$$ISERR(pStatus)
							do ..WriteSegmentField(pIOStream, pSegObj, sAlias, .pStatus) Quit:$$$ISERR(pStatus)
							Do pIOStream.Write(tClosingIndent_"</"_tNS_tTag3_">",,.pStatus)  Quit:$$$ISERR(pStatus)
							
						} Quit:$$$ISERR(pStatus)
						Do pIOStream.Write(tClosingIndent_"</"_tNS_tTag2_"."_c_">",,.pStatus)  Quit:$$$ISERR(pStatus)
						}
				}
				else {
						set tTag3=$piece(tTag2,".")_"."_c
						Do pIOStream.Write(tIndent_"<"_tNS_tTag3_">",,.pStatus)  Quit:$$$ISERR(pStatus)
						do ..WriteSegmentField(pIOStream, pSegObj, cAlias, .pStatus) Quit:$$$ISERR(pStatus)
						Do pIOStream.Write(tClosingIndent_"</"_tNS_tTag3_">",,.pStatus)  Quit:$$$ISERR(pStatus)
				}			
	
			} Quit:$$$ISERR(pStatus)
			if ((tRepeating="")||("+*"'[tRepeating)) {
					set tTag2=""
			}
			If ((r<rCnt)) {
				 Do pIOStream.Write(tClosingIndent_"</"_tNS_tTag1_">",,.pStatus)  Quit:$$$ISERR(pStatus)
			 	 Do pIOStream.Write(tIndent_"<"_tNS_tTag1_">",,.pStatus)  Quit:$$$ISERR(pStatus)
			}
		} Quit:$$$ISERR(pStatus)
		//Set:rCnt>1 tIndent=$E(tIndent,1,*-1)
		Do pIOStream.Write($S(tElem:"",1:tClosingIndent)_"</"_tNS_tTag1_">",,.pStatus)  Set tElem=0  Quit:$$$ISERR(pStatus)
	} Quit:$$$ISERR(pStatus) 1
	
	// Do pIOStream.WriteLine(pIOStream.LineTerminator_"</"_tNS_tName_">",,.pStatus)
	Do pIOStream.Write("</"_tNS_tName_">",,.pStatus)
	//ITB+
	Do ..IsGroupEnd(pSegObj, pIOStream, pSegNum, pSegPath, pParentDoc)
	//ITB-
	Quit 1
}

/// Return 1 if we imported the whole document or got an error. Returning 0 means the caller will do its standard parse.
/// Must pass Schema value in the pConfigItem array.  For example:  set pConfigItem="2.4"
/// Change Log:
/// Base Release: Rajiv Bhatia
ClassMethod ImportDocument(Output pDocObj As EnsLib.EDI.Document, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, ByRef pConfigItem As %String) As %Boolean
{
	set pConfigItem("Schema") = $piece(pConfigItem,":",1)
	
	if '$data(pConfigItem("Schema")) quit $$$ERROR($$$GeneralError,"No schema to associate with document")
	Set pDocObj=$$$NULLOREF, tHandler=..%New()
	Merge tHandler.%Context=pConfigItem
	Set pStatus=##class(%XML.SAX.Parser).ParseStream(##class(%IO.LibraryStream).%New(pIOStream),tHandler)  Quit:$$$ISERR(pStatus) 1
	Quit:$$$ISERR(pStatus) 1
	Quit:'$IsObject(tHandler.%DocObj)||'tHandler.%DocObj.%Extends("EnsLib.HL7.Message") $$$ERROR($$$EnsErrGeneral,"No SimpleHL7v2 object found in stream "_pIOStream.Name)
	Set pDocObj=tHandler.%DocObj
	
	// default DocType to MSH:12 _":"_ MSH:9.3.  Must add more code if these values are not found. 
	do pDocObj.PokeDocType(pDocObj.GetValueAt("1:12")_":"_pDocObj.GetValueAt("1:9.3"))
		
	// Try to set it to schema as sent in pConfigItem
	set tType=pDocObj.GetValueAt("1:9.1")_"_"_pDocObj.GetValueAt("1:9.2")
	set tSchema=pConfigItem("Schema")
		
	if (tType'="") {
		set tMessageStructure=##class(EnsLib.HL7.Schema).ResolveSchemaTypeToDocType(tSchema,tType)
	}
	if (tMessageStructure'="") {
		do pDocObj.PokeDocType(tMessageStructure)
	}

	Quit 1
}

/// Return 1 if we imported a segment or got an error. Returning 0 means the caller will do its standard parse.
/// Change Log:
/// Base Release: Rajiv Bhatia
ClassMethod ImportSegment(Output pSegObj As EnsLib.EDI.Segment, Output pStatus As %Status, pIOStream As %IO.I.CharacterStream, ByRef pSeparators As %String) As %Boolean
{
	Set pSegObj=$$$NULLOREF, tHandler=..%New()
	Merge tHandler.%Context=pSeparators
	Set pStatus=##class(%XML.SAX.Parser).ParseStream(##class(%IO.LibraryStream).%New(pIOStream),tHandler)  Quit:$$$ISERR(pStatus) 1
	Set pStatus=tHandler.Error
	Quit:$$$ISERR(pStatus) 1
	Quit:'$IsObject(tHandler.%DocObj)||'tHandler.%DocObj.%Extends("EnsLib.HL7.Segment") $$$ERROR($$$EnsErrGeneral,"No SimpleHL7v2 segment object found in stream "_pIOStream.Name)
	Set pSegObj=tHandler.%DocObj
	Quit 1
}

/* SAX parser properties and methods used by Import... */
Property %Context As %String [ MultiDimensional ];

Property %DocObj As EnsLib.EDI.Document;

Property %SegObj As EnsLib.EDI.Segment;

Property %SegFields As %Integer;

Property %FieldPath As %String;

Property %FieldPathDelayed As %String;

Property %LastLevel As %Integer;

Property %Content As %String;

Property %ContentStream As %Stream.GlobalCharacter;

Property %ContentStreamDelayed As %Stream.GlobalCharacter;

Property %InCData As %Integer [ InitialExpression = 0 ];

Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List)
{
	//For i=0:1:$LL(attrs)\5-1 Set attribs($LI(attrs,i*5+2))=$LI(attrs,i*5+5)
	if localname[":" set localname=$piece(localname,":",2)
	
	set tSchema=$get(..%Context("Schema"))
	If $data($$$vaSchemaGbl(tSchema,"MT",localname)) {
		Do:$IsObject(..%DocObj) ..fault("More than one message found in stream")
		Set ..%DocObj=##class(EnsLib.HL7.Message).%New()
	} ElseIf $data($$$vaSchemaGbl(tSchema,"SS",localname)) {
		if (localname="MSH") {
			set ..%SegObj=..%DocObj.getSegmentByIndex(1)
		}
		else {
			Set ..%SegObj=##class(EnsLib.HL7.Segment).%New()
			If $IsObject(..%DocObj) {
			Set ..%SegObj.Separators = ..%DocObj.Separators
			Set tSC=..%DocObj.setSegmentByIndex(..%SegObj,(..%DocObj.SegCount)+1,0)
			Do ..%SegObj.SetValueAt(localname,0)
			}
		}
		
		Set ..%SegFields=0
		Set ..%Content=""
		set ..%FieldPath=""
	} ElseIf ($data($$$vaSchemaGbl(tSchema,"SS",$piece(localname,".")))&&(+$piece(localname,".",2)>0)) {
		set ..%SegFields=$piece(localname,".",2)
		// schema defines more than one item per field
		if ("+*"[$lg($lg($$$vaSchemaGbl(tSchema,"SS",..%SegObj.Name),..%SegFields),2)) {
			if (..%SegFields > ..%LastLevel)
				{
					set ..%FieldPath=""
				}
			if ..%FieldPath["("  {
				Set ..%FieldPath=..%SegFields_"("_($piece($piece(..%FieldPath,"(",2),")")+1)_")"
			}
			else  {
				set ..%FieldPath=..%SegFields_"(1)"
			}
		}
		else {
			Set ..%FieldPath=..%SegFields
		}
		Set ..%Content=""
	} Elseif ($data($$$vaSchemaGbl(tSchema,"DT",$piece(localname,"."))) || $data($$$vaSchemaGbl(tSchema,"DS",$piece(localname,"."))))  {
		/*if ($lg(^EnsHL7.Schema(tSchema,"DS",$piece(localname,".")),$piece(localname,".",2))="")&&($piece(localname,".",2)>1) {
			set tLength=1
			if $length(..%FieldPath,".")>1 set tLength=$length(..%FieldPath,".")-1
			Set ..%FieldPath=$piece(..%FieldPath,".",1,tLength)_"."_$piece(localname,".",2)
			Set ..%Content=""
		}
		else {*/
			Set ..%FieldPath=..%FieldPath_"."_$piece(localname,".",2)
			set ..%Content=""
		/*}*/
	}
	Quit
}

Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String)
{
	
	if localname[":" set localname=$piece(localname,":",2)
	
	set tSchema=$get(..%Context("Schema"))
	
	If $data($$$vaSchemaGbl(tSchema,"MT",$piece(localname,"."))) {
		Quit
	} ElseIf $data($$$vaSchemaGbl(tSchema,"SS",localname)) {
		///ITB+
		if ..%ContentStreamDelayed.Size>0 {
			// write delayed stream field in the segment. segment will remain immutable after this.
			do ..%ContentStreamDelayed.Rewind()
			set tSC=..%SegObj.StoreFieldStreamRaw(..%ContentStreamDelayed, ..%FieldPathDelayed)
			Do:$$$ISERR(tSC) ..faultStatus(tSC)
		}
		Set tSC=..%SegObj.SaveData()
		///ITB-
		Do:$$$ISERR(tSC) ..faultStatus(tSC)
		Set ..%SegFields=""
		Set ..%SegObj=$$$NULLOREF
		Set ..%LastLevel=0
		Quit
	}
			if (..%SegObj.GetValueAt(..%FieldPath)="") {
			//ITB+
			set tSC=..WriteContentToSegment()
			//ITB-
			Do:$$$ISERR(tSC) ..faultStatus(tSC)
			}

	
	If ($data($$$vaSchemaGbl(tSchema,"SS",localname))) {
		set ..%FieldPath=""
	}
	If ($data($$$vaSchemaGbl(tSchema,"SS",$piece(localname,".")))&&(+$piece(localname,".",2)>0)) {
		set ..%LastLevel=+$piece(localname,".",2)
	}
	if ($data($$$vaSchemaGbl(tSchema,"DT",$piece(localname,"."))) || $data($$$vaSchemaGbl(tSchema,"DS",$piece(localname,"."))))  {
		/*if $lg(^EnsHL7.Schema(tSchema,"DS",$piece(localname,".")),$piece(localname,".",2))="" {*/
			set tLength=1
			if $length(..%FieldPath,".")>1 set tLength=$length(..%FieldPath,".")-1
			Set ..%FieldPath=$piece(..%FieldPath,".",1,tLength)
		/*}*/
		
	}
}

Method characters(chars As %Library.String, length As %Library.Integer)
{
	Set data=""
	If ..%InCData=1 {
		Set data=$E(chars,1,length)
	} Else {
		Set data=$ZCVT($E(chars,1,length),"I","XML")
	}
	
	#if $$$ITB32K
		if (..%ContentStream.Size>0) {
			do ..%ContentStream.Write(data)
		} 
		elseif ($length(..%Content)+length) < $$$MaxStringLen {
			set ..%Content=..%Content_data
		} 
		else {
			do ..%ContentStream.Write(..%Content)
			do ..%ContentStream.Write(data)
		}
	#else
		set ..%Content=..%Content_data
	#endif
}

Method startCDATA()
{
	Set ..%InCData=1
	Set ..%Content="<![CDATA["
}

Method endCDATA()
{
	Set ..%InCData=0
	if (..%ContentStream.Size>0) {
		do ..%ContentStream.Write("]]>")
	}else{
		Set ..%Content=..%Content_"]]>"
	}
}

Method startEntity(name As %String)
{
	Quit
}

Method endEntity(name As %String)
{
	Quit
}

Method fault(text As %String)
{
	Set %objlasterror=$$$ERROR($$$EnsErrGeneral,text)
	ZTRAP "HL7v2"
}

Method faultStatus(status As %Status)
{
	Set %objlasterror=status
	ZTRAP "HL7v2"
}

/// ITB. xml to er7. Write SAX content to EnsLib.HL7.Segment
Method WriteContentToSegment()
{
	set tSC = $$$OK
	
	#if $$$ITB32K
		if ..%ContentStream.Size > 0 {
			set ..%FieldPathDelayed = ..%FieldPath
			do ..%ContentStreamDelayed.CopyFromAndSave(..%ContentStream)
			set ..%ContentStream = ##class(%Stream.GlobalCharacter).%New()
		} else {
			// Fix. Keep LineFeed characters
			//set tSC=..%SegObj.SetValueAt(..EscapeXML($zstrip(..%Content,"*C"),..%SegObj.Separators),..%FieldPath)
			set tSC=..%SegObj.SetValueAt(..EscapeXML(..%Content,..%SegObj.Separators),..%FieldPath)
		}
		
	#else
		// Fix. Keep LineFeed characters
		//set tSC=..%SegObj.SetValueAt(..EscapeXML($zstrip(..%Content,"*C"),..%SegObj.Separators),..%FieldPath)
		set tSC=..%SegObj.SetValueAt(..EscapeXML(..%Content,..%SegObj.Separators),..%FieldPath)
	#endif
	
	set ..%Content=""
	quit tSC
}

/// ITB. to xml. Get Tag.
ClassMethod GetTag(pSegPath As %String, pOnlyGroups As %Boolean = 0, pFullName As %Boolean = 0) As %String
{
	set (ret,tmp) = ""
	for i=1:1:$l(pSegPath,".") {
		if pFullName {
			set tmp=$p(pSegPath,".",i)
		} else {
			set tmp=$p($p(pSegPath,".",i),"(",1)
		}
		
		if pOnlyGroups {
			if ((tmp["grp")||(tmp["union")) set ret=ret_"."_tmp
		} else {
			set ret=ret_"."_tmp
		}
	}
	set ret=$extract(ret,2,*)
	quit ret
}

/// ITB. to xml. Is Group Start.
ClassMethod IsGroupStart(pSegObj As EnsLib.EDI.Segment, pIOStream As %IO.I.CharacterStream, pSegNum As %String, pSegPath As %String, pParentDoc As EnsLib.EDI.Document)
{
	if ((pSegPath["grp")||(pSegPath["union")) {
		set tPrevSegPath = pParentDoc.GetSegmentPath(pSegNum-1)	
		set tGroupPath = ..GetTag(pSegPath, 1, 1)
		set tPrevGroupPath = ..GetTag(tPrevSegPath, 1, 1)
		set tGroupTag = ..GetTag(pSegPath, 1)
				
		#if $$$ITBDebug
			set zind=$i(^zitb(0))
			set ^zitb(0,zind,1,"SegPath")=pSegPath
			set ^zitb(0,zind,2,"tPrevSegPath")=tPrevSegPath
			set ^zitb(0,zind,3,"tGroupPath")=tGroupPath
			set ^zitb(0,zind,4,"tPrevGroupPath")=tPrevGroupPath
			set ^zitb(0,zind,5,"tGroupTag")=tGroupTag
			set ^zitb(0,zind,"z")="----------"
		#endif
		
		if tPrevGroupPath [ tGroupPath quit
		
		for i=1:1:$l(tGroupPath,".") {
			set iPath = $p(tGroupPath,".",1,i)
			if tPrevGroupPath [ iPath continue
			
			set iTag = $p(tGroupTag,".",1,i)
			
			// substitute standard XML group names with HL7 XML Schema group names
			set lkuId = "hl7_"_pParentDoc.DocTypeCategory_"||"_pParentDoc.DocTypeName_"."_iTag
			set lkuValue = 0
			
			&sql(select DataValue into :lkuValue from Ens_Util.LookupTable where id=:lkuId)
			set:SQLCODE'=0 dataValue=0
			if SQLCODE=100 continue
			
			// only add additional groups where a lookup value has been found
			if lkuValue'=""	{
				#if $$$ITBDebug 
					set ^zitb(0,zind,6,i,iTag)=lkuValue
				#endif
				for j=1:1:$l(lkuValue,",") {
					do pIOStream.Write("<"_$p(lkuValue,",",j)_">")
				}
			}
		} // for
	}
}

/// ITB. to xml. Is Group End.
ClassMethod IsGroupEnd(pSegObj As EnsLib.EDI.Segment, pIOStream As %IO.I.CharacterStream, pSegNum As %String, pSegPath As %String, pParentDoc As EnsLib.EDI.Document)
{
	if ((pSegPath["grp")||(pSegPath["union")) {
		set tNextSegPath = pParentDoc.GetSegmentPath(pSegNum+1)	
		set tGroupPath = ..GetTag(pSegPath, 1, 1)
		set tNextGroupPath = ..GetTag(tNextSegPath, 1, 1)
		set tGroupTag = ..GetTag(pSegPath, 1)
		
		#if $$$ITBDebug
			set zind=$i(^zitb(1))
			set ^zitb(1,zind,1,"SegPath")=pSegPath
			set ^zitb(1,zind,2,"tNextSegPath")=tNextSegPath
			set ^zitb(1,zind,3,"tGroupPath")=tGroupPath
			set ^zitb(1,zind,4,"tNextGroupPath")=tNextGroupPath
			set ^zitb(1,zind,5,"tGroupTag")=tGroupTag
			set ^zitb(1,zind,"z")="----------"
		#endif
		
		if tNextGroupPath [ tGroupPath quit
		
		for i=$l(tGroupPath,"."):-1:1
		{			
			set iPath = $p(tGroupPath,".",1,i)
			if tNextGroupPath [ iPath continue
			
			set iTag = $p(tGroupTag,".",1,i)
			
			
			// substitute standard XML group names with HL7 XML Schema group names
			set lkuId = "hl7_"_pParentDoc.DocTypeCategory_"||"_pParentDoc.DocTypeName_"."_iTag
			set lkuValue = 0
			
			&sql(select DataValue into :lkuValue from Ens_Util.LookupTable where id=:lkuId)
			set:SQLCODE'=0 dataValue=0
			if SQLCODE=100 continue
			
			// only add additional groups where a lookup value has been found
			if lkuValue'=""	{
				#if $$$ITBDebug 
					set ^zitb(1,zind,6,i,iTag)=lkuValue
				#endif
				for j=$l(lkuValue,","):-1:1 {
					do pIOStream.Write("</"_$p(lkuValue,",",j)_">")
				}
			}
		} // for
	}
}

/// ITB. to xml. Return if DataType is simple (only one substructure) or not
ClassMethod IsDTSimple(pCat As %String, pDT As %String = "") As %Boolean
{
	// if there is no structure (e.g. "ST","NM"), consider it simple.
	if '$data($$$vaSchemaGbl(pCat,"DT",pDT)) {
		quit 1
	}
	
	// check if there is more than one node in data structure (e.g. "XCN")
	set tNode="", tNumNodes=0
	for {
		set tNode=$order($$$vaSchemaGbl(pCat,"DT",pDT,"names",tNode))
		quit:tNode=""
		set tNumNodes=tNumNodes+1
		quit:tNumNodes>1
	}
	quit (tNumNodes=1)
}

/// ITB. to xml. Custom Escape method for HL7-XML. Based on EnsLib.HL7.Segment.
ClassMethod EscapeXML(pData, pSeparators, pEscapeChar) As %String
{
	Set tEscape=$g(pEscapeChar,$$$ESCSEP(pSeparators))
	Set replace($C(10))=tEscape_"X0A"_tEscape
	Set replace($C(13))=tEscape_"X0D"_tEscape
	Set replace($$$FSSEP(pSeparators))=tEscape_"F"_tEscape
	Set replace($$$RSSEP(pSeparators))=tEscape_"R"_tEscape
	Set replace($$$CSSEP(pSeparators))=tEscape_"S"_tEscape
	Set replace($$$SSSEP(pSeparators))=tEscape_"T"_tEscape
	//Set replace($$$ESCSEP(pSeparators))=tEscape_"E"_tEscape
	Quit $$replaceArray^EnsUtil(pData,.replace)
}

/// ITB. to xml. Custom Unescape method for HL7-XML. Based on EnsLib.HL7.Segment.
ClassMethod UnescapeXML(pData, pSeparators, pEscapeChar)
{
	Set tEscape=$g(pEscapeChar,$$$ESCSEP(pSeparators))
	Set replace(tEscape_"X0A"_tEscape)=$c(10)
	Set replace(tEscape_"X0D"_tEscape)=$c(13)
	//Set replace(tEscape_".br"_tEscape)=$C(13)
	Set replace(tEscape_"F"_tEscape)=$$$FSSEP(pSeparators)
	Set replace(tEscape_"R"_tEscape)=$$$RSSEP(pSeparators)
	Set replace(tEscape_"S"_tEscape)=$$$CSSEP(pSeparators)
	Set replace(tEscape_"T"_tEscape)=$$$SSSEP(pSeparators)
	Set replace(tEscape_"E"_tEscape)=$$$ESCSEP(pSeparators)
	Set replace(tEscape_"X00"_tEscape)=""     // empty fields in XML can be created using "\X00\"
	quit $$replaceArrayLeftToRight^EnsUtil(pData,.replace,5,.pLastPos)
}

/// ITB. to xml. Write a segment field into a given IOStream
ClassMethod WriteSegmentField(pIOStream As %IO.I.CharacterStream, pSegObj As EnsLib.HL7.Segment, pPropertyPath As %String = "", Output pStatus)
{
	#if $$$ITB32K
		// use regular GetValueAt() if segment size < 32K
		if pSegObj.FullSize < $$$CriticalSegmentLen {
			if $find(pSegObj.GetValueAt(pPropertyPath),"<![CDATA[") {
				do pIOStream.Write(..UnescapeXML(pSegObj.GetValueAt(pPropertyPath),pSegObj.Separators),,.pStatus)
			}else{
				do pIOStream.Write($zcvt(..UnescapeXML(pSegObj.GetValueAt(pPropertyPath),pSegObj.Separators),"O","XML"),,.pStatus)
			}
		}
		else {
			#if $$$VersionAbove2024 
				;# GetFieldStreamRaw throws MAXSTRING error when remainder too long! if version < 2024
				set pStatus = pSegObj.GetFieldStreamRaw(.tStream, pPropertyPath, .remainder)
			#else
				set pStatus = pSegObj.ReadRawDataStream(.tStream, pPropertyPath)
			#endif

			while 'tStream.AtEnd {
				do pIOStream.Write(..UnescapeXML(tStream.Read(),pSegObj.Separators),,.pStatus)
			}
		}
	#else
		if $find(pSegObj.GetValueAt(pPropertyPath),"<![CDATA[") {
			do pIOStream.Write(..UnescapeXML(pSegObj.GetValueAt(pPropertyPath),pSegObj.Separators),,.pStatus)
		}else{
			do pIOStream.Write($zcvt(..UnescapeXML(pSegObj.GetValueAt(pPropertyPath),pSegObj.Separators),"O","XML"),,.pStatus)
		}
	#endif
}

}
