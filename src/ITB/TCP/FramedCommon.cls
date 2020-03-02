Include (%occInclude, Ensemble)

/// Common class for inbound and outbound framed adapters
Class ITB.TCP.FramedCommon Extends EnsLib.TCP.CountedCommon [ Abstract, ClassType = "", ProcedureBlock ]
{

/// Frame Prefix Character (ASCII code)
Property PrefixChar As %String [ InitialExpression = "11" ];

/// Frame Suffix Character (ASCII code)
Property SuffixChar As %String [ InitialExpression = "28,13" ];

/// Frame Preffix
Property Prefix As %String;

/// Frame Suffix
Property Suffix As %String;

/// Temporal Buffer Size
Property TempBufSize As %String [ InitialExpression = 32000 ];

/// Should the adapter construct a FileStream or a GlobalStream for data received?
Property UseFileStream As %Boolean;

/// Read data from the TCP socket into the Stream using a Charset for translation
Method ReadFramedStream(ByRef pStream As %CharacterStream = "", pCharset As %String = "", pStartTimeout As %Numeric = -1, pTimeout As %Numeric = 60, pInbound As %Boolean = 0) As %Status
{
	set ret = $$$OK
	
	try {
		// switch to RAW input mode
		do SetIO^%NLS("RAW")
	
		// instantiate output Stream object	
		if pInbound,'$IsObject(pStream) do ..CreateStream(.pStream, pCharset)
		$$$ASSERT($IsObject(pStream))
		
		// create temporary Stream for temp writes
		set tStream = ##class(%FileCharacterStream).%New()  $$$ASSERT($IsObject(tStream))
		set tStream.TranslateTable = "RAW" 		; avoid data translation for temp writes
		set tStream.StreamFormatWrite = 0 		; ensure writes to the stream don't convert $c(13,10) to $c(10)
		set tStream.TranslateTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)
		
		// read TCP framed data
		set ok=0
		if '$l(..Prefix) set ok=1
		set buffer="",zh=$zh
		for  {
			read *x:pTimeout
			if x=-1	$$$ThrowStatus($$$ERROR($$$EnsErrTCPReadTimeoutExpired,pTimeout,pCharset))
			if 'ok,$find(..Prefix,$char(x)) set ok=1
			if 'ok $$$TRACE("Wait for "_..Prefix_" but received "_$char(x))
			if ok { 
				set buffer=buffer_$char(x)
				if $l(buffer)>..TempBufSize {
					do tStream.Write(buffer)
					set buffer=""
				}
			}
			if $find(..Suffix,$char(x)) quit
			if ($zh-zh)>pTimeout $$$ThrowStatus($$$ERROR($$$EnsErrTCPReadTimeoutExpired,pTimeout,pCharset))
		}
		
		// copy data to output Stream and remove frame prefix and suffix
		do tStream.Write($tr($tr(buffer,..Prefix,""),..Suffix,""))
		while 'tStream.AtEnd {
			set buffer = tStream.Read()
			do pStream.Write($tr($tr(buffer,..Prefix,""),..Suffix,""))
		}
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	quit ret
}

/// Write the stream contents as on the TCP socket
Method WriteFramedStream(pStream As %Stream.Object, pCharset As %String = "", pInbound As %Boolean = 0) As %Status
{
	set ret = $$$OK
	
	try {
		do {
			set tTable = ##class(%IO.I.TranslationDevice).GetCharEncodingTable(pCharset)
			//do SetIO^%NLS("RAW")

			if "RAW"=tTable {
				write ..Prefix
				$$$THROWONERROR(tSC, pStream.OutputToDevice())
				write ..Suffix
			} 
			else {
				// use 8k chunks to allow up to 4x expansion in $zcvt
				set tLen=0,tLeft=pStream.Size,tMaxChunk=$$$GetClassParameter("%Library.FileCharacterStream","MAXLOCALSIZE")\4
				for iChunk=1:1 {
					set tChunkSize = $select(tLeft>tMaxChunk:tMaxChunk,1:tLeft)
					set ^||EnsWCSChunk(iChunk) = $zcvt(pStream.Read(tChunkSize),"O",tTable), tLen=tLen+$L(^||EnsWCSChunk(iChunk))
					set tLeft = tLeft-tChunkSize  quit:tLeft'>0
				}
				$$$catTRACE("protocol","Converted("_pStream.Size_") characters to ("_tLen_") output bytes using charset '"_pCharset_"', table '"_tTable_"'")
		
				write ..Prefix
				for i=1:1:iChunk write ^||EnsWCSChunk(i)
				write ..Suffix
			}
			write *-3 // flush buffer
			
		} while(0)
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Create a Stream object 
Method CreateStream(ByRef pStream As %CharacterStream, pCharset As %String) [ Private ]
{
	if ""'=pStream set pStream=$classmethod(pStream,"%New")
	
	// Binary charset
	if "binary"=$zcvt(pCharset,"L") {
		if ..UseFileStream { 
			set pStream=##class(%FileBinaryStream).%New() 
		}
		else { 
			set pStream=##class(%GlobalBinaryStream).%New()
		}
	}
	// Other charset 
	else {
		if ..UseFileStream {
			set pStream=##class(%FileCharacterStream).%New()
			set pStream.TranslateTable="UnicodeLittle", pStream.BOM=""
		} 
		else {
			set pStream=##class(%GlobalCharacterStream).%New()
		}
	}
}

/// Preffix Setter
Method PrefixCharSet(pValue As %String) As %Status
{
	set i%PrefixChar = pValue
	set i%Prefix = ..GetChars(pValue)
	quit $$$OK
}

/// Suffix Setter
Method SuffixCharSet(pValue As %String) As %Status
{
	set i%SuffixChar = pValue
	set i%Suffix = ..GetChars(pValue)
	quit $$$OK
}

/// Returns a string built from a given comma separated list (e.g. "28,13")
Method GetChars(pValue) As %String [ Private ]
{
	set ret = ""	
	for i=1:1:$l(pValue,",") {
		set ret = ret_$c($p(pValue,",",i))	
	}
	quit ret
}

}
