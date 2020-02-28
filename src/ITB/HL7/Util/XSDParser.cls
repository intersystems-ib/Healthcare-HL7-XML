/// <p>Parse HL7 XML XSD structure files and generate Ensemble LookUp table to map group names<p>
/// <ul>
/// <li>Build ^||xsdparser with XSD structure</li>
/// <li>Process ^||xsdparser comparing with ^EnsHL7.Schema</li>
/// </ul>
Class ITB.HL7.Util.XSDParser Extends %XML.SAX.ContentHandler
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

/// Prefix used in Lookup table names
Parameter TABLEPREFIX = "hl7_";

/// HL7 category
Property Category As %String;

/// HL7 message structure
Property Structure As %String;

/// complexType level
Property ComplexTypeLevel As %Integer [ InitialExpression = 0 ];

/// sequence level
Property SequenceLevel As %Integer [ InitialExpression = 0 ];

/// Current complexType name
Property ComplexTypeName As %String;

/// Debug flag
Property Debug As %Integer [ InitialExpression = 0 ];

/// SAX. Start element
Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List)
{
 	do ..ParseAttr(attrs,.namedattrs)
	
	if localname="complexType" set ..ComplexTypeLevel=..ComplexTypeLevel+1
	if localname="sequence" set ..SequenceLevel=..SequenceLevel+1
	
	if ((localname="complexType") || (localname="element")) {
		set name = $g(namedattrs("name"))
		set ref = $g(namedattrs("ref"))
		set type = $g(namedattrs("type"))
		
		if localname="complexType",name'="" {
			set ..ComplexTypeName = name
			set ^||xsdparser(..ComplexTypeName,"localname")=localname
		}
		
		if ..ComplexTypeLevel=1,..SequenceLevel=1 {
			set ^||xsdparser(..ComplexTypeName,$i(^||xsdparser(..ComplexTypeName)))=ref
		}
		
		if ..ComplexTypeLevel=0,..SequenceLevel=0 {
			set ^||xsdparser(name,"type")=type
			set ^||xsdparser(name,"localname")=localname
		}
		
		write:..Debug "[ct=",..ComplexTypeLevel," seq=",..SequenceLevel," ctn=",..ComplexTypeName,"] ln=",localname, " n=",name," "," r=",ref,!
	}
	
	quit
}

/// SAX. End element
Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String)
{
 	if localname="complexType" set ..ComplexTypeLevel=..ComplexTypeLevel-1
	if localname="sequence" set ..SequenceLevel=..SequenceLevel-1
}

/// Parse attributes and return a named list easier to handle
Method ParseAttr(attrs As %List, ByRef namedattrs) As %Status [ Private ]
{
	k namedattrs
	for p=1:5:$ll(attrs) set namedattrs($lg(attrs,p+1))=$lg(attrs,p+4)
	quit $$$OK
}

/// Process ^||xsdparser data and build LookUp tables
Method ProcessContent(ind As %String) As %Status
{
	quit ..Process("",..Structure)
}

/// Process ^||xsdparser recursively
Method Process(pInd As %String, pNode As %String, pXMLGroup As %String = "", pEnsPath As %String = "", pIncremented As %String) As %Status [ Private ]
{
	set ret = $$$OK
	try {
		set increment = 0
		set localname=$g(^||xsdparser(pNode,"localname"))
		
		if ..Debug {
			write !,"==========================================",!
			write pInd," ",pNode," ",pEnsPath," ",pXMLGroup,!
		}
		
		// calculate next levels
		set nelements=+$g(^||xsdparser(pNode))
		set nextNodes = ""
		write:..Debug ">leafs=",!
		for i=1:1:nelements {
			set element = $g(^||xsdparser(pNode,i))
				
			if '$data(^||xsdparser(element)) {
				write:..Debug "  ",element,!
			} else {
				set nextNodes = nextNodes_$lb($lb(i,element))
			}
		}
		set increment = ( (localname="complexType") && (nelements>1) )
		
		// avoid circular references
		if $g(^||xsdparser(pNode,"processed")),$ll(nextNodes)>0 $$$ThrowStatus($$$ERROR($$$GeneralError,pNode_": circular reference!"))
		set ^||xsdparser(pNode,"processed") = 1
		
		// calculate next levels (type)
		set type = $g(^||xsdparser(pNode,"type"))
		if type'="",$data(^||xsdparser(type)) {
			set nextNodes = nextNodes_$lb($lb(1,type))
		}
		
		if ..Debug {
			write ">"
			zwrite nextNodes
		}
		
		// match Ensemble path / XML group name
		if localname="element" {
			set pXMLGroup=pNode
			write:..Debug ">xmlgroup="_pXMLGroup,!
			
			set enspath = ""
			if pInd'="" x ("(enspath) { set enspath=$g(^EnsHL7.Schema("""_..Category_""",""MS"","""_..Structure_""",""array"","_pInd_",""name"")) }", .enspath)
			
			write:..Debug ">enspath=",enspath,!
			
			if ((enspath["grp")||(enspath["union")) {
				set enspath=$p(enspath,"(")
				if pIncremented {
					set pEnsPath=pEnsPath_$s(pEnsPath="":enspath,1:"."_enspath)
				}
				write:..Debug ">key=",pEnsPath,!
				
				// map Ensemble -> XML group name
				set table=..#TABLEPREFIX_..Category, key=..Structure_"."_pEnsPath, value=pXMLGroup
				set lookup=##class(Ens.Util.LookupTable).%OpenId(table_"||"_key,,.tSC)
				if $$$ISERR(tSC) set lookup=##class(Ens.Util.LookupTable).%New()
				set lookup.TableName = table
				set lookup.KeyName = key
				set lookup.DataValue = $select($l(lookup.DataValue):lookup.DataValue_"," , 1:"")_value
				$$$THROWONERROR(tSC, lookup.%Save())
			}
		}
		
		// go into next levels
		for i=1:1:$listlength(nextNodes) {
			set tmpInd = $lg($lg(nextNodes,i),1)
			set nextInd=pInd
			set nextNode = $lg($lg(nextNodes,i),2)
			
			if nextInd="",increment {
				set nextInd=tmpInd
			}
			elseif nextInd'="",increment {
				set nextInd=nextInd_","_tmpInd 
			}
			
			$$$THROWONERROR(tSC, ..Process(nextInd, nextNode, pXMLGroup, pEnsPath, increment))
		}
	} catch ex {
		set ret = ex.AsStatus()
		write $system.Status.GetOneErrorText(ret),!
	}
	quit ret
}

/// Parse a given HL7 message structure XSD file and build LookUp tables to map Ensemble and HL7 XML group names
ClassMethod LoadFile(pCategory = "2.5", pPath = "c:\hl7\hl7_xml-2.5\", pFile = "OMG_O19.xsd", pDebug = 0) As %Status
{
	set ret = $$$OK
	try {
		set structure = $piece(pFile,".")
		
		set handler=..%New()
		set handler.Structure = structure
		set handler.Category = pCategory
		set handler.Debug = pDebug
		
		kill ^||xsdparser, ^xsdparser
		$$$THROWONERROR(tSC, ##class(%XML.SAX.Parser).ParseFile(pPath_pFile,handler))
		merge ^xsdparser = ^||xsdparser
		$$$THROWONERROR(tSC, handler.ProcessContent())
	} catch ex {
		set ret = ex.AsStatus()
		write $system.Status.GetOneErrorText(ret),!
	}
    quit ret
}

/// Parse all "*_*.xsd" HL7 message XSD files within a given directory 
ClassMethod LoadDirectory(pCategory = "2.5", pPath = "c:\hl7\hl7_xml-2.5\", pDebug = 0) As %Status
{
	write "Clearing Lookup Table: "_..#TABLEPREFIX_pCategory,!
	do ##class(Ens.Util.LookupTable).%ClearTable(..#TABLEPREFIX_pCategory)
	
	write "Processing files...",!
	set tRS = ##class(%ResultSet).%New("%File:FileSet")
	set sc = tRS.Execute(pPath,"*_*.xsd")
 	while (tRS.Next()) {        
 		set filename = tRS.Data("Name")
        do ..LoadFile(pCategory, pPath, ##class(%File).GetFilename(filename), pDebug) 
 	}
 	write "Done.",!
 	
 	quit $$$OK
}

}
