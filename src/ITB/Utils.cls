Include (Ensemble, %ZEN.ReportUtil, ITB)

Class ITB.Utils Extends %RegisteredObject
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id: //custom_ccrs/_common/tools/Iberia/ITB/latest/cls/ITB/Utils.xml#3 $";

/// Path of 7zip exe (used to build distribution package).
Parameter ZIP = "C:\Program Files\7-Zip\7zG.exe";

/// Add a docbook xml file to DOCBOOK documentation
/// pPath - Path to docbook xml file.
ClassMethod LoadDoc(pPath As %String) As %Status
{
	set ret = $$$OK
	set ns=$namespace
	try {
		set $namespace="DOCBOOK"
		$$$THROWONERROR(tSC, ##class(DocBook.Utils).Load(pPath))
		set tFilename=##class(%File).GetFilename(pPath)
		set ^DocBook.BookList(tFilename, "book", "Articles")=""
	} catch ex {
		set ret = ex.AsStatus()
	}
	set $namespace=ns
	quit ret
}

/// Create a distribution package
/// pSourcePath - Path to directory containing source files (classes, xml, etc.)
/// pTargetPAth - Path where distribution package will be created.
/// <example>
/// set source="C:\isc\p4\custom_ccrs\_common\tools\Iberia\ITB\latest"
/// set target="C:\Temp\"
/// set sc=##class(ITB.Utils).MakeDist(source,target,"ITB_1.5_2014")
/// </example>
ClassMethod MakeDist(pSourcePath As %String, pTargetPath As %String, pDistName As %String = "") As %Status
{
	set ret = $$$OK
	try {
		set version=##class(ITB.Info).#VERSION_"_"_##class(ITB.Info).#PORTING
		
		// normalize paths
		set source=##class(%File).NormalizeDirectory("", pSourcePath)
		set target=##class(%File).NormalizeDirectory("", pTargetPath)
		if ((source="")||(target="")) $$$ThrowStatus($$$ERROR($$$GeneralError,"source/target path incorrect"))
		
		// build zip file from source path excluding *.bak files
		set srcfiles = source_"*"
		if pDistName="" set pDistName="ITB_"_version
		set distfile = target_pDistName_".zip"
		set cmd=""""_..#ZIP_""" a -tzip "_distfile_" "_srcfiles_" -mx=9 -xr!*.bak" 
		set err=$ZF(-1,cmd)
		if (err) $$$ThrowStatus($$$ERROR($$$GeneralError,"'"_cmd_"' returned error "_err))
		
		// build pdf doc
		set doc = ##class(%File).SubDirectoryName(source,"backup",1)_"DOCITB.xml"
		set docpdf = target_"DOCITB_"_version_".pdf"
		set doclog = target_"DOCITB_"_version_".log"
		$$$THROWONERROR(tSC, ..BuildDocPDF(doc, docpdf, doclog))
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Build a PDF file from a docbook xml
/// pPath - Path to docbook xml file.
/// pPDFFileName - Filename of the PDF that will be generated.
/// pLogFileName - Filename of the log file that will be generated.
ClassMethod BuildDocPDF(pPath As %String, pPDFFileName As %String, pLogFileName As %String) As %Status
{
	set ret = $$$OK
	try {
		set Mode=$case($$$isVMS,1:"U",:"S")
		
		// do not include name, address, etc.
		set Params("logo-name")=""		
		set Params("logo-address1")=""
		set Params("logo-address2")=""
		set Params("logo-citystatezip")=""
		set Params("logo-website")=""
		
		// open log file
		set LogFile = ##class(%File).%New(pLogFileName)
		do LogFile.Open("WN"_Mode)
		
		// get system configured PDF renderer
		set PDFRenderer=""
		if $G(^%SYS("zenreport","transformerpath"))'="" {
			set PDFRenderer=^%SYS("zenreport","transformerpath")
		} 
		elseIf (##class(%File).Exists($$$fopbat)) {
			set PDFRenderer=$$$fopbat
		} 
		else {
			$$$ThrowStatus($$$ERROR($$$GeneralError,"You must set ^%SYS(""zenreport"",""transformerpath"") to the location of your PDF transformer."))
	    }
		
		// run XSLT to generate a PDF file
		set CSPName = $system.Util.InstallDirectory()
		set CSPDir = $S($$$isUNIX:"csp",1:"CSP")
		for tDirPiece = CSPDir,"enslib","xsl" {
			set CSPName = ##class(%Library.File).SubDirectoryName(CSPName,tDirPiece,1)
		}
		set PDFXSLFileName = CSPName_"DocBookPDFSimple.xsl"
		set pPDFFileName = ##class(%File).NormalizeFilename(pPDFFileName)
		set PDFFile = ##class(%File).%New(pPDFFileName)
		set tSC = PDFFile.Open("WN"_Mode)
		if 'tSC {
			do LogFile.WriteLine("Ensure you have sufficient privileges to write to file '"_pPDFFileName_"'")
			$$$ThrowStatus($$$ERROR($$$GeneralError,"Unable to write to "_pPDFFileName))
		}
		do PDFFile.Close()

		// Prepare the string of XSL parameters for DocBookPDFSimple.xsl
		// Note that FOP and XEP require slightly different syntax for the name-value pairs
		// Default logo is Ensemble.jpg
		// (To do: Make it compatible with VMS after resolution of current XSLT issues on that platform)
		if '$d(Params("logo-image")) {
			set XMLName = $system.Util.InstallDirectory()
			if $$$isWINDOWS {
				set XMLName = $TR(XMLName,"\","/")
			}
			set CSPDir = $S($$$isUNIX:"csp",1:"CSP")
			for tDirPiece = CSPDir,"enslib","xsl" {
				set XMLName = XMLName_tDirPiece_"/"
			}
			set Params("logo-image") = XMLName_"Ensemble.jpg"
		}
		set ParamString = ""
		set Connect = $S($ZCVT(PDFRenderer,"l")["fop":" ",1:"=")
		
		for p = "logo-image", "title-color", "href-color", "logo-name", "logo-address1", "logo-address2", "logo-citystatezip", "logo-website" {
			if $D(Params(p)) Set ParamString = ParamString_" -param "_p_Connect_""""_Params(p)_""""
		}

		do LogFile.WriteLine("Generating PDF file '"_pPDFFileName_"'")
		do LogFile.WriteLine("using XSLT '"_PDFXSLFileName_"'")
		do LogFile.WriteLine("with PDF renderer '"_PDFRenderer_"'")
		do LogFile.WriteLine("passing these parameters: "_ParamString)

		set cmd = $ZU(147,PDFRenderer)_" -xml "_$ZU(147,pPath)_" -xsl "_$ZU(147,PDFXSLFileName)_" -pdf "_$ZU(147,pPDFFileName)_ParamString_" 2>&1"
		do LogFile.WriteLine("Note: If the PDF renderer fails, check if Java is properly configured for the current user '"_$Username_"'.")
		do LogFile.WriteLine("Executing: "_cmd)
		kill tFile, ret, tRetCode
		set tSC = ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, .tFile, .ret, 300, 1, .tRetCode)
		do LogFile.WriteLine("PDF renderer terminated with code: "_$G(tRetCode)_$S($G(tRetCode)=0:" (success)",1:" (ERROR)"))
		if +$G(tRetCode) {
			set tSC = $$$ERROR($$$EnsErrGeneral,"PDF renderer terminated with error code: "_tRetCode)
		}
		if $G(ret)="" {
			do LogFile.WriteLine("PDF renderer did not return any output")
		}
		else {
			do LogFile.WriteLine("PDF renderer returned:")
			do LogFile.WriteLine(ret)
		}
		do LogFile.WriteLine("")
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Run ITB UnitTest in debug mode
ClassMethod Test(pDir As %String = "C:\ISC\p4\custom_ccrs\_common\tools\Iberia\ITB\latest\") As %Status
{
	set ret = $$$OK
	try {
		set ^UnitTestRoot = pDir
		set userParam = "v="_##class(ITB.Info).#VERSION_" 32K="_$$$ITB32K
		do ##class(%UnitTest.Manager).RunTest("src/ITB/UnitTest","/nodelete/debug",userParam)
	} catch ex {
		set ret = ex.AsStatus()
		do $system.Status.DisplayError(ret)
	}
	quit ret
}

}
