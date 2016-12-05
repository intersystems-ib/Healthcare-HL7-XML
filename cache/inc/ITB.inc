^INC^Save for Source Control^^~Format=Cache.S~^UTF8
%RO
ITB^INC^^^0
#; ** ITB.inc **
.
#; ITB debug mode
#define ITBDebug 0
.
#; ITB support HL7 field values greater than 32K
#define ITB32K 1
.
#; Max string length to write to stream. Depends on 'Enable Long Strings' setting.
#define MaxStringLen ##expression($case($zu(69, 69), 1:3600000, :32000))
 
#; Max segment length to consider using a string or stream
#define CriticalSegmentLen $$$MaxStringLen
.
#; Max message length to consider using a string or stream
#define CriticalMessageLen $$$MaxStringLen
																															



