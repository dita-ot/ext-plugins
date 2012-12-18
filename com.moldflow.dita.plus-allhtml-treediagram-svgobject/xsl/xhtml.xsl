<?xml version="1.0" encoding="utf-8"?><xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:treediagram-svgobject="http://www.moldflow.com/namespace/2008/allhtml-treediagram-svgobject" xmlns:svgobject="http://www.moldflow.com/namespace/2008/dita/svgobject" xmlns:treediagram2svg="http://www.moldflow.com/namespace/2008/treediagram2svg" exclude-result-prefixes="treediagram-svgobject treediagram2svg">

    
<xsl:import href="../../com.moldflow.dita.treediagram2svg/xsl/treediagram2svg.xsl"/>

    <xsl:param name="plus-treediagram-format" select="&apos;svgobject&apos;"></xsl:param>
    <xsl:param name="plus-allhtml-treediagram-svgobject-csspath" select="&apos;&apos;"></xsl:param>
    <xsl:param name="plus-allhtml-treediagram-svgobject-jspath" select="&apos;&apos;"></xsl:param>

    <!-- Entry point. -->
    <xsl:template match="*[contains(@class, &apos; tree-d/tree &apos;)]">
        <xsl:choose>
          <xsl:when test="$plus-treediagram-format = &apos;svgobject&apos;">
            <xsl:apply-templates select="." mode="treediagram-svgobject:default"></xsl:apply-templates>
          </xsl:when>
          <xsl:otherwise>
            <xsl:next-match>
              <xsl:fallback>
                <xsl:message terminate="no">
                  <xsl:text>treediagram-svgobject: cannot fall back in XSLT 1.0.</xsl:text>
                </xsl:message>
              </xsl:fallback>
            </xsl:next-match>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Top-level tree diagram elements. -->
    <xsl:template match="*[contains(@class, &apos; tree-d/tree &apos;)]" mode="treediagram-svgobject:default">
        <div>
            <xsl:attribute name="class">treediagram</xsl:attribute>
            <xsl:call-template name="commonattributes"></xsl:call-template>
            <xsl:call-template name="setidaname"></xsl:call-template>
            <xsl:call-template name="flagcheck"></xsl:call-template>
            <!-- Apply title of tree diagram. -->
            <xsl:apply-templates select="*[contains(@class, &apos; topic/title &apos;)]" mode="treediagram-svgobject:default"></xsl:apply-templates>
            <!-- Apply body of tree diagram. -->
            <xsl:apply-templates select="." mode="svgobject:generate-reference">
              <xsl:with-param name="content">
                <xsl:call-template name="treediagram2svg:create-svg-document">
                   <xsl:with-param name="CSSPATH">
                       <xsl:call-template name="svgobject:svgobject-reverse-path"></xsl:call-template>
                       <xsl:value-of select="$plus-allhtml-treediagram-svgobject-csspath"></xsl:value-of>
                   </xsl:with-param>
                   <xsl:with-param name="JSPATH">
                       <xsl:call-template name="svgobject:svgobject-reverse-path"></xsl:call-template>
                       <xsl:value-of select="$plus-allhtml-treediagram-svgobject-jspath"></xsl:value-of>
                   </xsl:with-param>
                </xsl:call-template>
              </xsl:with-param>
              <xsl:with-param name="make-static" select="&apos;yes&apos;"></xsl:with-param>
            </xsl:apply-templates>
        </div>
    </xsl:template>

    <!-- Title for treediagram. -->
    <xsl:template match="*[contains(@class, &apos; tree-d/tree &apos;)]/*[contains(@class, &apos; topic/title &apos;)]" mode="treediagram-svgobject:default">
        <div>
            <xsl:attribute name="class">treediagram-title</xsl:attribute>
            <xsl:call-template name="commonattributes"></xsl:call-template>
            <xsl:call-template name="setidaname"></xsl:call-template>
            <xsl:call-template name="flagcheck"></xsl:call-template>
            <xsl:apply-templates></xsl:apply-templates>
        </div>
    </xsl:template>

</xsl:stylesheet>