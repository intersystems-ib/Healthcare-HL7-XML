/// Simple XSLT that replace ORM_O01.ORDER_DETAIL for TRANSFORMED.ORDER_DETAIL
Class ITB.Production.Sample.SimpleXSLT Extends %RegisteredObject
{

XData XSLT
{
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" />
        </xsl:copy>
    </xsl:template>
    <xsl:template match="ORM_O01.ORDER_DETAIL">
        <TRANSFORMED.ORDER_DETAIL><xsl:apply-templates select="@*|node()" /></TRANSFORMED.ORDER_DETAIL>
    </xsl:template>
</xsl:stylesheet>
}

}
