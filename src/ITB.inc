ROUTINE ITB [Type=INC]
#; ** ITB.inc **

#; ITB debug mode
#define ITBDebug 0

#; ITB support HL7 field values greater than 32K
#define ITB32K 1

#; Max string length to write to stream. Depends on 'Enable Long Strings' setting.
#define MaxStringLen ##expression($case($zu(69, 69), 1:3600000, :32000))
 
#; Max segment length to consider using a string or stream
#define CriticalSegmentLen $$$MaxStringLen

#; Max message length to consider using a string or stream
#define CriticalMessageLen $$$MaxStringLen

#; Check if 2024 or above version
#define VersionAbove2024 ##expression((##class(%SYSTEM.Version).GetMajor() >= 2024))
																															