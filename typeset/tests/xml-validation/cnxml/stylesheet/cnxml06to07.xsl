<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:col="http://cnx.rice.edu/collxml"
  xmlns:cnxml="http://cnx.rice.edu/cnxml"
  xmlns:cnxorg="http://cnx.rice.edu/system-info"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  xmlns:md4="http://cnx.rice.edu/mdml/0.4"
  xmlns:md="http://cnx.rice.edu/mdml"
  xmlns:q="http://cnx.rice.edu/qml/1.0"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:bib="http://bibtexml.sf.net/"
  xmlns:cc="http://web.resource.org/cc/"
  xmlns:cnx="http://cnx.rice.edu/contexts#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:exsl="http://exslt.org/common"
  xmlns:str="http://exslt.org/strings"
  extension-element-prefixes="exsl str"
  exclude-result-prefixes="md4 xhtml cnx cc rdf col"
>

  <xsl:output indent="yes" method="xml"/>
  <!-- <xsl:strip-space elements="*"/> -->
  <!-- <xsl:preserve-space elements="md:abstract cnxml:code cnxml:preformat"/> -->

  <xsl:key name="member-by-userid" match="md4:author|md4:maintainer|md4:licensor|md4:editor|md4:translator" use="@id"/>
  <xsl:variable name="members" select="//md4:author|//md4:maintainer|//md4:licensor|//md4:editor|//md4:translator"/>

  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!-- Add @for="pdf" to second media object child of 'media'. -->
  <xsl:template match="*[self::cnxml:object or self::cnxml:image or self::cnxml:audio or
                         self::cnxml:video or self::cnxml:java-applet or self::cnxml:flash or
                         self::cnxml:labview or self::cnxml:text or self::cnxml:download]
                        [preceding-sibling::cnxml:object or preceding-sibling::cnxml:image or 
                         preceding-sibling::cnxml:audio or preceding-sibling::cnxml:video or 
                         preceding-sibling::cnxml:java-applet or preceding-sibling::cnxml:flash or 
                         preceding-sibling::cnxml:labview or preceding-sibling::cnxml:text or 
                         preceding-sibling::cnxml:download]">
    <xsl:copy>
      <xsl:attribute name="for">pdf</xsl:attribute>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!-- Bump CNXML version and ensure presence of needed namespaces. -->
  <xsl:template match="cnxml:document">
    <xsl:choose>
      <xsl:when test="@cnxml-version='0.7'">
        <xsl:copy-of select="."/>
      </xsl:when>
      <xsl:when test="@cnxml-version='0.6'">
        <document xmlns="http://cnx.rice.edu/cnxml"
                  xmlns:cnxorg="http://cnx.rice.edu/system-info"
                  xmlns:m="http://www.w3.org/1998/Math/MathML"
                  xmlns:md="http://cnx.rice.edu/mdml"
                  xmlns:q="http://cnx.rice.edu/qml/1.0"
                  xmlns:bib="http://bibtexml.sf.net/">
          <xsl:apply-templates select="@*"/>
          <xsl:attribute name="cnxml-version">0.7</xsl:attribute>
          <xsl:apply-templates select="node()"/>
        </document>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">This module is neither 0.6 nor 0.7!</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Convert md4:parent-module to md:derived-from. -->
  <xsl:template match="md4:parent-module">
    <xsl:element name="md:derived-from">
      <xsl:attribute name="url"><xsl:value-of select="@href"/></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- Convert md4:license/@href to md:license/@url-->
  <xsl:template match="md4:license/@href">
    <xsl:attribute name="url"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <!-- Add MDML version number to metadata element. -->
  <xsl:template match="cnxml:metadata">
    <xsl:element name="{name()}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:apply-templates select="@*"/>
      <xsl:attribute name="mdml-version">0.5</xsl:attribute>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>

  <!-- Update namespace on MDML elements. -->
  <xsl:template match="md4:*">
    <xsl:element name="md:{local-name()}" namespace="http://cnx.rice.edu/mdml">
      <xsl:apply-templates select="node()|@*"/>
    </xsl:element>
  </xsl:template>

  <!-- Add repository and content-url elements to metadata after content-id. -->
  <xsl:template match="md4:content-id">
    <xsl:element name="md:{local-name()}" namespace="http://cnx.rice.edu/mdml">
      <xsl:apply-templates select="node()|@*"/>
    </xsl:element>
    <xsl:element name="md:repository">http://cnx.org/content</xsl:element>
    <xsl:element name="md:content-url">
      <xsl:value-of select="concat('http://cnx.org/content/', string(.), '/', string(parent::*/md4:version), '/')"/>
    </xsl:element>
  </xsl:template>

  <!-- Rework roles in MDML. -->
  <xsl:template match="md4:authorlist">
    <xsl:element name="md:actors" namespace="http://cnx.rice.edu/mdml">
      <xsl:for-each select="$members[generate-id()=generate-id(key('member-by-userid', @id)[1])]">
        <xsl:apply-templates select="." mode="conversion"/>
      </xsl:for-each>
    </xsl:element>
    <xsl:element name="md:roles" namespace="http://cnx.rice.edu/mdml">
      <xsl:element name="md:role">
        <xsl:attribute name="type">author</xsl:attribute>
        <xsl:variable name="userids">
          <xsl:for-each select="md4:author/@id">
            <xsl:value-of select="concat(., ' ')"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="normalize-space($userids)"/>
      </xsl:element>
      <xsl:element name="md:role">
        <xsl:attribute name="type">maintainer</xsl:attribute>
        <xsl:variable name="userids">
          <xsl:for-each select="following-sibling::md4:maintainerlist/md4:maintainer/@id">
            <xsl:value-of select="concat(., ' ')"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="normalize-space($userids)"/>
      </xsl:element>
      <xsl:element name="md:role">
        <xsl:attribute name="type">licensor</xsl:attribute>
        <xsl:variable name="userids">
          <xsl:for-each select="following-sibling::md4:licensorlist/md4:licensor/@id">
            <xsl:value-of select="concat(., ' ')"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="normalize-space($userids)"/>
      </xsl:element>
      <xsl:if test="following-sibling::md4:editorlist">
        <xsl:element name="md:role">
          <xsl:attribute name="type">editor</xsl:attribute>
        <xsl:variable name="userids">
          <xsl:for-each select="following-sibling::md4:editorlist/md4:editor/@id">
            <xsl:value-of select="concat(., ' ')"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="normalize-space($userids)"/>
        </xsl:element>
      </xsl:if>
      <xsl:if test="following-sibling::md4:translatorlist">
        <xsl:element name="md:role">
          <xsl:attribute name="type">translator</xsl:attribute>
        <xsl:variable name="userids">
          <xsl:for-each select="following-sibling::md4:translatorlist/md4:translator/@id">
            <xsl:value-of select="concat(., ' ')"/>
          </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="normalize-space($userids)"/>
        </xsl:element>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*[self::md4:author or self::md4:maintainer or self::md4:licensor or self::md4:editor or self::md4:translator]" mode="conversion">
    <xsl:element name="md:person">
      <xsl:attribute name="userid">
        <xsl:value-of select="@id"/>
      </xsl:attribute>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*[self::md4:author or self::md4:maintainer or self::md4:licensor or self::md4:editor or self::md4:translator][@id='cnxorg']" mode="conversion">
    <xsl:element name="md:organization">
      <xsl:attribute name="userid">
        <xsl:value-of select="@id"/>
      </xsl:attribute>
      <xsl:apply-templates select="node()"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="md4:*[@id='cnxorg']/md4:firstname">
  </xsl:template>

  <xsl:template match="md4:*[@id='cnxorg']/md4:surname">
    <xsl:element name="md:shortname"><xsl:value-of select="."/></xsl:element>
  </xsl:template>

  <xsl:template match="md4:maintainerlist|md4:licensorlist|md4:editorlist|md4:translatorlist">
  </xsl:template>

</xsl:stylesheet>
