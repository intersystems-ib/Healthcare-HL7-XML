Class ITB.Production.TestXMLHL7HTTP Extends Ens.Production
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

XData ProductionDefinition
{
<Production Name="ITB.Production.TestXMLHL7HTTP" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="HL7HTTPXMLService" Category="" ClassName="ITB.HL7.BS.HTTPXMLService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="ArchiveIO">1</Setting>
    <Setting Target="Host" Name="MessageSchemaCategory">2.5</Setting>
    <Setting Target="Host" Name="TargetConfigNames">HL7FileXMLOperation</Setting>
    <Setting Target="Host" Name="BadMessageHandler">HL7XML Error</Setting>
    <Setting Target="Host" Name="XMLInputHandler">HL7XML Log</Setting>
    <Setting Target="Adapter" Name="Port">9000</Setting>
    <Setting Target="Adapter" Name="Charset">UTF-8</Setting>
    <Setting Target="Adapter" Name="StayConnected">-1</Setting>
  </Item>
  <Item Name="HL7FileXMLOperation" Category="" ClassName="ITB.HL7.BO.FileXMLOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\outHL7</Setting>
  </Item>
  <Item Name="HL7FileXMLService" Category="" ClassName="ITB.HL7.BS.FileXMLService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="TargetConfigNames">HL7HTTPXMLOperation</Setting>
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\inHL7</Setting>
    <Setting Target="Host" Name="ArchiveIO">1</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.xml</Setting>
    <Setting Target="Host" Name="AlertOnError">1</Setting>
    <Setting Target="Host" Name="BadMessageHandler">HL7XML Error</Setting>
    <Setting Target="Host" Name="XMLInputHandler"></Setting>
  </Item>
  <Item Name="HL7XML Error" Category="" ClassName="EnsLib.File.PassthroughOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\error</Setting>
    <Setting Target="Host" Name="Filename">%f_%Q.xml</Setting>
  </Item>
  <Item Name="HL7XML Log" Category="" ClassName="EnsLib.File.PassthroughOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\log</Setting>
    <Setting Target="Host" Name="Filename">%f_%Q.xml</Setting>
  </Item>
  <Item Name="HL7HTTPXMLOperation" Category="" ClassName="ITB.HL7.BO.HTTPXMLOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="HTTPPort">9000</Setting>
    <Setting Target="Adapter" Name="HTTPServer">127.0.0.1</Setting>
  </Item>
</Production>
}

}
