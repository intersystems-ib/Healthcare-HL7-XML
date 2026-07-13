Include EnsHL7

Class ITB.EnsLib.HL7.SchemaXML Extends %XML.SAX.ContentHandler [ ClassType = "", ProcedureBlock ]
{

/// Flag to only check the category defined in the schema xml file
Property CatOnly As %Boolean;

/// slot for remembering categories encountered in schema xml file
Property lastFileCategory As %String;

/// slot for remembering forced category name
Property forceCategory As %String;

/// Error encountered inside xml import handler
Property Error As %Status [ InitialExpression = {$$$OK} ];

/// Filename for use in constructing xml handler error messages
Property Filename As %String;

/// Array for disambiguation of names
Property %propNames As %String [ MultiDimensional ];

ClassMethod Import(pFile As %String, Output pCategoryImported As %String, pForceCategory As %String) As %Status
{
	Set handler=..%New(), handler.forceCategory=$G(pForceCategory), pCategoryImported=""
	If '$IsObject(pFile) {
		Set handler.Filename=pFile
		Quit:'##class(%File).Exists(pFile) $$$ERROR($$$FileDoesNotExist,pFile)
		Set sc=##class(%XML.SAX.Parser).ParseFile(pFile,handler)  quit:$$$ISERR(sc) sc
	} Else {
		Set handler.Filename=$S(""'=pForceCategory:pForceCategory_".HL7", ""'=$G(pCategoryImported):pCategoryImported_".HL7", 1:pFile)
		Set sc=##class(%XML.SAX.Parser).ParseStream(pFile,handler)  quit:$$$ISERR(sc) sc
	}
	Set pCategoryImported=handler.lastFileCategory
	Quit handler.Error
}

ClassMethod GetImportCategory(pFilename As %String) As %String
{
	set handler=..%New()  Set handler.CatOnly=1
	set sc=##class(%XML.SAX.Parser).ParseFile(pFilename,handler)
	quit handler.lastFileCategory
}

ClassMethod Export(pCategory As %String, pFile As %String) As %Status
{
	Quit:'$D($$$vaSchemaGbl(pCategory)) $$$ERROR($$$ObjectScriptError,"HL7 Schema Category <"_pCategory_"> does not exist in namespace "_$ZNSpace)
	If '$IsObject(pFile) {
		set tFilename=pFile
		set pFile=##class(%FileCharacterStream).%New()
		//set tSC=pFile.LinkToFile(tFilename)  Quit:$$$ISERR(tSC) tSC
		set pFile.Filename = tFilename
		set pFile.TranslateTable="UTF8"
		Set tEncoding="UTF-8"
	} Else {
		Set tEncoding=$S(pFile.%Extends("%IO.IParts.CharacterIO"):pFile.CharEncoding,
						pFile.%Extends("%FileCharacterStream"):$$MapExtCharset^%NLS(pFile.TranslateTable),
						1:"")
	}
#define escape(%text) $replace($ZCVT(%text,"O","XML"),"&quot;","""")

	Do pFile.WriteLine("<?xml version=""1.0"""_$S(""=tEncoding:"",1:" encoding="""_tEncoding_"""")_"?>")
	Do pFile.WriteLine("")
	Do pFile.Write("<Category name="""_pCategory_"""")
	set desc=$g($$$vaSchemaDescGbl(pCategory))
	if desc'="" Do pFile.Write(" description="""_$$$escape(desc)_"""")
	set base=$g($$$vaSchemaGbl(pCategory,"base"))
	if base'="" Do pFile.Write(" base="""_base_"""")
	if +$g($$$vaSchemaDescGbl(pCategory,"std")) Do pFile.Write(" std=""1""")
	Do pFile.WriteLine(">")

	#; message group
	if $d($$$vaSchemaDescGbl(pCategory,"MG")) Do pFile.WriteLine("")
	set mg="" for { set mg=$o($$$vaSchemaDescGbl(pCategory,"MG",mg)) quit:mg=""
		set description=$g($$$vaSchemaDescGbl(pCategory,"MG",mg))
		Do pFile.Write("<MessageGroup name='"_mg_"'")
		Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine("/>")
	}
	#; message event
	if $d($$$vaSchemaDescGbl(pCategory,"ME")) Do pFile.WriteLine("")
	set me="" for { set me=$o($$$vaSchemaDescGbl(pCategory,"ME",me)) quit:me=""
		set description=$g($$$vaSchemaDescGbl(pCategory,"ME",me))
		Do pFile.Write("<MessageEvent name='"_me_"'")
		Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine("/>")
	}

	#; message types
	if $d($$$vaSchemaGbl(pCategory,"MT")) Do pFile.WriteLine("")
	set mt="" for { set mt=$o($$$vaSchemaGbl(pCategory,"MT",mt)) quit:mt=""
		set struct=$$$vaSchemaGbl(pCategory,"MT",mt)
		set rettype=$g($$$vaSchemaGbl(pCategory,"MT",mt,"rettype"))
		set altstruct=$g($$$vaSchemaGbl(pCategory,"MT",mt,"altstruct"))
		set description=$g($$$vaSchemaDescGbl(pCategory,"MT",mt))
		Do pFile.Write("<MessageType name='"_mt_"'")
		if struct'="" Do pFile.Write(" structure='"_..stripDefCategory(struct,pCategory,base)_"'")
		if altstruct'="" Do pFile.Write(" altstructure='"_..stripDefCategory(altstruct,pCategory,base)_"'")
		if rettype'="" Do pFile.Write(" returntype='"_..stripDefCategory(rettype,pCategory,base)_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine("/>")
	}
	#; message structure
	if $d($$$vaSchemaGbl(pCategory,"MS")) Do pFile.WriteLine("")
	set ms="" for { set ms=$o($$$vaSchemaGbl(pCategory,"MS",ms)) quit:ms=""
		set definition=$g($$$vaSchemaGbl(pCategory,"MS",ms))
		set description=$g($$$vaSchemaDescGbl(pCategory,"MS",ms))
		Do pFile.Write("<MessageStructure name='"_ms_"'")
		Do pFile.Write(" definition='"_$$$escape(..stripDefCategory(definition,pCategory,base))_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine("/>")
	}
	#; segment structure
	if $d($$$vaSchemaGbl(pCategory,"SS")) Do pFile.WriteLine("")
	set ss="" for { set ss=$o($$$vaSchemaGbl(pCategory,"SS",ss)) quit:ss=""
		set definition=$g($$$vaSchemaGbl(pCategory,"SS",ss))
		set description=$g($$$vaSchemaDescGbl(pCategory,"SS",ss))
		Do pFile.Write("<SegmentStructure name='"_ss_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine(">")
		for i=1:1:$LL(definition) { continue:'$LD(definition,i)
			Do pFile.Write("    <SegmentSubStructure piece='"_i_"'")
			Do pFile.Write(" description='"_$$$escape($g($$$vaSchemaDescGbl(pCategory,"SS",ss,i)))_"'")
			set altdesc=$g($$$vaSchemaDescGbl(pCategory,"SS",ss,i,"alt"))
			if altdesc'="" Do pFile.Write(" altdesc='"_$$$escape(altdesc)_"'")
			if $lg($li(definition,i),1)'="" Do pFile.Write(" datatype='"_..stripDefCategory($lg($li(definition,i),1),pCategory,base)_"'")
			if $lg($li(definition,i),2)'="" Do pFile.Write(" symbol='"_$$$escape($lg($li(definition,i),2))_"'")
			if $lg($li(definition,i),3)'="" Do pFile.Write(" repeatcount='"_$lg($li(definition,i),3)_"'")
			if $lg($li(definition,i),7)     Do pFile.Write(" min_length='"_$lg($li(definition,i),7)_"'")
			if $lg($li(definition,i),4)'="" Do pFile.Write(" max_length='"_$lg($li(definition,i),4)_"'")
			if $lg($li(definition,i),5)'="" Do pFile.Write(" required='"_$$$escape($lg($li(definition,i),5))_"'")
			if $lg($li(definition,i),6)'="" Do pFile.Write(" ifrepeating='"_$lg($li(definition,i),6)_"'")
			set codetable=$g($$$vaSchemaGbl(pCategory,"SS",ss,"tables",i))
			if codetable'="" Do pFile.Write(" codetable='"_..stripDefCategory(codetable,pCategory,base)_"'")
			Do pFile.WriteLine("/>")
		}
		Do pFile.WriteLine("</SegmentStructure>")
	}
	#; data structure
	if $d($$$vaSchemaGbl(pCategory,"DS")) Do pFile.WriteLine("")
	set ds="" for { set ds=$o($$$vaSchemaGbl(pCategory,"DS",ds))  quit:ds=""
		set definition=$g($$$vaSchemaGbl(pCategory,"DS",ds))
		set description=$g($$$vaSchemaDescGbl(pCategory,"DS",ds))
		Do pFile.Write("<DataType name='"_ds_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine(">")
		for i=1:1:$LL(definition) {
			Do pFile.Write("    <DataSubType piece='"_i_"'")
			Do pFile.Write(" description='"_$$$escape($g($$$vaSchemaDescGbl(pCategory,"DS",ds,i)))_"'")
			set altdesc=$g($$$vaSchemaDescGbl(pCategory,"DS",ds,i,"alt"))
			if altdesc'="" Do pFile.Write(" altdesc='"_$$$escape(altdesc)_"'")
			if $lg(definition,i)'="" Do pFile.Write(" datatype='"_..stripDefCategory($lg(definition,i),pCategory,base)_"'")
			set codetable=$g($$$vaSchemaGbl(pCategory,"DS",ds,"tables",i))
			if codetable'="" Do pFile.Write(" codetable='"_..stripDefCategory(codetable,pCategory,base)_"'")
			Do pFile.WriteLine("/>")
		}
		Do pFile.WriteLine("</DataType>")
	}
	#; data type
	if $d($$$vaSchemaGbl(pCategory,"DT")) Do pFile.WriteLine("")
	set ds="" for { set ds=$o($$$vaSchemaGbl(pCategory,"DT",ds))  quit:ds=""
		set definition=$g($$$vaSchemaGbl(pCategory,"DT",ds))
		set description=$g($$$vaSchemaDescGbl(pCategory,"DT",ds))
		Do pFile.Write("<DataType name='"_ds_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine(">")
		for i=1:1:$LL(definition) {
			Do pFile.Write("    <DataSubType piece='"_i_"'")
			Do pFile.Write(" description='"_$$$escape($g($$$vaSchemaDescGbl(pCategory,"DT",ds,i)))_"'")
			set altdesc=$g($$$vaSchemaDescGbl(pCategory,"DT",ds,i,"alt"))
			if altdesc'="" Do pFile.Write(" altdesc='"_$$$escape(altdesc)_"'")
			if $lg($li(definition,i),1)'="" Do pFile.Write(" datatype='"_..stripDefCategory($lg($li(definition,i),1),pCategory,base)_"'")
			set codetable=$g($$$vaSchemaGbl(pCategory,"DT",ds,"tables",i))
			if codetable'="" Do pFile.Write(" codetable='"_..stripDefCategory(codetable,pCategory,base)_"'")
			if $lg($li(definition,i),2)     Do pFile.Write(" min_length='"_$lg($li(definition,i),2)_"'")
			if $lg($li(definition,i),3)'="" Do pFile.Write(" max_length='"_$lg($li(definition,i),3)_"'")
			if $lg($li(definition,i),4)'="" Do pFile.Write(" required='"_$$$escape($lg($li(definition,i),4))_"'")
			Do pFile.WriteLine("/>")
		}
		Do pFile.WriteLine("</DataType>")
	}
	#; code table
	if $d($$$vaSchemaGbl(pCategory,"CT")) Do pFile.WriteLine("")
	set ct="" for { set ct=$o($$$vaSchemaGbl(pCategory,"CT",ct))  quit:ct=""
		set definition=$g($$$vaSchemaGbl(pCategory,"CT",ct))
		set description=$g($$$vaSchemaDescGbl(pCategory,"CT",ct))
		Do pFile.Write("<CodeTable name='"_ct_"'")
		Do pFile.Write(" tabletype='"_definition_"'")
		if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
		Do pFile.WriteLine(">")
		kill indexed
		set one="" for { set one=$o($$$vaSchemaGbl(pCategory,"CT",ct,one))  quit:one=""
			set indexed($$$vaSchemaGbl(pCategory,"CT",ct,one))=one
		}
		set i="" for { set i=$o(indexed(i))  quit:i=""
			set description=$g($$$vaSchemaDescGbl(pCategory,"CT",ct,indexed(i)))
			Do pFile.Write("   <Enumerate")
			Do pFile.Write(" position='"_i_"'")
			Do pFile.Write(" value='"_$$$escape(indexed(i))_"'")
			if description'="" Do pFile.Write(" description='"_$$$escape(description)_"'")
			Do pFile.WriteLine("/>")
		}
		Do pFile.WriteLine("</CodeTable>")
	}
	Do pFile.WriteLine("")
	Do pFile.WriteLine("</Category>")
	Do:pFile.%Extends("%Library.FileStreamAdaptor") pFile.SaveStream()
	Quit $$$OK
}

ClassMethod bothDSandCTexists() [ Internal ]
{
	set cat="" for {
		set cat=$o($$$vaSchemaGbl(cat)) quit:cat=""
		set ss="" for {
			set ss=$o($$$vaSchemaGbl(cat,"SS",ss)) quit:ss=""
			set definition=$$$vaSchemaGbl(cat,"SS",ss)
			for i=1:1:$LL(definition) {
				set ds=$lg($li(definition,i),1)
				set ct=$g($$$vaSchemaGbl(cat,"SS",ss,"tables",i))
				if ds'="",ct'="" write "SS:"_cat_":"_ss,?14," ->  ",ds,?30,ct,!
			}
		}
		set ele="", node = "DT" for {
			set ele=$o($$$vaSchemaGbl(cat,node,ele)) set:(ele=""&&(node'="DS")) ele = $o($$$vaSchemaGbl(cat,"DS",ele)), node = "DS" quit:ele=""
			set definition=$$$vaSchemaGbl(cat,node,ele)
			for i=1:1:$LL(definition) {
				set:(node="DT") ds=$lg($li(definition,i),1)
				set:(node="DS") ds=$li(definition,i)
				set ct=$g($$$vaSchemaGbl(cat,node,ele,"tables",i))
				if ds'="",ct'="" write "DT:"_cat_":"_ele,?14," ->  ",ds,?30,ct,!
			}
		}
	}
}

ClassMethod integCheckAll() [ Internal ]
{
	set cat="" for {
		set cat=$o($$$vaSchemaGbl(cat))  quit:cat=""
		do ..integCheck(cat)
	}
	quit
}

ClassMethod integCheck(cat As %String) [ Internal ]
{
	#; mismatched braces in message structure definition
	set ele="" for {set ele=$o($$$vaSchemaGbl(cat,"MS",ele)) quit:ele=""
		set def = $$$vaSchemaGbl(cat,"MS",ele)
		set (curlyOpen, curlyClose,squareOpen,squareClose,lessThan,greaterThan) = 0
		for i=1:1:$length(def) {
			set char = $E(def,i)
			set:char="{" curlyOpen = curlyOpen + 1
			set:char="}" curlyClose = curlyClose + 1
			set:char="[" squareOpen = squareOpen + 1
			set:char="]" squareClose = squareClose + 1
			set:char="<" lessThan = lessThan + 1
			set:char=">" greaterThan = greaterThan + 1 
		}
		if ((curlyOpen'=curlyClose) || (squareOpen'=squareClose) || (lessThan'=greaterThan)) {
			write "Mismatched braces in message structure: MS:"_cat_":"_ele,!
		}
	}
	#; property name not alpha-numeric
	for type="SS","DT","DS" {
		set ele="" for { set ele=$o($$$vaSchemaGbl(cat,type,ele)) quit:ele=""
			set name="" for { set name=$o($$$vaSchemaGbl(cat,type,ele,"names",name)) quit:name=""
				if name'?1A1.AN {
					write "property name not alpha-numeric: "_type_":"_cat_":"_ele_":"_name,!
				}
			}
		}
	}
	#; empty description
	#; description contains wide characters
	set q=$Name($$$vaSchemaDescGbl)
	for { set q=$q(@q) quit:q=""
		if $qs(q,1)'=cat continue
		set desc = @q
		if desc="" {
			write "empty description: "_q,!
		}
		if $ziswide(desc) {
			write "description contains wide characters: "_cat_":"_$qs(q,2)_":"_$qs(q,3)_" = "_desc,!
		}
	}
	#; description that lacks definition
	for type="MT","MS","SS","DT","DS","CT" {
		set ele="" for { set ele=$o($$$vaSchemaDescGbl(cat,type,ele)) quit:ele=""
			if $d($$$vaSchemaGbl(cat,type,ele))=0 {
				write "description lacks definition: "_type_":"_cat_":"_ele,!
			}
			
		}
	}
	#; message structure, return type, alternate structure undefined, empty rettype or altstruct
	set mt="" for { set mt=$o($$$vaSchemaGbl(cat,"MT",mt)) quit:mt=""
		set ms=$$$vaSchemaGbl(cat,"MT",mt)
		if ms="" {
			write "message structure definition missing: MT:",cat,":",mt,!
		} else {
			set category=$p(ms,":"),secondary=$p(ms,":",2)
			if $d($$$vaSchemaGbl(category,"MS",secondary))=0 {
				write "message structure not defined: MT:",cat,":",mt," -> ",ms,!
			}
		}
		if $d($$$vaSchemaGbl(cat,"MT",mt,"rettype"),rettype) {
			if ($Case(rettype,"":1,"?":1,:0)) {
				write "empty rettype: "_cat_":"_mt,!
			} elseif ('$D($$$vaSchemaGbl($p(rettype,":"),"MT",$p(rettype,":",2))) && (("ACK_"'=$E($p(rettype,":",2),1,4)) || '$D($$$vaSchemaGbl($p(rettype,":"),"MT","ACK")))){
				Write "return message type not defined: MT:"_cat_":"_mt_" -> "_rettype,!
			}
		}
		if $D($$$vaSchemaGbl(cat,"MT",mt,"altstruct"),altstruct) {
			if ($Case(altstruct,"":1,"?":1,:0)) {
				write "empty altstruct: "_cat_":"_mt,!
			} ElseIf '$D($$$vaSchemaGbl($P(altstruct,":"),"MS",$P(altstruct,":",2))) {
				Write "alternate message structure not defined: MT:"_cat_":"_mt_" -> "_altstruct,!
			}
		}
	}
	#; message structure definition contains strange characters
	#; segment structure undefined
	set ms="" for { set ms=$o($$$vaSchemaGbl(cat,"MS",ms)) quit:ms=""
		set definition=$$$vaSchemaGbl(cat,"MS",ms)
		set definition2=$tr(definition,"[]{}~:.<>|?")
		if definition2'?.AN {
			write "message structure definition contains strange characters: MS:"_cat_":"_ms,!,$$$vaSchemaGbl(cat,"MS",ms),!!
		}
		for i=1:1:$L(definition,"~") { set one=$p(definition,"~",i)  continue:""=one
			if $L(one)=1,"[]{}~:.<>|?"[one continue
			set category=$p(one,":"),secondary=$p(one,":",2)
			if category'="",secondary'="",$d($$$vaSchemaGbl(category,"SS",secondary)) continue
			if ((secondary="Zxx") || (secondary="Hxx") || (secondary="Any")) continue
			write "segment structure not defined: MS:",cat,":",ms," -> ",one,!
		}
	}
	#; data structure and code table undefined in segment structure
	set ss="" for { set ss=$o($$$vaSchemaGbl(cat,"SS",ss)) quit:ss=""
		set definition=$$$vaSchemaGbl(cat,"SS",ss)
		for i=1:1:$LL(definition) {
			set one=$lg($lg(definition,i),1) if one="" continue
			set category=$p(one,":"),secondary=$p(one,":",2)
			if category'="",secondary'="",$d($$$vaSchemaGbl(category,"DT",secondary)) continue
			if category'="",secondary'="",$d($$$vaSchemaGbl(category,"DS",secondary)) continue
			write "data type not defined: SS:",cat,":",ss," -> ",one,!
		}
		set ct="" for { set ct=$o($$$vaSchemaGbl(cat,"SS",ss,"tables",ct)) quit:ct=""
			set one=$$$vaSchemaGbl(cat,"SS",ss,"tables",ct)
			set category=$p(one,":"),secondary=$p(one,":",2)
			if category'="",secondary'="",$d($$$vaSchemaGbl(category,"CT",secondary)) continue
			write "code table not defined: SS:",cat,":",ss," -> ",one,!
		}
	}
	#; data structure and code table undefined in data structure
	set ds="",node = "DT" for { set ds=$o($$$vaSchemaGbl(cat,node,ds)) set:(ds=""&&(node'="DS")) ds=$o($$$vaSchemaGbl(cat,"DS",ds)), node = "DS"  quit:ds=""
		set definition=$$$vaSchemaGbl(cat,node,ds)
		for i=1:1:$LL(definition) {
			set:(node = "DT") one=$lg($lg(definition,i),1) if one="" continue
			set:(node = "DS") one=$lg(definition,i) if one="" continue
			set category=$p(one,":"),secondary=$p(one,":",2)
			if category'="",secondary'="",$d($$$vaSchemaGbl(category,node,secondary)) continue
			write "data type not defined: DT:",cat,":",ds," -> ",one,!
		}
		set ct="" for { set ct=$o($$$vaSchemaGbl(cat,node,ds,"tables",ct)) quit:ct=""
			set one=$$$vaSchemaGbl(cat,node,ds,"tables",ct)
			set category=$p(one,":"),secondary=$p(one,":",2)
			if category'="",secondary'="",$d($$$vaSchemaGbl(category,"CT",secondary)) continue
			write "code table not defined: ",node,":",cat,":",ds," -> ",one,!
		}
	}
	#; data structure component's data structure is self
	set ds="",node = "DT"
	for {
		set ds=$o($$$vaSchemaGbl(cat,node,ds))
		set:(ds=""&&(node'="DS")) ds=$o($$$vaSchemaGbl(cat,"DS",ds)), node = "DS"
		quit:ds=""
		set definition=$$$vaSchemaGbl(cat,node,ds)
		for i=1:1:$LL(definition) {
			set:(node = "DT") one=$lg($lg(definition,i),1) if one="" continue
			set:(node = "DS") one=$lg(definition,i) if one="" continue
			set secondary=$p(one,":",2)
			if secondary=ds {
				write "data type uses self: DT:",cat,":",ds," component ",i,!
			}
		}
	}
	#; code tables have no enums defined
	set ct="" for { set ct=$o($$$vaSchemaGbl(cat,"CT",ct)) quit:ct=""
		if $d($$$vaSchemaGbl(cat,"CT",ct))=1 {
			write "code table has no values: CT:",cat,":",ct,!
		}
	}
	#; ordinal position(s) skipped in code table
	set ct="" for {set ct=$o($$$vaSchemaGbl(cat,"CT",ct)) quit:ct=""
		kill nums set enum="",largest=0 for { set enum=$o($$$vaSchemaGbl(cat,"CT",ct,enum)) quit:enum=""
			if $d(nums($$$vaSchemaGbl(cat,"CT",ct,enum))) {
				write "ordinal position ",$$$vaSchemaGbl(cat,"CT",ct,enum)," used multiple times: CT:",cat,":",ct,!
			}
			set nums($$$vaSchemaGbl(cat,"CT",ct,enum)) = 1
			if $$$vaSchemaGbl(cat,"CT",ct,enum) > largest { set largest = $$$vaSchemaGbl(cat,"CT",ct,enum) }
		}
		for i=1:1:largest {
			if '$d(nums(i)) {
				write "ordinal position ",i," skipped: CT:",cat,":",ct,!
			}
		}
	}
	#; ordinal position(s) skipped in data structure
	set ds="",node = "DT" for { set ds=$o($$$vaSchemaGbl(cat,node,ds)) set:(ds=""&&(node'="DS")) ds=$o($$$vaSchemaGbl(cat,"DS",ds)), node = "DS"  quit:ds=""
		kill nums set enum="",largest=0 for { set enum=$o($$$vaSchemaGbl(cat,node,ds,"names",enum)) quit:enum=""
			if $d(nums($$$vaSchemaGbl(cat,node,ds,"names",enum))) {
				write "ordinal position ",$$$vaSchemaGbl(cat,node,ds,"names",enum)," used multiple times: "_node_":",cat,":",ds,!
			}
			set nums($$$vaSchemaGbl(cat,node,ds,"names",enum)) = 1
			if $$$vaSchemaGbl(cat,node,ds,"names",enum) > largest { set largest = $$$vaSchemaGbl(cat,node,ds,"names",enum) }
		}
		for i=1:1:largest {
			if '$d(nums(i)) {
				write "ordinal position ",i," skipped: "_node_":",cat,":",ds,!
			}
		}
	}
	#; ordinal position(s) skipped in segment structure
	set ss="" for {set ss=$o($$$vaSchemaGbl(cat,"SS",ss)) quit:ss=""
		kill nums set enum="",largest=0 for { set enum=$o($$$vaSchemaGbl(cat,"SS",ss,"names",enum)) quit:enum=""
			if $d(nums($$$vaSchemaGbl(cat,"SS",ss,"names",enum))) {
				write "ordinal position ",$$$vaSchemaGbl(cat,"SS",ss,"names",enum)," used multiple times: SS:",cat,":",ss,!
			}
			set nums($$$vaSchemaGbl(cat,"SS",ss,"names",enum)) = 1
			if $$$vaSchemaGbl(cat,"SS",ss,"names",enum) > largest { set largest = $$$vaSchemaGbl(cat,"SS",ss,"names",enum) }
		}
		for i=1:1:largest {
			if '$d(nums(i)) {
				write "ordinal position ",i," skipped: SS:",cat,":",ss,!
			}
		}
	}
	quit
}

ClassMethod test(CATEGORY, cleanup = 1, loadStd = 1) [ Internal ]
{
	set CATEGORY=$g(CATEGORY,"2.3.1:")

	If cleanup {
		$$$KillRootNode(^EnsHL8.Schema)
		$$$KillRootNode(^EnsHL8.Description)
	}
	merge:cleanup||'$d(^EnsHL8.Schema(CATEGORY)) ^EnsHL8.Schema=$$$vaSchemaGbl
	merge:cleanup||'$d(^EnsHL8.Schema(CATEGORY)) ^EnsHL8.Description=$$$vaSchemaDescGbl

	set file="c:\temp\hl7schema"_$ZStrip(CATEGORY,"*WPC")_".xml"
	if loadStd {
		set file="P:\databases\enslib\packages\HL7\schema\hl7_"_$ZStrip(CATEGORY,"*WPC")_".xml"
	} else {
		w !,"Export to "_file
		set sc=..Export(CATEGORY,"c:\temp\hl7schema"_$ZStrip(CATEGORY,"*WPC")_".xml")  quit:$$$ISERR(sc) sc
	}
	w !,"Import from "_file
	set sc=..Import(file)  quit:$$$ISERR(sc) sc

	for xxx=7,8 {
		set file="c:\temp\diff_hl"_xxx_"_"_$ZStrip(CATEGORY,"*WPC")_".txt"
		open file:"wns":1  else  write "can not open file "_file,! quit
		w !,"saving to "_file
		use file
		for global="^EnsHL"_xxx_".Schema","^EnsHL"_xxx_".Description" {
			for {
				set category=$qs(global,1)
				//w !,$data(@global)#2," ",category,"=",CATEGORY," ",global
				if category=CATEGORY,$data(@global,val)#2,val'="0" write $e(global,1,6),"x",$tr($e(global,8,*),".","_"),!,val,!
				set global=$q(@global) quit:global=""
			}
		}
		close file
	}
	if cleanup kill ^EnsHL8.Schema,^EnsHL8.Description 
	quit sc
}

Property category;

Property base;

Property elementtype;

Property elementname;

Method startElement(uri As %Library.String, localname As %Library.String, qname As %Library.String, attrs As %Library.List) [ Internal ]
{
	for i=0:1:$LL(attrs)\5-1 set attribs($li(attrs,i*5+2))=$li(attrs,i*5+5)
	if localname="Category" {
		If ..CatOnly Set ..lastFileCategory=attribs("name")  ZTrap "GCAT"
		set ..category=$S(""'=..forceCategory:..forceCategory, 1:attribs("name")), ..forceCategory=""
		set ..base=$g(attribs("base"))
		set desc=$g(attribs("description"))
		set std=$g(attribs("std"))
		kill $$$vaSchemaGbl(..category)
		kill $$$vaSchemaDescGbl(..category)
		if ..base'="" set $$$vaSchemaGbl(..category,"base")=..base
		if desc'="" set $$$vaSchemaDescGbl(..category)=desc
		if $Case($ZCVT(std,"L"),"":0,0:0,"false":0,:1) set $$$vaSchemaDescGbl(..category,"std")=1
	} elseif localname="MessageGroup" {
		set $$$vaSchemaDescGbl(..category,"MG",attribs("name"))=attribs("description")
	} elseif localname="MessageEvent" {
		set $$$vaSchemaDescGbl(..category,"ME",attribs("name"))=attribs("description")
	} elseif localname="MessageType" {
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"MT",attribs("name"))=attribs("description")
		set $$$vaSchemaGbl(..category,"MT",attribs("name"))=$g(attribs("structure"))
		if $g(attribs("altstructure"))'="" set $$$vaSchemaGbl(..category,"MT",attribs("name"),"altstruct")=attribs("altstructure")
		if $g(attribs("returntype"))'="" set $$$vaSchemaGbl(..category,"MT",attribs("name"),"rettype")=attribs("returntype")
	} elseif localname="MessageStructure" {
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"MS",attribs("name"))=attribs("description")
		if $g(attribs("definition"))'="" {
			set (curlyOpen, curlyClose,squareOpen,squareClose,lessThan,greaterThan) = 0
			for i=1:1:$length(attribs("definition")) {
				set char = $E(attribs("definition"),i)
				set:char="{" curlyOpen = curlyOpen + 1
				set:char="}" curlyClose = curlyClose + 1
				set:char="[" squareOpen = squareOpen + 1
				set:char="]" squareClose = squareClose + 1
				set:char="<" lessThan = lessThan + 1
				set:char=">" greaterThan = greaterThan + 1 
			}
			if ((curlyOpen'=curlyClose) || (squareOpen'=squareClose) || (lessThan'=greaterThan)) {
				Set:(curlyOpen'=curlyClose) ..Error = $$$ERROR($$$ObjectScriptError, "Mismatched braces '{' and '}' in message structure "_attribs("name")_" in load of schema "_..Filename)
				Set:(squareOpen'=squareClose) ..Error = $$$ERROR($$$ObjectScriptError, "Mismatched braces '[' and ']' in message structure "_attribs("name")_" in load of schema "_..Filename)
				Set:(lessThan'=greaterThan) ..Error = $$$ERROR($$$ObjectScriptError, "Mismatched braces ('&lt;' and '&gt;' or '<' and '>') in message structure "_attribs("name")_" in load of schema "_..Filename)
			}
		}
		set $$$vaSchemaGbl(..category,"MS",attribs("name"))=$g(attribs("definition"))
	} elseif localname="SegmentStructure" {
		set ..elementtype="SS"
		set ..elementname=attribs("name")
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"SS",attribs("name"))=attribs("description")
		set $$$vaSchemaGbl(..category,"SS",..elementname)=""
		kill ..%propNames
	} elseif localname="SegmentSubStructure" {
		if ..elementtype'="SS" quit
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"SS",..elementname,attribs("piece"))=attribs("description")
		if $g(attribs("altdesc"))'=""     set $$$vaSchemaDescGbl(..category,"SS",..elementname,attribs("piece"),"alt")=attribs("altdesc")
		if $g(attribs("codetable"))'="" set $$$vaSchemaGbl(..category,"SS",..elementname,"tables",attribs("piece"))=attribs("codetable")
		set datastructure=$g(attribs("datatype"),$g(attribs("datastruct")))
		set max = +$g(attribs("max_length"),$g(attribs("length")))
		set:(max '= $g(attribs("max_length"),$g(attribs("length")))) max = ""
		set min = +$g(attribs("min_length"))
		set:(min '= $g(attribs("min_length"))) min = ""
		set definition=$lb(datastructure,$g(attribs("symbol")),$g(attribs("repeatcount")),max,$g(attribs("required")),+$g(attribs("ifrepeating")),min)
		set $li($$$vaSchemaGbl(..category,"SS",..elementname),attribs("piece"))=definition
		set propname=##class(EnsLib.HL7.Util.Generator).fieldDescToName(attribs("description"),..elementname,attribs("piece"))
		set basename=propname  for { set:$I(..%propNames(basename))>1 propname=basename_..%propNames(basename)  quit:..%propNames(basename)=1||'$D(..%propNames(propname)) }
		set $$$vaSchemaGbl(..category,"SS",..elementname,"names",propname)=attribs("piece")
	} elseif localname="DataType" {
		set ..elementtype="DT"
		set ..elementname=attribs("name")
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"DT",attribs("name"))=attribs("description")
		set $$$vaSchemaGbl(..category,"DT",attribs("name"))=""
		kill ..%propNames
	} elseif localname="DataSubType" {
		if ..elementtype'="DT" quit
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"DT",..elementname,attribs("piece"))=attribs("description")
		if $g(attribs("altdesc"))'=""     set $$$vaSchemaDescGbl(..category,"DT",..elementname,attribs("piece"),"alt")=attribs("altdesc")
		if $g(attribs("codetable"))'="" set $$$vaSchemaGbl(..category,"DT",..elementname,"tables",attribs("piece"))=attribs("codetable")
		set type=$g(attribs("datatype"))
		set min=+$g(attribs("min_length"))
		set max=+$g(attribs("max_length"))
		set:max'=$g(attribs("max_length")) max = ""
		set:min'=$g(attribs("min_length")) min = ""
		set req=$g(attribs("required"))
		set definition = $lb(type,min,max,req)
		set $li($$$vaSchemaGbl(..category,"DT",..elementname),attribs("piece"))=definition
		set propname=##class(EnsLib.HL7.Util.Generator).componentDescToName(attribs("description"),..elementname,attribs("piece"))
		set basename=propname  for { set:$I(..%propNames(basename))>1 propname=basename_..%propNames(basename)  quit:..%propNames(basename)=1||'$D(..%propNames(propname)) }
		set $$$vaSchemaGbl(..category,"DT",..elementname,"names",propname)=attribs("piece")
	} elseif localname="DataStructure" {
		set ..elementtype="DS"
		set ..elementname=attribs("name")
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"DT",attribs("name"))=attribs("description")
		set $$$vaSchemaGbl(..category,"DT",attribs("name"))=""
		kill ..%propNames
	} elseif localname="DataSubStructure" {
		if ..elementtype'="DS" quit
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"DT",..elementname,attribs("piece"))=attribs("description")
		if $g(attribs("altdesc"))'=""     set $$$vaSchemaDescGbl(..category,"DT",..elementname,attribs("piece"),"alt")=attribs("altdesc")
		if $g(attribs("codetable"))'="" set $$$vaSchemaGbl(..category,"DT",..elementname,"tables",attribs("piece"))=attribs("codetable")
		set type=$g(attribs("datastruct"))
		set min=""
		set max=""
		set req=""
		set definition=$lb(type,min,max,req)
		set $li($$$vaSchemaGbl(..category,"DT",..elementname),attribs("piece"))=definition
		set propname=##class(EnsLib.HL7.Util.Generator).componentDescToName(attribs("description"),..elementname,attribs("piece"))
		set basename=propname  for { set:$I(..%propNames(basename))>1 propname=basename_..%propNames(basename)  quit:..%propNames(basename)=1||'$D(..%propNames(propname)) }
		set $$$vaSchemaGbl(..category,"DT",..elementname,"names",propname)=attribs("piece")
	} elseif localname="CodeTable" {
		set ..elementtype="CT"
		set ..elementname=attribs("name")
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"CT",..elementname)=attribs("description")
		set $$$vaSchemaGbl(..category,"CT",..elementname)=attribs("tabletype")
	} elseif localname="Enumerate" {
		if ..elementtype'="CT" quit
		if $g(attribs("description"))'="" set $$$vaSchemaDescGbl(..category,"CT",..elementname,attribs("value"))=attribs("description")
		set $$$vaSchemaGbl(..category,"CT",..elementname,attribs("value"))=attribs("position")
	} elseif ..category_..lastFileCategory'="" {
		Set ..Error=$$$ERROR($$$ObjectScriptError,"unrecognized tag <"_localname_"> in load of schema "_..Filename)
	}
	Try {
		Set:..category'="" tSC2 = $$$AuditModifySchema("HL7 "_..category,"Schema saved"_$S($$$ISERR(..Error):" (ERROR)",1:""))
	}
	Catch {
	}
	quit
}

Method endElement(uri As %Library.String, localname As %Library.String, qname As %Library.String) [ Internal ]
{
	if localname="Category" {
		if $$$ISOK(..Error) {
			set ..Error=..addDefaultCategories(..category,..Filename)
			set tSC = ##class(EnsLib.HL7.Schema).BuildCategoryMaps(..category)
			#; If there was an error in BuildCategoryMaps, we need to place it into an ObjectScriptError in order to actually report the issue
			If $$$ISERR(tSC) {
				If '$System.Status.Equals(tSC,$$$ObjectScriptError) {
					Set ..Error = $$$ERROR($$$ObjectScriptError,$System.Status.GetOneStatusText(tSC,1))
				}
			}
		}
		set $$$vaSchemaGbl(..category,"time")=$ZTS
		set ..lastFileCategory=..category
		set ..category=""
	} elseif localname="SegmentStructure" {
		set ..elementtype=""
		set ..elementname=""
	} elseif localname="DataStructure" {
		set ..elementtype=""
		set ..elementname=""
	} elseif localname="DataType" {
		set ..elementtype=""
		set ..elementname=""
	} elseif localname="CodeTable" {
		set ..elementtype=""
		set ..elementname=""
	}
	quit
}

ClassMethod addDefaultCategories(pCategory As %String, pFilename As %String) As %Status [ Internal ]
{
	Set sc=$$$OK

	#; message types
	set mt="" for { set mt=$o($$$vaSchemaGbl(pCategory,"MT",mt)) quit:mt=""
		set structname=$g($$$vaSchemaGbl(pCategory,"MT",mt))
		set:""'=structname $$$vaSchemaGbl(pCategory,"MT",mt)=..addDefaultCategory(structname,pCategory,"MS",.sc,pFilename)
		set rettype=$g($$$vaSchemaGbl(pCategory,"MT",mt,"rettype"))
		set:""'=rettype $$$vaSchemaGbl(pCategory,"MT",mt,"rettype")=..addDefaultCategory(rettype,pCategory,"MT",.sc,pFilename)
		set altstruct=$g($$$vaSchemaGbl(pCategory,"MT",mt,"altstruct"))
		set:""'=altstruct $$$vaSchemaGbl(pCategory,"MT",mt,"altstruct")=..addDefaultCategory(altstruct,pCategory,"MS",.sc,pFilename)
	}
	#; message structure
	set ms="" for { set ms=$o($$$vaSchemaGbl(pCategory,"MS",ms)) quit:ms=""
		set definition=$g($$$vaSchemaGbl(pCategory,"MS",ms))
		set:""'=definition $$$vaSchemaGbl(pCategory,"MS",ms)=..addDefaultCategory(definition,pCategory,"SS",.sc,pFilename)
	}
	#; segment structure
	set ss="" for { set ss=$o($$$vaSchemaGbl(pCategory,"SS",ss)) quit:ss=""
		set definition=$g($$$vaSchemaGbl(pCategory,"SS",ss))
		set did=0  for i=1:1:$LL(definition) { set info=$LG(definition,i)
			set datastruct=$LG(info,1)
			set:""'=datastruct $li(info,1)=..addDefaultCategory(datastruct,pCategory,"DT",.sc,pFilename), $li(definition,i)=info, did=1
			set codetable=$g($$$vaSchemaGbl(pCategory,"SS",ss,"tables",i))
			set:""'=codetable $$$vaSchemaGbl(pCategory,"SS",ss,"tables",i)=..addDefaultCategory(codetable,pCategory,"CT",.sc,pFilename)
		}
		set:did $$$vaSchemaGbl(pCategory,"SS",ss)=definition
	}
	#; data structure
	set ds="" for { set ds=$o($$$vaSchemaGbl(pCategory,"DS",ds)) quit:ds=""
		set definition=$g($$$vaSchemaGbl(pCategory,"DS",ds))
		set did=0  for i=1:1:$LL(definition) { set datastruct=$LG(definition,i)
			set:""'=datastruct $li(definition,i)=..addDefaultCategory(datastruct,pCategory,"DS",.sc,pFilename), did=1
			set codetable=$g($$$vaSchemaGbl(pCategory,"DS",ds,"tables",i))
			set:""'=codetable $$$vaSchemaGbl(pCategory,"DS",ds,"tables",i)=..addDefaultCategory(codetable,pCategory,"CT",.sc,pFilename)
		}
		set:did $$$vaSchemaGbl(pCategory,"DS",ds)=definition
	}
	#; data type
	set ds="" for { set ds=$o($$$vaSchemaGbl(pCategory,"DT",ds)) quit:ds=""
		set definition=$g($$$vaSchemaGbl(pCategory,"DT",ds))
		set did=0  for i=1:1:$LL(definition)  { set datastruct=$LG($LG(definition,i),1)
			if ""'=datastruct { 
				set max=+$LG($LG(definition,i),3)
				set:max'=$LG($LG(definition,i),3) max = "" 
				set min=+$LG($LG(definition,i),2)
				set:min'=$LG($LG(definition,i),2) min = ""
				set $li(definition,i)=$lb(..addDefaultCategory(datastruct,pCategory,"DT",.sc,pFilename),min,max,$LG($LG(definition,i),4)), did=1
			}
			set codetable=$g($$$vaSchemaGbl(pCategory,"DT",ds,"tables",i))
			set:""'=codetable $$$vaSchemaGbl(pCategory,"DT",ds,"tables",i)=..addDefaultCategory(codetable,pCategory,"CT",.sc,pFilename)
		}
		set:did $$$vaSchemaGbl(pCategory,"DT",ds)=definition
	}
	quit:+$g($$$vaSchemaDescGbl(pCategory,"std")) $$$OK  ; don't report unresolved references in standard schema categories
	quit sc
}

/// Add categories to xml definitions for precise schema global definitions
ClassMethod addDefaultCategory(pValue As %String, pCategory As %String, pElementType As %String, ByRef pSC As %Status = {$$$OK}, pFilename As %String) As %String [ Internal ]
{
	for i=1:1:$L(pValue,"~") { set one=$P(pValue,"~",i)  continue:""=one
		continue:one?1P
		set:":"=$E(one) $E(one)="" ; strip leading ':'
		set:".:"=$E(one,1,2) $E(one,1,2)="" ; strip leading '.:'
		set:"base:"=$E(one,1,$L("base:")) $E(one,1,$L("base:"))="" ; strip leading 'base:'
		if one'[":" {
			kill base  set base=pCategory, base(base)=1, tElemType=pElementType
			while ""'=base
				 && '$d($$$vaSchemaGbl(base,tElemType,one))
				 && '("MT"=tElemType && ("ACK_"=$e(one,1,4)) && $d($$$vaSchemaGbl(base,"MT","ACK")))
				 && '("SS"=tElemType && $Case(one,"Zxx":1,"Hxx":1,"Any":1,:0)) {
				set base=$G($$$vaSchemaGbl(base,"base"))
				#; prevent circular references
				if ""=base||$d(base(base)) set base=""  quit
				set base(base)=1
			}
			set:""=base base="."
			set $P(pValue,"~",i)=base_":"_one
			set:"."=base&&$$$ISOK(pSC) pSC=$$$ERROR($$$ObjectScriptError,"Unresolved "_tElemType_" reference '"_one_"' in category "_pCategory_" in load of schema "_pFilename)
		}
	}
	quit pValue
}

/// Strip schema global definition categories for concise xml format
ClassMethod stripDefCategory(pValue As %String, pDefCategory As %String, pBase As %String) As %String [ Internal ]
{
	for i=1:1:$L(pValue,"~") { set one=$P(pValue,"~",i)  continue:""=one
		continue:one?1P
		set:":"=$E(one) $E(one)="" ; strip leading ':'
		if one[":" {
			set oneCat=$P(one,":"), oneDoc=$P(one,":",2)
			if oneCat=pDefCategory { set $P(pValue,"~",i)=oneDoc }
			elseif oneCat=pBase { set $P(pValue,"~",i)="base:"_oneDoc }
		}
	}
	quit pValue
}

}
