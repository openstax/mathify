<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:cnxml="http://cnx.rice.edu/cnxml"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  xmlns:md="http://cnx.rice.edu/mdml/0.4"
  xmlns:q="http://cnx.rice.edu/qml/1.0"
  xmlns:bib="http://bibtexml.sf.net/"
  xmlns:exsl="http://exslt.org/common"
  extension-element-prefixes="exsl"
  exclude-result-prefixes="cnxml"
>

<!-- Important: this stylesheet attempts to handle only those combinations of 
     elements and attributes in the Connexions respository at the time I was 
     writing the upconversion.  For instance, there are presently no loop 
     parameters on audio or video media elements, so there is no handling for 
     them in this conversion, even though they are valid as attributes on 
     audio and video elements.  This transformation is therefore does not 
     handle all possible CNXML 0.5 to 0.6 pathways. -->

  <xsl:output indent="yes" method="xml"/>
  <xsl:param name="moduleid"/>
  <xsl:variable name="required-id-elements" 
                select="document('')/xsl:stylesheet/reqid:elements"
                xmlns:reqid="#required-ids"/>
  <xsl:variable name="media-conversions" 
                select="document('')/xsl:stylesheet/mc:mediaconversions" 
                xmlns:mc="#media-conversions"/>
  <xsl:variable name="lower-alpha" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="upper-alpha" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <xsl:key name="author-by-id" match="/cnxml:document/cnxml:metadata/md:authorlist/md:author" use="@id"/>

  <xsl:template match="/*[local-name()='document']">
    <xsl:choose>
      <xsl:when test="@cnxml-version='0.6'">
        <xsl:copy-of select="."/>
      </xsl:when>
      <xsl:when test="not(@cnxml-version)">
        <document xmlns="http://cnx.rice.edu/cnxml" 
                  xmlns:m="http://www.w3.org/1998/Math/MathML"
                  xmlns:md="http://cnx.rice.edu/mdml/0.4"
                  xmlns:bib="http://bibtexml.sf.net/"
                  xmlns:q="http://cnx.rice.edu/qml/1.0">
          <xsl:apply-templates select="@*"/>
          <xsl:attribute name="module-id"><xsl:value-of select="$moduleid"/></xsl:attribute>
          <xsl:attribute name="cnxml-version">0.6</xsl:attribute>
          <xsl:apply-templates/>
        </document>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">This module is neither 0.5 nor 0.6!</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="cnxml:metadata">
    <xsl:copy>
      <xsl:comment>These elements are placeholers needed to create a valid document.</xsl:comment>
      <md:content-id>undefined</md:content-id>
      <md:title></md:title>
      <md:version></md:version>
      <md:created></md:created>
      <md:revised></md:revised>
      <md:authorlist>
        <md:author id="author">
          <md:firstname></md:firstname>
          <md:surname></md:surname>
          <md:fullname></md:fullname>
        </md:author>
      </md:authorlist>
      <md:maintainerlist>
        <md:maintainer id="maintainer">
          <md:firstname></md:firstname>
          <md:surname></md:surname>
          <md:fullname></md:fullname>
        </md:maintainer>
      </md:maintainerlist>
      <md:license href=""/>
      <md:licensorlist>
        <md:licensor id="licensor">
          <md:firstname></md:firstname>
          <md:surname></md:surname>
          <md:fullname></md:fullname>
        </md:licensor>
      </md:licensorlist>
      <md:language></md:language>
    </xsl:copy>
  </xsl:template>

  <!-- Convert 'name' to 'label' if the child of 'item', otherwise to 'title'. -->
  <xsl:template match="cnxml:name">
    <xsl:variable name="element-name">
      <xsl:choose>
        <xsl:when test="parent::cnxml:item and $moduleid='m14479'">cite</xsl:when>
        <xsl:when test="parent::cnxml:item">label</xsl:when>
        <xsl:otherwise>title</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$element-name}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:apply-templates select="@id"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="cnxml:name" mode="m15555">
    <xsl:element name="item" namespace="http://cnx.rice.edu/cnxml">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@type">
    <xsl:choose>
      <xsl:when test="parent::cnxml:code[parent::cnxml:figure]"></xsl:when>
      <xsl:when test="parent::cnxml:note or parent::cnxml:rule"><xsl:copy/></xsl:when>
      <xsl:when test=".='inline'">
        <xsl:attribute name="display">inline</xsl:attribute>
      </xsl:when>
      <xsl:when test=".='block'">
        <xsl:attribute name="display">block</xsl:attribute>
      </xsl:when>
      <xsl:otherwise><xsl:copy/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="cnxml:note[@type='footnote']">
    <xsl:call-template name="make-footnote"/>
  </xsl:template>

  <xsl:template name="make-footnote">
    <xsl:element name="footnote" namespace="http://cnx.rice.edu/cnxml">
      <xsl:apply-templates select="@id"/>
      <xsl:if test="not(@id)">
        <xsl:attribute name="id">
          <xsl:value-of select="generate-id()"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="cnxml:note">
    <xsl:variable name="type" select="normalize-space(@type)"/>
    <xsl:choose>
      <xsl:when test="translate($type, $upper-alpha, $lower-alpha)='footnote'">
        <xsl:call-template name="make-footnote"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="@*"/>
          <xsl:if test="not(@id)">
            <xsl:attribute name="id">
              <xsl:value-of select="generate-id()"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:if test="$type and $type != 'note' and $type != 'aside' and $type != 'warning' and $type != 'tip' and $type != 'important'">
            <xsl:element name="label" namespace="http://cnx.rice.edu/cnxml">
              <xsl:call-template name="uppercase-first-letter">
                <xsl:with-param name="data" select="normalize-space(@type)"/>
              </xsl:call-template>
            </xsl:element>
          </xsl:if>
          <xsl:apply-templates/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="cnxml:rule">
    <xsl:variable name="type" select="normalize-space(@type)"/>
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:if test="not(@id)">
        <xsl:attribute name="id">
          <xsl:value-of select="generate-id()"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$type and $type != 'rule' and $type != 'theorem' and $type != 'lemma' and $type != 'corollary' and $type != 'law' and $type != 'proposition'">
        <xsl:element name="label" namespace="http://cnx.rice.edu/cnxml">
          <xsl:call-template name="uppercase-first-letter">
            <xsl:with-param name="data" select="normalize-space(@type)"/>
          </xsl:call-template>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="uppercase-first-letter">
    <xsl:param name="data"/>
    <xsl:value-of select="concat(translate(substring($data, 1, 1), $lower-alpha, $upper-alpha), substring($data, 2))"/>
  </xsl:template>

  <xsl:template match="cnxml:list[normalize-space(@type)='inline']
                                 [parent::cnxml:section or 
                                  parent::cnxml:example or 
                                  parent::cnxml:problem]">
    <xsl:choose>
      <xsl:when test="key('author-by-id', 'billowsky')">
        <para id="{generate-id()}" xmlns="http://cnx.rice.edu/cnxml">
          <xsl:apply-templates select="." mode="default-copy"/>
        </para>
      </xsl:when>
      <xsl:otherwise>
        <div id="{generate-id()}" xmlns="http://cnx.rice.edu/cnxml">
          <xsl:apply-templates select="." mode="default-copy"/>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="cnxml:solution">
    <xsl:copy>
      <xsl:if test="preceding-sibling::processing-instruction('solution_in_back') or following-sibling::processing-instruction('solution_in_back')">
        <xsl:attribute name="print-placement">end</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="generate-id-if-required"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="processing-instruction('solution_in_back')"></xsl:template>

  <xsl:template match="*" mode="default-copy">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="generate-id-if-required"/>
      <xsl:if test="self::cnxml:list">
        <xsl:call-template name="make-after-mark"/>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="make-after-mark">
    <xsl:variable name="after">
      <xsl:choose>
        <xsl:when test="descendant::processing-instruction('mark')">
          <xsl:value-of select="normalize-space(descendant::processing-instruction('mark')[1])"/>
        </xsl:when>
        <xsl:when test="preceding-sibling::processing-instruction('mark')">
          <xsl:value-of select="normalize-space(preceding-sibling::processing-instruction('mark')[1])"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="descendant::processing-instruction('mark') or 
                  preceding-sibling::processing-instruction('mark')">
      <xsl:attribute name="mark-suffix"><xsl:value-of select="$after"/></xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="cnxml:list/@type">
    <xsl:choose>
      <xsl:when test="starts-with(normalize-space(.), 'bull') or
                      starts-with(normalize-space(.), 'unen') or
                      starts-with(normalize-space(.), 'list') or
                      starts-with(normalize-space(.), 'unor')">
        <xsl:attribute name="list-type">bulleted</xsl:attribute>
      </xsl:when>
      <xsl:when test="starts-with(normalize-space(.), 'enum') or
                      starts-with(normalize-space(.), 'enme') or
                      starts-with(normalize-space(.), 'ennu')">
        <xsl:attribute name="list-type">enumerated</xsl:attribute>
      </xsl:when>
      <xsl:when test="starts-with(normalize-space(.), 'name')">
        <xsl:attribute name="list-type">labeled-item</xsl:attribute>
      </xsl:when>
      <xsl:when test=".='inline'">
        <xsl:attribute name="list-type">labeled-item</xsl:attribute>
        <xsl:attribute name="display">inline</xsl:attribute>
      </xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="cnxml:item">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="cnxml:name"/>
      <xsl:apply-templates select="*[not(self::cnxml:name)]|text()|comment()|processing-instruction()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="cnxml:item[local-name(child::*[1])='media'][local-name(child::*[2])='name']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:element name="label" namespace="http://cnx.rice.edu/cnxml">
        <xsl:apply-templates select="child::*[1]/preceding-sibling::node()"/>
        <xsl:apply-templates select="child::*[1]"/>
        <xsl:apply-templates select="child::*[2]/preceding-sibling::node()[preceding-sibling::cnxml:media]"/>
        <xsl:apply-templates select="child::*[2]/node()"/>
      </xsl:element>
      <xsl:apply-templates select="child::*[2]/following-sibling::node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="generate-id-if-required" xmlns:reqid="#required-ids">
    <xsl:if test="not(@id)">
      <xsl:variable name="element-name" select="name(self::*)"/>
      <xsl:choose>
        <!-- Certain elements now get IDs always. -->
        <xsl:when test="$required-id-elements/reqid:element[@name=$element-name]">
          <xsl:attribute name="id">
            <xsl:value-of select="generate-id()"/>
          </xsl:attribute>
        </xsl:when>
        <!-- Block 'quote', 'pre', and 'code' get IDs always. -->
        <xsl:when test="((self::cnxml:preformat and (@type='block' or not(@type))) or 
                        ((self::cnxml:quote or self::cnxml:code) and @type='block')) and not(@id)">
          <xsl:attribute name="id">
            <xsl:value-of select="generate-id()"/>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!--
   Handle these attributes:
   - @document
   - @target-id
   - @resource
   - @version -->
  <xsl:template match="cnxml:link|cnxml:cite|cnxml:term|cnxml:quote[@type='inline' or not(@type)]">
    <xsl:copy>
      <xsl:apply-templates select="@*[not(name(.)='src')][not(name(.)='type')]"/>
      <xsl:if test="self::cnxml:quote">
        <xsl:attribute name="display">inline</xsl:attribute>
        <xsl:attribute name="class">no-marks</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="convert-link-src">
        <xsl:with-param name="src" select="normalize-space(@src)"/>
      </xsl:call-template>
      <xsl:call-template name="generate-id-if-required"/>
      <xsl:choose>
        <xsl:when test="self::cnxml:cite and string-length(normalize-space(.))">
          <cite-title xmlns="http://cnx.rice.edu/cnxml"><xsl:apply-templates/></cite-title>
        </xsl:when>
        <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="cnxml:quote">
    <xsl:copy>
      <xsl:apply-templates select="@*[not(name(.)='src')]"/>
      <xsl:call-template name="convert-link-src">
        <xsl:with-param name="src" select="normalize-space(@src)"/>
      </xsl:call-template>
      <xsl:call-template name="generate-id-if-required"/>
      <xsl:choose>
        <xsl:when test="parent::cnxml:emphasis">
          <xsl:choose>
            <!-- When there no non-whitespace sibling text nodes and no
                 sibling elements, we can output this 'quote' as a block
                 and pull the 'emphasis' element inside it. -->
            <xsl:when test="string-length(normalize-space(parent::cnxml:emphasis/text()))=0 and count(parent::cnxml:emphasis/*)=1">
              <emphasis xmlns="http://cnx.rice.edu/cnxml"><xsl:apply-templates/></emphasis>
            </xsl:when>
            <!-- When there are significant sibling nodes, we must convert 
                 this quote to @type='inline'. -->
            <xsl:otherwise>
              <xsl:attribute name="display">inline</xsl:attribute>
              <xsl:apply-templates/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="convert-link-src">
    <xsl:param name="src"/>
    <xsl:choose>
      <!-- Empty or absent @src: do nothing. -->
      <xsl:when test="not($src)">
        <xsl:if test="self::cnxml:link">
          <xsl:attribute name="url"></xsl:attribute>
        </xsl:if>
      </xsl:when>
      <!-- Absolute URL pointing to Connexions object -->
      <xsl:when test="starts-with($src, 'http:') and (
                contains($src, 'cnx.rice.edu') or
                contains($src, 'cnx.org')
                ) and
                contains($src, '/content/') and
                not(contains($src, 'content/browse')) and
                not(contains($src, 'content/search'))">
        <xsl:call-template name="make-link-attributes">
          <xsl:with-param name="attribute-name" select="'document'"/>
          <xsl:with-param name="value" select="substring-after($src, 'content/')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- Relative URL pointing to Connexions object -->
      <xsl:when test="starts-with($src, '/content/') and
                      not(contains($src, '/content/search')) and
                      not(contains($src, '/content/browse'))">
        <xsl:call-template name="make-link-attributes">
          <xsl:with-param name="attribute-name" select="'document'"/>
          <xsl:with-param name="value" select="substring-after($src, 'content/')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- Fragment identifier pointing to element @id -->
      <xsl:when test="starts-with($src, '#')">
        <xsl:call-template name="make-link-attributes">
          <xsl:with-param name="attribute-name" select="'target-id'"/>
          <xsl:with-param name="value" select="substring-after($src, '#')"/>
        </xsl:call-template>
      </xsl:when>
      <!-- Relative URL pointing to resource inside of a module -->
      <xsl:when test="not(starts-with($src, '/')) and
                      not(starts-with($src, 'http:')) and
                      not(starts-with($src, 'https:')) and
                      not(starts-with($src, 'ftp:')) and
                      not(starts-with($src, 'file:')) and
                      not(starts-with($src, 'mailto:')) and
                      not(starts-with($src, 'matilto:')) and
                      not(starts-with($src, 'mms:')) and
                      not(starts-with($src, 'www.')) and
                      not(starts-with($src, 'okapi.berkeley.edu')) and
                      not(starts-with($src, 'serials.abc-clio.com'))">
        <xsl:call-template name="make-link-attributes">
          <xsl:with-param name="attribute-name" select="'resource'"/>
          <xsl:with-param name="value" select="$src"/>
        </xsl:call-template>
      </xsl:when>
      <!-- URL pointing somewhere outside of the respository -->
      <xsl:otherwise>
        <xsl:attribute name="url"><xsl:value-of select="$src"/></xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="make-link-attributes">
    <xsl:param name="attribute-name"/>
    <xsl:param name="value"/>
    <xsl:variable name="value-before-slash" select="substring-before($value, '/')"/>
    <xsl:variable name="value-after-slash" select="substring-after($value, '/')"/>
    <xsl:variable name="first">
      <xsl:choose>
        <xsl:when test="$value-before-slash">
          <xsl:value-of select="$value-before-slash"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="rest">
      <xsl:if test="$value-after-slash">
        <xsl:value-of select="$value-after-slash"/>
      </xsl:if>
    </xsl:variable>
    <!-- Output an attribute unless its name is 'version' and the value is 'latest'. -->
    <xsl:if test="not($attribute-name = 'version' and $first = 'latest')">
      <xsl:attribute name="{$attribute-name}">
        <xsl:value-of select="$first"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="string-length($rest)">
      <xsl:choose>
        <xsl:when test="$attribute-name = 'document'">
          <xsl:call-template name="make-link-attributes">
            <xsl:with-param name="attribute-name" select="'version'"/>
            <xsl:with-param name="value" select="$rest"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="$attribute-name = 'version'">
          <xsl:choose>
            <xsl:when test="starts-with($rest, '#')">
              <xsl:call-template name="make-link-attributes">
                <xsl:with-param name="attribute-name">target-id</xsl:with-param>
                <xsl:with-param name="value" select="substring-after($rest, '#')"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="make-link-attributes">
                <xsl:with-param name="attribute-name">resource</xsl:with-param>
                <xsl:with-param name="value" select="$rest"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="cnxml:cnxn">
    <xsl:variable name="strength" select="normalize-space(@strength)"/>
    <xsl:variable name="document" select="normalize-space(@document)"/>
    <xsl:variable name="target" select="normalize-space(@target)"/>
    <xsl:element name="link" namespace="http://cnx.rice.edu/cnxml">
      <xsl:apply-templates select="@id"/>
      <xsl:if test="@document">
        <xsl:attribute name="document">
          <xsl:value-of select="$document"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@version">
        <xsl:attribute name="version">
          <xsl:value-of select="normalize-space(@version)"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="@target">
        <xsl:attribute name="target-id">
          <xsl:choose>
            <xsl:when test="$document = 'm16333' and $target ='element-176'">
              <xsl:value-of select="'uid22'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="fix-colon-in-id">
                <xsl:with-param name="id-value" select="$target"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="$strength">
        <xsl:attribute name="strength">
          <xsl:choose>
            <xsl:when test="$strength='9' or $strength='8'">3</xsl:when>
            <xsl:when test="$strength='7' or $strength='6' or
                            $strength='5' or $strength='4'">2</xsl:when>
            <xsl:when test="$strength='3' or $strength='2' or
                            $strength='1' or $strength='0'">1</xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <!-- We need at least an empty @url on 'link'. -->
      <xsl:if test="not(@document) and not(@version) and not(@target)">
        <xsl:attribute name="url"></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="cnxml:table">
    <xsl:param name="keep-figure" select="0"/>
    <xsl:variable name="summary">
      <xsl:if test="processing-instruction('table-summary')">
        <xsl:value-of select="processing-instruction('table-summary')"/>
      </xsl:if>
    </xsl:variable>
    <xsl:copy>
      <xsl:apply-templates select="@*[name(.)!='id']"/>
      <xsl:choose>
        <!-- m16333 is the one module in which cnxns pointing to a table 
              within a figure use the table @id rather than the figure @id. 
              In this case, we don't pass figure/@id down to the table 
              template.  Also, we don't pass figure/@id down to the table 
              when we are keeping the figure because both it and the table 
              have title or caption. -->
        <xsl:when test="string-length(parent::cnxml:figure/@id) and $moduleid != 'm16333' and not($keep-figure)">
          <xsl:apply-templates select="parent::cnxml:figure/@id"/>
        </xsl:when>
        <xsl:when test="string-length(@id)">
          <xsl:apply-templates select="@id"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="generate-id()"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:attribute name="summary"><xsl:value-of select="$summary"/></xsl:attribute>
      <xsl:if test="parent::cnxml:figure and preceding-sibling::cnxml:name and not(cnxml:name) and not($keep-figure)">
        <xsl:apply-templates select="preceding-sibling::cnxml:name"/>
      </xsl:if>
      <xsl:apply-templates/>
      <xsl:if test="parent::cnxml:figure and following-sibling::cnxml:caption and not(cnxml:caption) and not($keep-figure)">
        <xsl:apply-templates select="following-sibling::cnxml:caption"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="cnxml:figure[cnxml:table]">
    <xsl:choose>
      <xsl:when test="$moduleid = 'm10221' or 
                (string-length(cnxml:name) and string-length(cnxml:table/cnxml:name)) or 
                (string-length(cnxml:caption) and string-length(cnxml:table/cnxml:caption))">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:call-template name="generate-id-if-required"/>
          <xsl:apply-templates>
            <xsl:with-param name="keep-figure" select="1"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="cnxml:table"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="cnxml:figure[cnxml:code]">
    <xsl:choose>
      <xsl:when test="$moduleid = 'm10221'">
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:call-template name="generate-id-if-required"/>
          <xsl:apply-templates>
            <xsl:with-param name="keep-figure" select="1"/>
          </xsl:apply-templates>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="cnxml:code"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="cnxml:code">
    <xsl:param name="keep-figure" select="0"/>
    <xsl:copy>
      <xsl:apply-templates select="@*[name()!='id']"/>
      <xsl:if test="@type='block' or parent::cnxml:content or parent::cnxml:section or parent::cnxml:figure">
        <xsl:attribute name="id">
          <xsl:choose>
            <xsl:when test="parent::cnxml:figure and not($keep-figure)">
              <xsl:value-of select="parent::cnxml:figure/@id"/>
            </xsl:when>
            <xsl:when test="string-length(@id)">
              <xsl:value-of select="@id"/>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="generate-id()"/></xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </xsl:if>
      <xsl:if test="parent::cnxml:content or parent::cnxml:section or parent::cnxml:figure">
        <xsl:attribute name="display">block</xsl:attribute>
      </xsl:if>
      <xsl:if test="parent::cnxml:figure and not($keep-figure)">
        <xsl:attribute name="class">listing</xsl:attribute>
        <xsl:if test="preceding-sibling::cnxml:name and not($keep-figure)">
          <xsl:apply-templates select="preceding-sibling::cnxml:name"/>
        </xsl:if>
      </xsl:if>
      <xsl:apply-templates/>
      <xsl:if test="parent::cnxml:figure and following-sibling::cnxml:caption and not($keep-figure)">
        <xsl:apply-templates select="following-sibling::cnxml:caption"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <!-- media upconversion cases:
      - ext='html' or ext='htm', type='image/png', has thumbnail (Ed Doering)
      - eps around png/bmp/gif
      - png around png
      - mov around png
      - everything else (single media) -->
  <!-- FIXME: this becomes a proper 'media' with children. -->
  <xsl:template match="cnxml:media" xmlns:mc="#media-conversions">
    <xsl:variable name="ext">
      <xsl:call-template name="get-extension">
        <xsl:with-param name="data" select="normalize-space(substring-after(@src, '.'))"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="intype" select="normalize-space(@type)"/>
    <xsl:variable name="media-conversion-rtf">
      <xsl:choose>
        <xsl:when test="count($media-conversions/mc:mediaconversion[@intype=$intype][@inext=$ext])">
          <xsl:copy-of select="$media-conversions/mc:mediaconversion[@intype=$intype][@inext=$ext]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$media-conversions/mc:mediadefault"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="media-conversion" select="exsl:node-set($media-conversion-rtf)/mc:*[1]"/>
    <xsl:element name="media" namespace="http://cnx.rice.edu/cnxml">
      <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
      <xsl:attribute name="alt">
        <xsl:value-of select="descendant::cnxml:param[@name='alt'][1]/@value"/>
      </xsl:attribute>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'longdesc'"/>
      </xsl:call-template>
      <xsl:call-template name="make-media-display-attribute"/>
      <xsl:choose>
        <xsl:when test="cnxml:media">
          <xsl:choose>
            <xsl:when test="$ext = 'eps'">
              <xsl:apply-templates select="cnxml:media" mode="media-object-only"/>
              <xsl:call-template name="make-media-image">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$ext = 'mov'">
              <xsl:call-template name="make-media-audio-video">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
              </xsl:call-template>
              <xsl:apply-templates select="cnxml:media" mode="media-object-only"/>
            </xsl:when>
            <xsl:when test="normalize-space(@type) = 'image/png' and 
                            normalize-space(cnxml:media/@type) = 'image/png'">
              <xsl:call-template name="make-media-image">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
              </xsl:call-template>
            </xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$media-conversion/@objtype='image'">
              <xsl:call-template name="make-media-image">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$media-conversion/@objtype='audio' or 
                            $media-conversion/@objtype='video'">
              <xsl:call-template name="make-media-audio-video">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$media-conversion/@objtype='flash'">
              <xsl:call-template name="make-media-flash">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$media-conversion/@objtype='labview'">
              <xsl:call-template name="make-media-labview">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$media-conversion/@objtype='java-applet'">
              <xsl:call-template name="make-media-java-applet">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
                <xsl:with-param name="ext" select="$ext"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:when test="$media-conversion/@objtype='download'">
              <xsl:call-template name="make-media-download">
                <xsl:with-param name="media-conversion" select="$media-conversion"/>
              </xsl:call-template>
            </xsl:when>
          </xsl:choose>
          <!-- FIXME -->
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <xsl:template match="cnxml:media" mode="media-object-only" xmlns:mc="#media-conversions">
    <xsl:variable name="ext">
      <xsl:call-template name="get-extension">
        <xsl:with-param name="data" select="normalize-space(substring-after(@src, '.'))"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="intype" select="normalize-space(@type)"/>
    <xsl:variable name="media-conversion" select="$media-conversions/mc:mediaconversion[@intype=$intype][@inext=$ext]"/>
    <xsl:choose>
      <xsl:when test="$media-conversion/@objtype='image'">
        <xsl:call-template name="make-media-image">
          <xsl:with-param name="media-conversion" select="$media-conversion"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$media-conversion/@objtype='audio' or 
                $media-conversion/@objtype='video'">
        <xsl:call-template name="make-media-audio-video">
          <xsl:with-param name="media-conversion" select="$media-conversion"/>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="get-extension">
    <xsl:param name="data"/>
    <xsl:choose>
      <xsl:when test="contains($data, '.')">
        <xsl:call-template name="get-extension">
          <xsl:with-param name="data" select="substring-after($data, '.')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$data"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="make-media-display-attribute">
    <xsl:if test="parent::cnxml:content or parent::cnxml:section or
                  parent::cnxml:example or parent::cnxml:problem or
                  parent::cnxml:solution or parent::cnxml:statement or
                  parent::cnxml:proof">
      <xsl:attribute name="display">block</xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template name="make-media-image">
    <xsl:param name="media-conversion"/>
    <xsl:element name="{$media-conversion/@objtype}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:attribute name="src">
        <xsl:value-of select="@src"/>
      </xsl:attribute>
      <xsl:apply-templates select="@id"/>
      <xsl:call-template name="make-mime-type">
        <xsl:with-param name="media-conversion" select="$media-conversion"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'height'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'width'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'print-width'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'thumbnail'"/>
      </xsl:call-template>
      <xsl:copy-of select="cnxml:param[@name!='height' and @name!='width' and @name!='print-width' and @name!='thumbnail' and @name !='alt']"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="make-media-audio-video">
    <xsl:param name="object-type" select="'audio'"/>
    <xsl:param name="media-conversion"/>
    <xsl:element name="{$media-conversion/@objtype}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:attribute name="src">
        <xsl:value-of select="@src"/>
      </xsl:attribute>
      <xsl:apply-templates select="@id"/>
      <xsl:call-template name="make-mime-type">
        <xsl:with-param name="media-conversion" select="$media-conversion"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'height'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'width'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'autoplay'"/>
      </xsl:call-template>
      <xsl:copy-of select="@*[not(name(self::node())='type')]"/>
      <xsl:copy-of select="cnxml:param[@name!='height' and @name!='width' and @name!='autoplay' and @name!='alt']"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="make-media-flash">
    <xsl:param name="object-type"/>
    <xsl:param name="media-conversion"/>
    <xsl:element name="{$media-conversion/@objtype}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:attribute name="src">
        <xsl:value-of select="@src"/>
      </xsl:attribute>
      <xsl:apply-templates select="@id"/>
      <xsl:call-template name="make-mime-type">
        <xsl:with-param name="media-conversion" select="$media-conversion"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'height'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'width'"/>
      </xsl:call-template>
      <xsl:copy-of select="@*[not(name(self::node())='type')]"/>
      <xsl:copy-of select="cnxml:param[@name!='height' and @name!='width' and @name!='alt']"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="make-media-labview">
    <xsl:param name="object-type"/>
    <xsl:param name="media-conversion"/>
    <xsl:variable name="version">
      <xsl:choose>
        <xsl:when test="normalize-space(@type)='application/x-labviewrpvi82'">8.2</xsl:when>
        <xsl:when test="normalize-space(@type)='application/x-labviewrpvi80'">8.0</xsl:when>
        <xsl:otherwise>7.0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$media-conversion/@objtype}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:attribute name="src">
        <xsl:value-of select="@src"/>
      </xsl:attribute>
      <xsl:apply-templates select="@id"/>
      <xsl:attribute name="viname">
        <xsl:choose>
          <xsl:when test="cnxml:param[@name='lvfppviname']">
            <xsl:value-of select="cnxml:param[@name='lvfppviname']/@value"/>
          </xsl:when>
          <xsl:when test="cnxml:param[@name='viinfo']">
            <xsl:value-of select="cnxml:param[@name='viinfo']/@value"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@src"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:attribute name="version">
        <xsl:value-of select="$version"/>
      </xsl:attribute>
      <xsl:call-template name="make-mime-type">
        <xsl:with-param name="media-conversion" select="$media-conversion"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'height'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'width'"/>
      </xsl:call-template>
      <xsl:copy-of select="@*[not(name(self::node())='type')]"/>
      <xsl:copy-of select="cnxml:param[@name!='height' and @name!='width' and @name!='alt']"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="make-media-java-applet">
    <xsl:param name="object-type"/>
    <xsl:param name="media-conversion"/>
    <xsl:param name="ext"/>
    <xsl:variable name="code">
      <xsl:choose>
        <xsl:when test="cnxml:param[@name='code']">
          <xsl:value-of select="cnxml:param[@name='code']/@value"/>
        </xsl:when>
        <xsl:when test="$ext != 'jar'">
          <xsl:value-of select="normalize-space(@src)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="archive">
      <xsl:choose>
        <xsl:when test="cnxml:param[@name='archive' or @name='ARCHIVE']">
          <xsl:value-of select="cnxml:param[@name='archive' or @name='ARCHIVE']/@value"/>
        </xsl:when>
        <xsl:when test="$ext = 'jar'">
          <xsl:value-of select="normalize-space(@src)"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$media-conversion/@objtype}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:attribute name="src">
        <xsl:value-of select="@src"/>
      </xsl:attribute>
      <xsl:apply-templates select="@id"/>
      <xsl:call-template name="make-mime-type">
        <xsl:with-param name="media-conversion" select="$media-conversion"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'height'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'width'"/>
      </xsl:call-template>
      <xsl:attribute name="code"><xsl:value-of select="$code"/></xsl:attribute>
      <xsl:if test="cnxml:param[@name='archive' or @name='ARCHIVE'] or $ext = 'jar'">
        <xsl:attribute name="archive">
          <xsl:value-of select="$archive"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:copy-of select="@*[not(name(self::node())='type')]"/>
      <xsl:copy-of select="cnxml:param[@name!='height' and @name!='width' and 
                                       @name!='alt' and 
                                       normalize-space(@name)!='archive' and 
                                       normalize-space(@name)!='ARCHIVE' and 
                                       normalize-space(@name)!='code']"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="make-media-download">
    <xsl:param name="media-conversion"/>
    <xsl:element name="{$media-conversion/@objtype}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:attribute name="src">
        <xsl:value-of select="@src"/>
      </xsl:attribute>
      <xsl:apply-templates select="@id"/>
      <xsl:call-template name="make-mime-type">
        <xsl:with-param name="media-conversion" select="$media-conversion"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'width'"/>
      </xsl:call-template>
      <xsl:call-template name="make-attribute-from-param">
        <xsl:with-param name="param-name" select="'print-width'"/>
      </xsl:call-template>
      <xsl:copy-of select="cnxml:param[@name!='width' and @name!='print-width' and @name!='alt']"/>
    </xsl:element>
  </xsl:template>

  <xsl:template name="make-mime-type">
    <xsl:param name="media-conversion"/>
    <xsl:attribute name="mime-type">
      <xsl:choose>
        <xsl:when test="string-length($media-conversion/@outtype)">
          <xsl:value-of select="$media-conversion/@outtype"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space(@type)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>

  <xsl:template name="make-attribute-from-param">
    <xsl:param name="param-name"/>
    <xsl:if test="cnxml:param[@name=$param-name]">
      <xsl:attribute name="{$param-name}">
        <xsl:value-of select="cnxml:param[@name=$param-name]/@value"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@rowsep|@colsep|@pgwide">
    <xsl:choose>
      <xsl:when test="normalize-space(.)='true' or normalize-space(.)='one'">
        <xsl:attribute name="rowsep">1</xsl:attribute>
      </xsl:when>
      <xsl:when test="normalize-space(.)='no'">
        <xsl:attribute name="rowsep">0</xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="cnxml:name[string-length(normalize-space(.))=0][not(parent::cnxml:document)]"/>

  <xsl:template match="cnxml:caption[string-length(normalize-space(.))=0]"/>

  <xsl:template match="*[self::cnxml:cite][not(@*)][string-length(normalize-space(.))=0]"/>

  <xsl:template name="fix-colon-in-id">
    <xsl:param name="id-value"/>
    <xsl:value-of select="normalize-space(translate($id-value, ':', '.'))"/>
  </xsl:template>

  <xsl:template match="@id">
    <xsl:attribute name="id">
      <xsl:call-template name="fix-colon-in-id">
        <xsl:with-param name="id-value" select="normalize-space(.)"/>
      </xsl:call-template>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="cnxml:emphasis[cnxml:quote[@type='block']]">
    <xsl:apply-templates select="cnxml:quote"/>
  </xsl:template>

  <xsl:template match="m:emphasis|m:equation">
    <xsl:element name="{local-name()}" namespace="http://cnx.rice.edu/cnxml">
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="generate-id-if-required"/>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="cnxml:para">
    <xsl:choose>
      <xsl:when test="@id='element-431' and $moduleid='m15555'">
        <xsl:copy>
          <xsl:apply-templates select="@*"/>
          <xsl:apply-templates select="cnxml:name[3]/preceding-sibling::node()"/>
          <xsl:element name="list" namespace="http://cnx.rice.edu/cnxml">
            <xsl:attribute name="list-type">labeled-item</xsl:attribute>
            <xsl:attribute name="display">inline</xsl:attribute>
            <xsl:attribute name="id"><xsl:value-of select="generate-id()"/></xsl:attribute>
            <xsl:apply-templates select="cnxml:name[position() &gt; 2]" mode="m15555"/>
          </xsl:element>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="@*"/>
          <xsl:apply-templates select="cnxml:name"/>
          <xsl:apply-templates select="text()|*[not(self::cnxml:name)]|comment()|processing-instruction()"/>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="*[local-name()='file'][namespace-uri()='']">
    <bib:file xmlns:bib="http://bibtexml.sf.net/">
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates mode="bibtexml"/>
    </bib:file>
  </xsl:template>

  <xsl:template match="*" mode="bibtexml">
    <xsl:element name="bib:{local-name()}" namespace="http://bibtexml.sf.net/">
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates mode="bibtexml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="node()[not(self::*)]" mode="bibtexml">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="*[local-name()='math']">
    <m:math xmlns:m="http://www.w3.org/1998/Math/MathML">
      <xsl:apply-templates select="@*" mode="mathml"/>
      <xsl:apply-templates mode="mathml"/>
    </m:math>
  </xsl:template>

  <xsl:template match="*" mode="mathml">
    <xsl:element name="m:{local-name()}" namespace="http://www.w3.org/1998/Math/MathML">
      <xsl:apply-templates select="@*" mode="mathml"/>
      <xsl:apply-templates mode="mathml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="@*[(name(.)='definitionURL' or name(.)='encoding') and string-length(.)=0]" mode="mathml">
  </xsl:template>

  <xsl:template match="@definitionURL[string-length(.)=0]|
                       @encoding[string-length(.)=0]|
                       @overflow[.='scroll']|
                       @base[.='10']" mode="mathml">
  </xsl:template>

  <xsl:template match="node()[not(self::*)]|@*" mode="mathml">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="*">
    <xsl:apply-templates select="." mode="default-copy"/>
  </xsl:template>

  <xsl:template match="processing-instruction('mark')|
                       processing-instruction('table-summary')|
                       processing-instruction('solution_in_back')">
  </xsl:template>

  <xsl:template match="@*|text()|comment()|processing-instruction()">
    <xsl:copy/>
  </xsl:template>

  <reqid:elements xmlns:reqid="#required-ids">
    <reqid:element name="div"/>
    <reqid:element name="section"/>
    <reqid:element name="figure"/>
    <reqid:element name="subfigure"/>
    <reqid:element name="example"/>
    <reqid:element name="note"/>
    <reqid:element name="footnote"/>
    <reqid:element name="problem"/>
    <reqid:element name="solution"/>
    <reqid:element name="media"/>
    <reqid:element name="meaning"/>
    <reqid:element name="proof"/>
    <reqid:element name="statement"/>
  </reqid:elements>

  <mc:mediaconversions xmlns:mc="#media-conversions">
    <mc:mediaconversion intype="image/png" inext="png" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/gif" inext="gif" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/jpg" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="application/postscript" inext="eps" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/jpeg" inext="jpg" objtype="image" outtype=""/>
    <mc:mediaconversion intype="audio/mpeg" inext="mp3" objtype="audio" outtype=""/>
    <mc:mediaconversion intype="image/bmp" inext="bmp" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/jpg" inext="gif" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="image/png" inext="" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/png" inext="PNG" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/" inext="" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/png" inext="html" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/jpg" inext="JPG" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/jpg" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="application/msword" inext="doc" objtype="download" outtype=""/>
    <mc:mediaconversion intype="application/mspowerpoint" inext="ppt" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediaconversion intype="image/jpeg" inext="JPG" objtype="image" outtype=""/>
    <mc:mediaconversion intype="application/x-java-applet" inext="class" objtype="java-applet" outtype=""/>
    <mc:mediaconversion intype="image/jpg" inext="GIF" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="image/jpeg" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="image/jpeg" inext="gif" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="image/jpg" inext="" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="video/mpeg" inext="mov" objtype="video" outtype="video/quicktime"/>
    <mc:mediaconversion intype="image/wmf" inext="wmf" objtype="image" outtype="image/wmf"/>
    <mc:mediaconversion intype="application/x-labviewrpvi80" inext="llb" objtype="labview" outtype=""/>
    <mc:mediaconversion intype="image/" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="audio/mp3" inext="mp3" objtype="audio" outtype="audio/mpeg"/>
    <mc:mediaconversion intype="audio/x-wav" inext="wav" objtype="audio" outtype=""/>
    <mc:mediaconversion intype="application/x-labview-llb" inext="llb" objtype="labview" outtype=""/>
    <mc:mediaconversion intype="image/png" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="application/word" inext="doc" objtype="download" outtype="application/msword"/>
    <mc:mediaconversion intype="application/mp3" inext="mp3" objtype="audio" outtype="audio/mpeg"/>
    <mc:mediaconversion intype="doc/pdf" inext="pdf" objtype="download" outtype="application/pdf"/>
    <mc:mediaconversion intype="image.png" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="application/x-shockwave-flash" inext="swf" objtype="flash" outtype=""/>
    <mc:mediaconversion intype="application/x-labview-vi" inext="vi" objtype="labview" outtype=""/>
    <mc:mediaconversion intype="image/png" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="application/x-labviewrpvi82" inext="llb" objtype="labview" outtype=""/>
    <mc:mediaconversion intype="image.jpg" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/bmp" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="audio/wav" inext="wav" objtype="audio" outtype="audio/x-wav"/>
    <mc:mediaconversion intype="image/jpg" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image/src" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="application/pdf" inext="pdf" objtype="download" outtype=""/>
    <mc:mediaconversion intype="application/vnd.mspowerpoint" inext="ppt" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediaconversion intype="image/gif" inext="GIF" objtype="image" outtype=""/>
    <mc:mediaconversion intype="application/ms-word" inext="doc" objtype="download" outtype="application/msword"/>
    <mc:mediaconversion intype="application/ppt" inext="ppt" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediaconversion intype="image" inext="" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/gif" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="image" inext="gif" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="image/pjpg" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/wmf" inext="gif" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="imagejpg" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="video/mpeg" inext="mpg" objtype="video" outtype=""/>
    <mc:mediaconversion intype="application/octet" inext="m" objtype="download" outtype="application/octet-stream"/>
    <mc:mediaconversion intype="application/vnd.ms-powerpoint" inext="ppt" objtype="download" outtype=""/>
    <mc:mediaconversion intype="image" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="video/mpg" inext="mpg" objtype="video" outtype="video/mpeg"/>
    <mc:mediaconversion intype="application/x-java-applet" inext="TempCalcApplet" objtype="java-applet" outtype=""/>
    <mc:mediaconversion intype="image/jpeg" inext="jpeg" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/png" inext="gif" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="images/png" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="video.m4v" inext="m4v" objtype="video" outtype="video/mp4"/>
    <mc:mediaconversion intype="application/powerpoint" inext="ppt" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediaconversion intype="application/powerpoint" inext="pptx" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediaconversion intype="file/m" inext="m" objtype="download" outtype=""/>
    <mc:mediaconversion intype="image/fig" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/pct" inext="pct" objtype="image" outtype="image/pct"/>
    <mc:mediaconversion intype="image1.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image2.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="application/pptx" inext="pptx" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediaconversion intype="applicatoin/msword" inext="doc" objtype="download" outtype="application/msword"/>
    <mc:mediaconversion intype="applicaton/msword" inext="doc" objtype="download" outtype="application/msword"/>
    <mc:mediaconversion intype="audio/mpeg" inext="edu/Brandt/expository/" objtype="audio" outtype=""/>
    <mc:mediaconversion intype="file/wav" inext="wav" objtype="audio" outtype="audio/x-wav"/>
    <mc:mediaconversion intype="image.gif" inext="gif" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="image.png" inext="PNG" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="image/bmp" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="image/fig" inext="jpeg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/jpeg" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image/type" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="image3.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image4.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="text/plain" inext="m" objtype="download" outtype="application/octet-stream"/>
    <mc:mediaconversion intype="video/mov" inext="mov" objtype="video" outtype="video/quicktime"/>
    <mc:mediaconversion intype="application/adobeacrobat" inext="pdf" objtype="download" outtype="application/pdf"/>
    <mc:mediaconversion intype="application/maword" inext="doc" objtype="download" outtype="application/msword"/>
    <mc:mediaconversion intype="application/mspowerpoint" inext="pptx" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediaconversion intype="application/vnd.ms-word" inext="doc" objtype="download" outtype="application/msword"/>
    <mc:mediaconversion intype="application/vnd.mspowerpoint" inext="doc" objtype="download" outtype="application/msword"/>
    <mc:mediaconversion intype="application/x-java-applet" inext="jar" objtype="java-applet" outtype=""/>
    <mc:mediaconversion intype="application/x-java-applet" inext="TempCalcButtonApplet" objtype="java-applet" outtype=""/>
    <mc:mediaconversion intype="application/x-labview-llb" inext="vi" objtype="labview" outtype=""/>
    <mc:mediaconversion intype="application/x-labviewrpvi80" inext="vi" objtype="labview" outtype=""/>
    <mc:mediaconversion intype="application/xls" inext="xls" objtype="download" outtype="application/vnd.ms-excel"/>
    <mc:mediaconversion intype="applicaton/vnd.mspowerpoint" inext="ppt" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediaconversion intype="imag/jpeg" inext="" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/bitmap" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image/g" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="image/GIF" inext="GIF" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="image/gif" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/jpeg" inext="jpg/" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/jpeg" inext="jpg/image" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/JPG" inext="JPG" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/JPEG" inext="JPG" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/pg" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="image/pn" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="image/png" inext="GIF" objtype="image" outtype="image/gif"/>
    <mc:mediaconversion intype="image/png" inext="htm" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/png" inext="jpg/view" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/png" inext="pg" objtype="image" outtype=""/>
    <mc:mediaconversion intype="image/src" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image/wmf" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="image10.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image5.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image6.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image7.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image8.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image9.bmp" inext="bmp" objtype="image" outtype="image/bmp"/>
    <mc:mediaconversion intype="image9/jpg" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="images/jpeg" inext="JPG" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="images/png" inext="PNG" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="video/mp4" inext="mp4" objtype="video" outtype=""/>
    <mc:mediaconversion intype="video/x-msvideo" inext="avi" objtype="video" outtype=""/>
    <mc:mediaconversion intype="image\jpg" inext="jpg" objtype="image" outtype="image/jpeg"/>
    <mc:mediaconversion intype="application/msword" inext="docx" objtype="download" outtype="application/msword"/>
    <mc:mediaconversion intype="image/img" inext="png" objtype="image" outtype="image/png"/>
    <mc:mediaconversion intype="application/word" inext="pptx" objtype="download" outtype="application/vnd.ms-powerpoint"/>
    <mc:mediadefault objtype="download" outtype="application/octet-stream"/>
  </mc:mediaconversions>
</xsl:stylesheet>
