<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:cnx="http://cnx.rice.edu/cnxml"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
  xmlns:md="http://cnx.rice.edu/mdml/0.4"
  xmlns:qml="http://cnx.rice.edu/qml/1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:mod="http://cnx.rice.edu/#moduleIds"
  xmlns:bib="http://bibtexml.sf.net/">

  <!-- Import identity transform first so it gets lowest priority -->
  <xsl:import href="ident.xsl"/>

  <!-- Import our local translation keys -->
  <xsl:import href="cnxmll10n.xsl"/>

  <!-- MathML support -->
  <xsl:include href="http://cnx.rice.edu/technology/mathml/stylesheet/cnxmathmlc2p.xsl"/>

  <!-- Bibtexml support -->
  <xsl:include href="http://cnx.rice.edu/technology/bibtexml/stylesheet/bibtexml.xsl"/>

  <!-- QML support -->
  <xsl:include href="http://cnx.rice.edu/technology/qml/stylesheet/qml.xsl"/>

  <!-- Include the CALS Table stylesheet -->
  <xsl:include href="table.xsl"/>

  <!-- Include the Media stylesheet -->
  <xsl:include href="media.xsl"/>

  <xsl:param name="toc" select="0"/>
  <xsl:param name="viewmath" select="0"/>
  <xsl:param name="wrapper" select="1"/>
  <xsl:param name="objectId"/>
  <xsl:variable name="customstylesheet" select="/module/display/customstylesheet"/>
  <xsl:variable name="memcases" select="document('memcases.xml')/mod:modules"/>
  <xsl:variable name="case-diagnosis">
    <xsl:choose>
      <xsl:when test="$memcases/mod:module[@moduleId=$objectId] or                       $customstylesheet = 'case_diagnosis'">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="version">
    <xsl:choose>
      <xsl:when test="//cnx:document/@cnxml-version">
        <xsl:value-of select="//cnx:document/@cnxml-version"/>
      </xsl:when>
      <xsl:otherwise>0.5</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="lower" select="'abcdefghijklmnopqrstuvwxyzäëïöüáéíóúàèìòùâêîôûåøãõæœçłñ'"/>
  <xsl:variable name="upper" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZÄËÏÖÜÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÅØÃÕÆŒÇŁÑ'"/>
  <xsl:param name="printstyle" select="''"/>
  <xsl:param name="modern-textbook" select="$printstyle!=''"/>
  <xsl:param name="intro-module" select="0"/>

  <xsl:output omit-xml-declaration="yes" indent="yes"/>

  <!--ID CHECK -->
  <xsl:template name="IdCheck">
    <xsl:if test="@id">
      <xsl:attribute name="id">
	<xsl:value-of select="@id"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <!-- HOW MANY SECTION-LIKE ANCESTORS (for determining header levels) -->
  <xsl:template name="level-count">
    <xsl:variable name="level-number">
      <xsl:call-template name="level-count-ancestors"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$level-number &lt; 4">
        <xsl:value-of select="$level-number + 2"/>
      </xsl:when>
      <!-- There is no h7 element in HTML -->
      <xsl:otherwise>6</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="level-count-ancestors">
    <xsl:value-of select="count(ancestor::cnx:section|
                                ancestor::qml:problemset|
                                ancestor::qml:item[parent::qml:problemset]|
                                ancestor::cnx:example[cnx:name or cnx:title or not(cnx:label[not(node())])]|
                                ancestor::cnx:rule[cnx:name or cnx:title or not(cnx:label[not(node())])]|
                                ancestor::cnx:statement[cnx:name or cnx:title or cnx:label[node()]]|
                                ancestor::cnx:proof[cnx:name or cnx:title or not(cnx:label[not(node())])]|
                                ancestor::cnx:quote[not(@display='inline')][cnx:title or cnx:label[node()]]|
                                ancestor::cnx:code[cnx:title or cnx:label[node()]][not(@class!='listing')]|
                                ancestor::cnx:exercise[cnx:name or cnx:title or not(cnx:label[not(node())])]|
                                ancestor::cnx:problem[cnx:name or cnx:title or cnx:label[node()]]|
                                ancestor::cnx:commentary[cnx:name or cnx:title or cnx:label[node()]]|
                                ancestor::cnx:solution[cnx:name or cnx:title or not(cnx:label[not(node())])]|
                                ancestor::cnx:glossary|
                                ancestor::cnx:para[cnx:name or cnx:title]|
                                ancestor::cnx:div[cnx:title]|
                                ancestor::cnx:note[not(@display='inline')][cnx:title or cnx:label[node()] or ((@type!='' or not(@type)) and not(cnx:label))]|
                                ancestor::cnx:list[not((@type='inline' and $version='0.5') or @display='inline')][cnx:name or cnx:title]
                                )"/>
  </xsl:template>

  <!-- Declare a key for the id attribute since we may not be loading
  the DTD so we can't rely on id() working --> 
  <xsl:key name="id" match="*" use="@id"/>

  <xsl:template match="/">
    <xsl:choose>
      <!-- FAKE WRAPPER -->
      <xsl:when test="$wrapper">

	<html>
	  <head>
	    <title><xsl:value-of select="cnx:document/cnx:name|cnx:module/cnx:name"/></title>
	    
	    <link rel="stylesheet" type="text/css" href="/cnx-styles/sky/ns4.css"/>
	    <link rel="stylesheet" title="Sky" type="text/css" href="/cnx-styles/sky/document.css"/>
	    <!-- The extra space is because some browsers don't like script as an empty tag -->
	    <script type="text/javascript" src="/js/exercise.js"><xsl:text> </xsl:text></script>
	    <script type="text/javascript" src="/js/qml_1-0.js"><xsl:text> </xsl:text></script>
	    <xsl:if test="$toc">
	      <script type="text/javascript" src="/js/toc.js"><xsl:text> </xsl:text></script>
	    </xsl:if>

	    <xsl:comment>****QML**** sets the feedback and hints to non-visible.</xsl:comment>
	    <style type="text/css">
	      .feedback {display:none}
	      .hint {display:none}
	    </style>
	  </head>
	  
	  <body>
	    <xsl:comment>Editing In Place javascript</xsl:comment>
	    <div id="header">
	      <h1 id="name-box">
		<xsl:value-of select="cnx:document/cnx:name|cnx:module/cnx:name"/>
	      </h1>
	      <div id="about-links"> </div>

	      <div id="abstract-objectives">
		<div id="abstract">
		  <span id="abstract-before">Summary: </span>
		  <xsl:value-of select="cnx:module/cnx:abstract|cnx:module/cnx:metadata/cnx:abstract|cnx:module/cnx:metadata/md:abstract|cnx:document/cnx:metadata/md:abstract"/>
		</div>
	      </div>

	    </div>
	    
	    <xsl:apply-templates select="cnx:document|cnx:module"/>


	    <div id="footer">
	      <div id="credits">

		<div id="licensorlist">
		  <span id="licensorlist-before">Copyright: </span>
		  <xsl:for-each select="cnx:module/cnx:authorlist/cnx:author|cnx:module/cnx:metadata/cnx:authorlist/cnx:author|cnx:module/cnx:metadata/md:authorlist/md:author|cnx:document/cnx:metadata/md:authorlist/md:author">
		    <span class="author">
		      <span class="name">
			<xsl:choose>
			  <xsl:when test="@name">
			    <xsl:value-of select="@name"/>
			  </xsl:when>
			  <xsl:otherwise>
			    <xsl:value-of select="cnx:firstname|md:firstname"/> <xsl:value-of select="cnx:surname|md:surname"/>
			  </xsl:otherwise>
			</xsl:choose>
		      </span>
		      <xsl:choose>
			<xsl:when test="@email">
			  (<a class="email" href="mailto:{@email}"><xsl:value-of select="@email"/></a>)
			</xsl:when>
			<xsl:when test="cnx:email|md:email">
			  (<a class="email" href="mailto:{cnx:email|md:email}"><xsl:value-of select="cnx:email|md:email"/></a>)
			</xsl:when>
		      </xsl:choose>
		    </span>
		    <xsl:if test="position()!=last()">, </xsl:if>
		  </xsl:for-each>
		</div>

		<div id="authorlist">
		  <span id="authorlist-before">Written By: </span>
		  <xsl:for-each select="cnx:module/cnx:authorlist/cnx:author|cnx:module/cnx:metadata/cnx:authorlist/cnx:author|cnx:module/cnx:metadata/md:authorlist/md:author|cnx:document/cnx:metadata/md:authorlist/md:author">
		    <span class="author">
		      <span class="name">
			<xsl:choose>
			  <xsl:when test="@name">
			    <xsl:value-of select="@name"/>
			  </xsl:when>
			  <xsl:otherwise>
			    <xsl:value-of select="cnx:firstname|md:firstname"/> <xsl:value-of select="cnx:surname|md:surname"/>
			  </xsl:otherwise>
			</xsl:choose>
		      </span>
		      <xsl:choose>
			<xsl:when test="@email">
			  (<a class="email" href="mailto:{@email}"><xsl:value-of select="@email"/></a>)
			</xsl:when>
			<xsl:when test="cnx:email|md:email">
			  (<a class="email" href="mailto:{cnx:email|md:email}"><xsl:value-of select="cnx:email|md:email"/></a>)
			</xsl:when>
		      </xsl:choose>
		    </span>
		    <xsl:if test="position()!=last()">, </xsl:if>
		  </xsl:for-each>
		</div>

		<div id="maintainerlist">
		  <span id="maintainerlist-before">Maintained By: </span>
		  <xsl:for-each select="cnx:module/cnx:maintainerlist/cnx:maintainer|cnx:module/cnx:metadata/cnx:maintainerlist/cnx:maintainer|cnx:module/cnx:metadata/md:maintainerlist/md:maintainer|cnx:document/cnx:metadata/md:maintainerlist/md:maintainer">
		    <span class="maintainer">
		      <span class="name">
			<xsl:value-of select="cnx:firstname|md:firstname"/> <xsl:value-of select="cnx:surname|md:surname"/>
		      </span>
		      <xsl:if test="cnx:email|md:email">
			(<a class="email" href="mailto:{cnx:email|md:email}"><xsl:value-of select="cnx:email|md:email"/></a>)
		      </xsl:if>
		    </span>
		    <xsl:if test="position()!=last()">, </xsl:if>
		  </xsl:for-each>
		</div>

	      </div>
	    </div>
	  </body>
	</html>
      </xsl:when>
      <!-- END WRAPPER -->
      <xsl:otherwise>
	<xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Header and Body for the Document -->
  <xsl:template match="cnx:module|cnx:document">

    <div id="cnx_main">

      <!-- rest of content -->

      <xsl:if test="$toc">
        <input type="button" value="View/Hide Table of Contents" onclick="toggleToc();"/>
	<xsl:call-template name="toc"/>
      </xsl:if>

      <!-- Transform all of the content except glossary and bib. -->
      <xsl:apply-templates select="*[not(self::cnx:glossary|self::bib:file)]"/>

      <!-- FOOTNOTEs -->
      <xsl:if test="descendant::cnx:note[translate(@type,$upper,$lower)='footnote'] or descendant::cnx:footnote">
        <div class="footnotes">
        <h2 class="footnotes-header">
          <!-- Footnotes -->
          <xsl:call-template name="gentext">
            <xsl:with-param name="key">Footnotes</xsl:with-param>
            <xsl:with-param name="lang" select="/module/metadata/language"/>
          </xsl:call-template>
        </h2>
        <ol id="footnotes">
          <xsl:for-each select="descendant::cnx:note[translate(@type,$upper,$lower)='footnote']|descendant::cnx:footnote">
            <xsl:variable name="footnote-number">
              <xsl:number level="any" count="//cnx:note[translate(@type,$upper,$lower)='footnote']|//cnx:footnote" format="1"/>
            </xsl:variable>
            <li>
              <xsl:call-template name="IdCheck"/>
              <a name="footnote{$footnote-number}"><xsl:text> </xsl:text></a>
              <xsl:apply-templates/>
            </li>
          </xsl:for-each>
        </ol>
        </div>
      </xsl:if>

      <!-- GLOSSARY -->
      <xsl:apply-templates select="cnx:glossary"/>

      <!--BIBTEXML -->
      <xsl:if test="bib:file">
	<xsl:apply-templates select="bib:file"/>
      </xsl:if>

   </div>

  </xsl:template>

  <!-- GLOSSARY -->
  <xsl:template match="cnx:glossary">
    <div class="glossary-container">
      <xsl:call-template name="IdCheck"/>
      <h2 class="glossary-header">
        <!--Glossary-->
        <xsl:call-template name="gentext">
          <xsl:with-param name="key">Glossary</xsl:with-param>
          <xsl:with-param name="lang" select="/module/metadata/language"/>
        </xsl:call-template>
      </h2>
      <div class="glossary-contents">
        <xsl:apply-templates/>
      </div>
    </div>
  </xsl:template>

  <!-- TOC -->
  <xsl:template name="toc">
    <!-- Table of contents -->
    <div class="toc" id="tableofcontents">
      <h2 id="toc">
        <xsl:call-template name="gentext">
	  <xsl:with-param name="key">TableofContents</xsl:with-param>
	  <xsl:with-param name="lang" select="/module/metadata/language"/>
	</xsl:call-template>
        <!--Table of Contents--></h2>
      <ul class="toc">
	<xsl:for-each select="cnx:section|cnx:content/cnx:section">
	  <li class="toc">
	    <xsl:number level="single" count="cnx:section" format="1.  "/>
	    <a href="#{@id}"><xsl:value-of select="@name|cnx:name"/></a>
	    <ul class="toc">
	      <xsl:for-each select="cnx:section">
		<li class="toc">
		  <xsl:number level="multiple" count="cnx:section" format="1.1  "/>
		  <a href="#{@id}"><xsl:value-of select="@name|cnx:name"/></a>
		  <ul class="toc">
		    <xsl:for-each select="cnx:section">
		      <li class="toc">
			<xsl:number level="multiple" count="cnx:section" format="1.1.1  "/>
			<a href="#{@id}"><xsl:value-of select="@name|cnx:name"/></a>
		      </li>
		    </xsl:for-each>
		  </ul>
		</li>
	      </xsl:for-each>
	    </ul>
	  </li>	
	</xsl:for-each>
      </ul>
    </div>
  </xsl:template>

  <!-- METADATA and other non-displayed elements -->
  <xsl:template match="cnx:metadata|cnx:authorlist|cnx:maintainerlist|cnx:keywordlist|cnx:abstract|cnx:objectives|cnx:featured-links|cnx:link-group"/>

  <!-- Actually process SECTION ouput here -->
  <xsl:template match="cnx:section">
    <div class="section">
      <xsl:call-template name="IdCheck"/>
      <xsl:variable name="level-number">
        <xsl:call-template name="level-count"/>
      </xsl:variable>
      <!-- h2, h3, etc... -->
      <xsl:element name="h{$level-number}">
        <xsl:attribute name="class">section-header</xsl:attribute>
        <xsl:variable name="labeled-exercise" select="(parent::cnx:problem or parent::cnx:solution) and                                                        not(cnx:label[not(node())])"/>
        <xsl:if test="cnx:label[node()] or $labeled-exercise">
          <span class="cnx_label">
            <xsl:apply-templates select="cnx:label"/>
            <xsl:if test="cnx:label[node()] and (cnx:title[node()] and not($labeled-exercise))">
              <xsl:text>: </xsl:text>
            </xsl:if>
	    <xsl:if test="$labeled-exercise">
	      <xsl:number level="any" count="cnx:exercise" format="1."/>
              <xsl:number level="single" format="a) "/>
	    </xsl:if>
          </span>
        </xsl:if>
        <!-- for cnxml version 0.1 -->
        <xsl:if test="@name">
          <strong class="title">
            <xsl:value-of select="@name"/>
            <xsl:if test="@name=''">
              <xsl:text> </xsl:text>
            </xsl:if>
          </strong>
        </xsl:if>
        <!-- for all other cnxml versions -->
	<xsl:apply-templates select="cnx:name|cnx:title"/>
        <xsl:if test="not(cnx:name|cnx:title)">
          <xsl:text> </xsl:text>
        </xsl:if>
      </xsl:element>
      <div class="section-contents">
        <xsl:apply-templates select="*[not(self::cnx:label|self::cnx:name|self::cnx:title)]"/>
      </div>
    </div>
  </xsl:template>

  <!--CONTENT-->
  <xsl:template match="cnx:content">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="cnx:name[not(node())]|cnx:title[not(node())]|cnx:link[@src or @url][not(node())]|cnx:emphasis[not(node())]|cnx:important[not(node())]|cnx:quote[not(node())]|cnx:foreign[not(node())]|cnx:codeline[not(node())]|cnx:code[(@display='inline' or @type='inline') and not(node())]|cnx:codeblock[not(node())]|cnx:term[not(node())]|cnx:meaning[not(node())]|cnx:span[not(node())]|cnx:div[not(node())]|cnx:preformat[not(node())]|cnx:sup[not(node())]|cnx:sub[not(node())]">
    <xsl:comment>empty <xsl:value-of select="local-name()"/> tag</xsl:comment>
  </xsl:template>

  <!--NAME/TITLE -->
  <xsl:template match="cnx:name|cnx:title">
    <xsl:if test="not(parent::*[self::cnx:module|self::cnx:document])">
      <strong class="title">
	<xsl:call-template name="IdCheck"/>
	<xsl:apply-templates/>
        <xsl:if test="parent::cnx:meaning or                        parent::cnx:note or                        parent::cnx:item[parent::cnx:list[not(@type='named-item')]] or                        parent::cnx:list[(@type='inline' and $version='0.5') or @display='inline']">
          <xsl:text>: </xsl:text>
        </xsl:if>
        <xsl:if test="parent::cnx:item[parent::cnx:list[@type='named-item' and $version='0.5']]">
          <xsl:choose>
            <xsl:when test="parent::cnx:item[parent::cnx:list/processing-instruction('mark')[string-length(normalize-space(.)) &gt; 0]]">
              <xsl:value-of select="parent::cnx:item/parent::cnx:list/processing-instruction('mark')"/>
            </xsl:when>
            <xsl:when test="parent::cnx:item[parent::cnx:list/processing-instruction('mark')]"/>
            <xsl:otherwise>
              <xsl:text>:</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text> </xsl:text>
        </xsl:if>
      </strong>
    </xsl:if>
  </xsl:template>

  <!--LABEL-->
  <xsl:template match="cnx:label">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="cnx:label[parent::cnx:item[parent::cnx:list[not(@list-type='labeled-item')]]][node()]">
    <strong class="cnx_label">
      <xsl:apply-templates/>
      <xsl:text>: </xsl:text>
    </strong>
  </xsl:template>

  <!--PARA-->
  <xsl:template match="cnx:para">
    <xsl:if test="cnx:name[node()] or cnx:title[node()]">
      <xsl:variable name="level-number">
        <xsl:call-template name="level-count"/>
      </xsl:variable>
      <!-- h2, h3, etc... -->
      <xsl:element name="h{$level-number}">
        <xsl:attribute name="class">para-header</xsl:attribute>
        <xsl:apply-templates select="cnx:name|cnx:title"/>
      </xsl:element>
    </xsl:if>
    <p class="para">
      <xsl:call-template name="IdCheck"/>
      <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title)]|text()"/>
      <xsl:if test="not(node())">
	<xsl:comment>empty para tag</xsl:comment>
      </xsl:if>
    </p>
  </xsl:template>

  <!--DIV-->
  <xsl:template match="cnx:div">
    <div class="div">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:title[node()]">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">div-header</xsl:attribute>
          <xsl:apply-templates select="cnx:title"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::cnx:title)]|text()"/>
    </div>
  </xsl:template>

  <!-- LINK and CNXN (cnxml version 0.5 and before) -->
  <xsl:template match="cnx:link|cnx:cnxn">
    <a>
      <xsl:call-template name="IdCheck"/>
      <xsl:call-template name="link-attributes"/>
      <xsl:call-template name="link-text"/>
    </a>
  </xsl:template>

  <!-- Common link attributes: @strength, @window, href -->
  <xsl:template name="link-attributes">
    <xsl:if test="@strength">
      <xsl:attribute name="title">
        <!--Strength-->
        <xsl:call-template name="gentext">
          <xsl:with-param name="key">Strength</xsl:with-param>
          <xsl:with-param name="lang" select="/module/metadata/language"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
        <xsl:value-of select="@strength"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="@window='new'">
      <xsl:attribute name="target">_blank</xsl:attribute>
    </xsl:if>
    <xsl:attribute name="class">
      <xsl:choose>
        <xsl:when test="@url or (@src and not(starts-with(@src,'#')))">link</xsl:when>
        <xsl:otherwise>cnxn</xsl:otherwise>
      </xsl:choose>
      <xsl:if test="@window='new'">
        <xsl:text> newwindow</xsl:text>
      </xsl:if>
    </xsl:attribute>
    <xsl:attribute name="href">
      <xsl:call-template name="make-href"/>
    </xsl:attribute>
  </xsl:template>
     
  <!-- Construct an href -->
  <xsl:template name="make-href">
    <xsl:choose>
      <xsl:when test="@url[normalize-space()!=''] or @src[normalize-space()!='']">
        <xsl:value-of select="@url|@src"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="target" select="@target[normalize-space()!='']|@target-id[normalize-space()!='']"/>
        <xsl:variable name="document" select="normalize-space(@document[normalize-space()!=''])"/>
        <xsl:variable name="module" select="normalize-space(@module[normalize-space()!=''])"/>
        <xsl:variable name="doc-version" select="normalize-space(@version[normalize-space()!=''])"/>
        <xsl:choose>
          <xsl:when test="not($document) and not($module) and not($doc-version)"/>
          <xsl:when test="not($document) and not($module) and $doc-version">
            <xsl:text>../</xsl:text>
            <xsl:value-of select="$doc-version"/>
            <xsl:text>/</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>/content/</xsl:text>
            <xsl:value-of select="$document"/>
            <xsl:value-of select="$module"/>
            <xsl:text>/</xsl:text>
            <xsl:choose>
              <xsl:when test="$doc-version">
                <xsl:value-of select="$doc-version"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>latest</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text>/</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="normalize-space(@resource)"/>
        <xsl:if test="$target">
          <xsl:text>#</xsl:text>
          <xsl:value-of select="normalize-space($target)"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Provide the link/cnxn text if it's empty -->
  <xsl:template name="link-text">
    <xsl:variable name="target" select="@target[normalize-space()!='']|@target-id[normalize-space()!='']"/>
    <xsl:choose>
      <xsl:when test="node()">
        <xsl:apply-templates/>
      </xsl:when>
      <xsl:when test="key('id',normalize-space($target)) and not(@document[normalize-space()!=''] or                                                                   @module[normalize-space()!=''] or                                                                   @version[normalize-space()!='']                                                                 )">
        <span class="cnxn-target">
          <xsl:for-each select="key('id', normalize-space($target))">
            <!--<xsl:value-of select="local-name(key('id',$target))" />-->
            <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
            <xsl:choose>
              <xsl:when test="self::bib:entry" />
              <xsl:when test="cnx:label[node()]">
                <xsl:apply-templates select="cnx:label"/>
              </xsl:when>
              <xsl:when test="(self::cnx:note[@type!=''] or self::cnx:rule[@type!='']) and $version='0.5'">
                <xsl:value-of select="@type"/>
              </xsl:when>
              <xsl:when test="(self::cnx:note and ($type='note' or                                                     $type='warning' or                                                     $type='important' or                                                     $type='aside' or                                                     $type='tip')) or                                (self::cnx:rule and ($type='rule' or                                                     $type='theorem' or                                                     $type='lemma' or                                                     $type='corollary' or                                                     $type='law' or                                                     $type='proposition'))">
                <xsl:call-template name="gentext">
                  <xsl:with-param name="key" select="$type"/>
                  <xsl:with-param name="lang" select="/module/metadata/language"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="self::cnx:exercise[ancestor::cnx:example or qml:item] or self::qml:item">
                <xsl:call-template name="gentext">
                  <xsl:with-param name="key">Problem</xsl:with-param>
                  <xsl:with-param name="lang" select="/module/metadata/language"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="self::cnx:problem[not(parent::cnx:exercise[ancestor::cnx:example])]">
                <xsl:call-template name="gentext">
                  <xsl:with-param name="key">Exercise</xsl:with-param>
                  <xsl:with-param name="lang" select="/module/metadata/language"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:when test="self::cnx:subfigure">
                <xsl:call-template name="gentext">
                  <xsl:with-param name="key">Figure</xsl:with-param>
                  <xsl:with-param name="lang" select="/module/metadata/language"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="gentext">
                  <xsl:with-param name="key" select="local-name()"/>
                  <xsl:with-param name="lang" select="/module/metadata/language"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="not(self::cnx:example[ancestor::cnx:definition or                                                 ancestor::cnx:rule or                                                 ancestor::cnx:exercise or                                                 ancestor::cnx:entry or                                                 ancestor::cnx:footnote or                                                 ancestor::cnx:text or                                                 ancestor::cnx:longdesc])">
            <xsl:choose>
              <xsl:when test="self::bib:entry">[</xsl:when>
              <xsl:otherwise>
                <xsl:text> </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="self::cnx:note and ($type='note' or not(@type))">
                <xsl:number level="any" count="cnx:note[translate(@type,$upper,$lower)='note' or not(@type)]"/>
              </xsl:when>
              <xsl:when test="self::cnx:rule[@type='rule' or not(@type)]">
                <xsl:number level="any" count="cnx:rule[translate(@type,$upper,$lower)='rule' or not(@type)]"/>
              </xsl:when>
              <xsl:when test="self::qml:item">
                <xsl:number level="any" count="qml:item"/>
              </xsl:when>
              <xsl:when test="@type=local-name()">
                <xsl:variable name="element" select="name()"/>
                <xsl:number level="any" count="*[name()=$element][translate(@type,$upper,$lower)=$type or not(@type)]"/>
              </xsl:when>
              <xsl:when test="@type and (not($version='0.5') or self::cnx:rule or self::cnx:note)">
                <xsl:variable name="element" select="name()"/>
                <xsl:number level="any" count="*[name()=$element][translate(@type,$upper,$lower)=$type]"/>
              </xsl:when>
              <xsl:when test="self::cnx:subfigure">
                <xsl:variable name="figure-type" select="translate(parent::cnx:figure/@type,$upper,$lower)"/>
                <xsl:choose>
                  <xsl:when test="parent::cnx:figure/@type and $figure-type!='figure'">
                    <xsl:number level="any" count="cnx:figure[translate(@type,$upper,$lower)=$figure-type]"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:number level="any" count="cnx:figure[not(@type) or translate(@type,$upper,$lower)=$figure-type]"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:number format="(a)" count="cnx:subfigure[not(@type) or translate(@type,$upper,$lower)='subfigure']"/>
              </xsl:when>
              <xsl:when test="self::cnx:solution or self::cnx:problem">
                <xsl:variable name="exercise-type" select="translate(parent::cnx:exercise/@type,$upper,$lower)"/>
                <xsl:choose>
                  <xsl:when test="parent::cnx:exercise/@type and $exercise-type!='exercise'">
                    <xsl:number level="any" count="cnx:exercise[translate(@type,$upper,$lower)=$exercise-type]"/>
                  </xsl:when>
                  <xsl:when test="parent::cnx:exercise[ancestor::cnx:example]">
                    <xsl:number level="any" from="cnx:example" count="cnx:exercise[not(@type) or translate(@type,$upper,$lower)='exercise']"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:number level="any" count="cnx:exercise[not(ancestor::cnx:example|qml:item)][not(@type) or translate(@type,$upper,$lower)='exercise']"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="self::cnx:solution and count(parent::cnx:exercise/cnx:solution) &gt; 1">
                  <xsl:text>.</xsl:text>
                  <xsl:number format="A" count="cnx:solution[not(@type) or translate(@type,$upper,$lower)='solution']"/>
                </xsl:if>
              </xsl:when>
              <xsl:when test="self::cnx:exercise">
                <xsl:choose>
                  <xsl:when test="ancestor::cnx:example">
                    <xsl:number level="any" from="cnx:example" count="cnx:exercise[not(@type) or translate(@type,$upper,$lower)='exercise']"/>
                  </xsl:when>
                  <xsl:when test="qml:item">
                    <xsl:number level="any" count="cnx:exercise[qml:item]"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:number level="any" count="cnx:exercise[not(ancestor::cnx:example|qml:item)][not(@type) or translate(@type,$upper,$lower)='exercise']"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:when test="self::cnx:example">
                <xsl:number level="any" count="cnx:example[not(ancestor::cnx:definition or                                                    ancestor::cnx:rule or                                                    ancestor::cnx:exercise or                                                    ancestor::cnx:entry or                                                    ancestor::cnx:footnote or                                                    ancestor::cnx:text or                                                    ancestor::cnx:longdesc) and                                                (not(@type) or translate(@type,$upper,$lower)='example')]"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="element" select="name()"/>
                <xsl:choose>
                  <xsl:when test="$version='0.5'">
                    <xsl:number level="any" count="*[name()=$element]"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:number level="any" count="*[name()=$element][not(@type) or translate(@type,$upper,$lower)=$element]"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="self::bib:entry">]</xsl:if>
            </xsl:if>
          </xsl:for-each>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>(</xsl:text>
        <!-- Reference -->
        <xsl:call-template name="gentext">
          <xsl:with-param name="key">Reference</xsl:with-param>
          <xsl:with-param name="lang" select="/module/metadata/language"/>
        </xsl:call-template>
        <xsl:text>)</xsl:text>        
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="solution-test">
    <xsl:if test="self::cnx:solution">
      <xsl:if test="count(parent::cnx:exercise/cnx:solution) &gt; 1">
        <xsl:text>, </xsl:text>
      </xsl:if>
      <!-- Solution -->
      <xsl:call-template name="gentext">
        <xsl:with-param name="key">Solution</xsl:with-param>
        <xsl:with-param name="lang" select="/module/metadata/language"/>
      </xsl:call-template>
      <xsl:if test="count(parent::cnx:exercise/cnx:solution) &gt; 1">
         <xsl:text> </xsl:text>
         <xsl:number format="A"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!--SPAN-->
  <xsl:template match="cnx:span">
    <xsl:variable name="span-element">
      <xsl:choose>
        <xsl:when test="@effect='bold'">b</xsl:when>
        <xsl:when test="@effect='italics'">i</xsl:when>
        <xsl:when test="@effect='underline'">u</xsl:when>
        <xsl:otherwise>span</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$span-element}">
      <xsl:call-template name="IdCheck"/>
      <xsl:attribute name="class">
        <xsl:text>span</xsl:text>
        <xsl:if test="@effect='normal' or @effect='smallcaps'">
          <xsl:text> </xsl:text>
          <xsl:value-of select="@effect"/>
        </xsl:if>
      </xsl:attribute>
      <xsl:apply-templates/>      
    </xsl:element>
  </xsl:template>

  <!--EMPHASIS-->
  <xsl:template match="cnx:emphasis">
    <xsl:variable name="emphasis-element">
      <xsl:choose>
        <xsl:when test="@effect='bold'">b</xsl:when>
        <xsl:when test="@effect='italics'">i</xsl:when>
        <xsl:when test="@effect='underline'">u</xsl:when>
        <xsl:when test="@effect='normal' or @effect='smallcaps'">span</xsl:when>
        <xsl:otherwise>em</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$emphasis-element}">
      <xsl:call-template name="IdCheck"/>
      <xsl:attribute name="class">
        <xsl:text>emphasis</xsl:text>
        <xsl:if test="@effect='normal' or @effect='smallcaps'">
          <xsl:text> </xsl:text>
          <xsl:value-of select="@effect"/>
        </xsl:if>
      </xsl:attribute>
      <xsl:apply-templates/>      
    </xsl:element>
  </xsl:template>

  <!--IMPORTANT-->
  <xsl:template match="cnx:important">
    <strong class="important">
      <xsl:call-template name="IdCheck"/>
      <xsl:apply-templates/>
    </strong>
  </xsl:template>

  <!-- QUOTE -->
  <xsl:template match="cnx:quote">
    <xsl:if test="cnx:title or cnx:label[node()]">
      <xsl:choose>
        <xsl:when test="@display='inline'">
          <xsl:if test="cnx:label[node()]">
            <span class="cnx_label">
              <xsl:apply-templates select="cnx:label"/>
              <xsl:text>: </xsl:text>
            </span>
          </xsl:if>
          <xsl:apply-templates select="cnx:title"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="level-number">
            <xsl:call-template name="level-count"/>
          </xsl:variable>
          <!-- h2, h3, etc... -->
          <xsl:element name="h{$level-number}">
            <xsl:attribute name="class">quote-header</xsl:attribute>
            <xsl:if test="cnx:label[node()]">
              <span class="cnx_label">
                <xsl:apply-templates select="cnx:label"/>
                <xsl:if test="cnx:title">: </xsl:if>
              </span>
            </xsl:if>
            <xsl:apply-templates select="cnx:title"/>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:call-template name="make-quote">
      <xsl:with-param name="display">
        <xsl:choose>
          <xsl:when test="$version='0.5'">
            <xsl:choose>
              <xsl:when test="@type='block'">block</xsl:when>
              <xsl:otherwise>inline</xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <!-- CNXML 0.6 and EiP cases -->
          <xsl:when test="@display='inline'">inline</xsl:when>
          <xsl:otherwise>block</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="make-quote">
    <xsl:param name="display">block</xsl:param>
    <xsl:variable name="element-name">
      <xsl:choose>
        <xsl:when test="$display='block'">blockquote</xsl:when>
        <xsl:otherwise>span</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="href">
      <xsl:call-template name="make-href"/>
    </xsl:variable>
    <xsl:element name="{$element-name}">
      <xsl:call-template name="IdCheck"/>
      <xsl:attribute name="class">
        <xsl:text>quote</xsl:text>
        <xsl:if test="$display='inline'">
          <xsl:text> inline</xsl:text>
        </xsl:if>
      </xsl:attribute>
      <xsl:if test="@display='none'">
        <xsl:attribute name="style">display: none</xsl:attribute>
      </xsl:if>
      <xsl:if test="$href!='' and $display='block'">
        <xsl:attribute name="cite">
          <xsl:value-of select="$href"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:variable name="no-marks">
        <xsl:call-template name="class-test">
          <xsl:with-param name="provided-class" select="normalize-space(@class)"/>
          <xsl:with-param name="wanted-class">no-marks</xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:if test="not($version='0.5') and $display='inline' and $no-marks!='1'">
        <xsl:text>“</xsl:text>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::cnx:title|self::cnx:label)]|text()"/>
      <xsl:if test="not($version='0.5') and $display='inline' and $no-marks!='1'">
        <xsl:text>”</xsl:text>
      </xsl:if>
      <xsl:if test="$href!=''">
        <span class="quote-source">
          <xsl:text>[</xsl:text>
          <a>
            <xsl:call-template name="link-attributes"/>
            <xsl:text>source</xsl:text>
          </a>
          <xsl:text>]</xsl:text>
        </span>
      </xsl:if>
    </xsl:element>
  </xsl:template>

  <!-- SUP and SUB -->
  <xsl:template match="cnx:sup|cnx:sub">
    <xsl:element name="{local-name()}">
      <xsl:call-template name="IdCheck"/>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- FOREIGN -->
  <xsl:template match="cnx:foreign">
    <span class="foreign">
      <xsl:call-template name="IdCheck"/>
      <xsl:choose>
        <xsl:when test="@url[normalize-space()!=''] or                          @document[normalize-space()!=''] or                          @version[normalize-space()!=''] or                          @resource[normalize-space()!=''] or                          @target-id[normalize-space()!='']">
          <a>
            <xsl:call-template name="link-attributes"/>
            <xsl:apply-templates/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </span>
  </xsl:template>

  <!-- CODE -->
  <xsl:template match="cnx:code">
    <xsl:choose>
      <xsl:when test="$version ='0.5'">
        <xsl:choose>
          <xsl:when test="@type='block'">
            <xsl:call-template name="codeblock"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="codeline"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- CNXML 0.6 and EiP cases -->
      <xsl:when test="@display='block'">
        <xsl:call-template name="codeblock"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="codeline"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- CODELINE -->
  <xsl:template match="cnx:codeline">
    <xsl:call-template name="codeline"/>
  </xsl:template>

  <!-- CODEBLOCK -->
  <xsl:template match="cnx:codeblock">
    <xsl:call-template name="codeblock"/>
  </xsl:template>

  <xsl:template name="codeline">
    <code class="codeline">
      <xsl:if test="@display='none'">
        <xsl:attribute name="style">display: none</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="IdCheck"/>
      <xsl:apply-templates/>
    </code>
  </xsl:template>

  <xsl:template name="codeblock">
    <div class="code">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:title or cnx:label[node()]">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">code-header</xsl:attribute>
          <xsl:if test="cnx:label">
            <span class="cnx_label">
              <xsl:apply-templates select="cnx:label"/>
            </span>
            <xsl:if test="cnx:title">
              <xsl:text>: </xsl:text>
            </xsl:if>
          </xsl:if>
          <xsl:apply-templates select="cnx:title"/>
        </xsl:element>
      </xsl:if>
      <pre class="codeblock">
        <code>
          <xsl:apply-templates select="*[not(self::cnx:title|self::cnx:label|self::cnx:caption)]|text()"/>
          <xsl:if test="not(node())">
            <xsl:comment>empty code tag</xsl:comment>
          </xsl:if>
        </code>
      </pre>
      <xsl:if test="cnx:caption">
        <p class="code-caption caption">
          <xsl:if test="cnx:caption[@id]">
            <xsl:attribute name="id">
              <xsl:value-of select="cnx:caption/@id"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="cnx:caption"/>
        </p>
      </xsl:if>
    </div>
  </xsl:template>

  <!-- CODE with class="listing" -->
  <xsl:template match="cnx:code[@class='listing']">
    <div class="code">
      <xsl:call-template name="IdCheck"/>
      <table border="0" cellpadding="0" cellspacing="0" align="center" width="50%">
        <xsl:if test="cnx:caption or not(cnx:label[not(node())])">
          <caption align="bottom" class="code-caption caption">
            <xsl:if test="cnx:caption[@id]">
              <xsl:attribute name="id">
                <xsl:value-of select="cnx:caption/@id"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:if test="not(cnx:label[not(node())])">
              <strong class="cnx_label">
                <xsl:choose>
                  <xsl:when test="cnx:label">
                    <xsl:apply-templates select="cnx:label"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <!-- Listing -->
                    <xsl:call-template name="gentext">
                      <xsl:with-param name="key">Listing</xsl:with-param>
                      <xsl:with-param name="lang" select="/module/metadata/language"/>
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:text> </xsl:text>
                <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
                <xsl:choose>
                  <xsl:when test="@type and $type!='code'">
                    <xsl:number level="any" count="cnx:code[@class='listing'][translate(@type,$upper,$lower)=$type]"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:number level="any" count="cnx:code[@class='listing'][not(@type) or translate(@type,$upper,$lower)='code']"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="cnx:caption">
                  <xsl:text>: </xsl:text>
                </xsl:if>
              </strong>
            </xsl:if>
            <xsl:apply-templates select="cnx:caption"/>
          </caption>
        </xsl:if>
        <xsl:if test="cnx:title[node()]">
          <thead>
            <tr>
              <th class="code-title">
                <xsl:apply-templates select="cnx:title"/>
              </th>
            </tr>
          </thead>
        </xsl:if>
        <tbody>
          <tr>
            <td>
              <pre class="codeblock">
                <code>
                  <xsl:apply-templates select="*[not(self::cnx:caption|self::cnx:title|self::cnx:label)]|text()"/>
                </code>
              </pre>
	    </td>
          </tr>
        </tbody>
      </table>
    </div>
  </xsl:template>
  
  <!-- PREFORMAT -->
  <xsl:template match="cnx:preformat">
    <xsl:choose>
      <xsl:when test="@display='inline'">
        <span class="preformat">
          <xsl:call-template name="IdCheck"/>
          <xsl:apply-templates/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <div class="preformat">
          <xsl:call-template name="IdCheck"/>
          <xsl:apply-templates select="cnx:title"/>
          <pre class="preformatted">
            <xsl:if test="@display='none'">
              <xsl:attribute name="style">display: none</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="*[not(self::cnx:title)]|text()"/>
          </pre>
        </div>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- NEWLINE and SPACE -->
  <xsl:template match="cnx:newline|cnx:space">
    <xsl:variable name="blank-element">
      <xsl:choose>
        <xsl:when test="self::cnx:space">pre</xsl:when>
        <xsl:otherwise>span</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$blank-element}">
      <xsl:call-template name="IdCheck"/>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name()"/>
        <xsl:if test="@effect='underline'">
          <xsl:text> underline</xsl:text>
        </xsl:if>
      </xsl:attribute>
      <xsl:call-template name="loop">
        <xsl:with-param name="name">
          <xsl:value-of select="local-name()"/>
          <xsl:if test="@effect='underline'">
            <xsl:text>underline</xsl:text>
          </xsl:if>
        </xsl:with-param>
        <xsl:with-param name="count">
          <xsl:choose>
            <xsl:when test="@count">
              <xsl:value-of select="@count"/>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

  <!-- Loop through the code based on the value of the @count attribute -->
  <xsl:template name="loop">
    <xsl:param name="name">newline</xsl:param>
    <xsl:param name="count">1</xsl:param>
    <xsl:choose>
      <xsl:when test="$count = '0'"/>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$name='newline'"><br/></xsl:when>
          <xsl:when test="$name='newlineunderline'"><hr/></xsl:when>
          <xsl:when test="contains($name,'space')"><xsl:text> </xsl:text></xsl:when>
        </xsl:choose>
        <xsl:call-template name="loop">
          <xsl:with-param name="name" select="$name"/>
          <xsl:with-param name="count" select="$count - 1"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- NOTE -->
  <xsl:template match="cnx:note">
    <xsl:choose>
      <xsl:when test="$version='0.5'">
        <xsl:choose>
          <xsl:when test="translate(@type,$upper,$lower)='footnote'">
            <xsl:call-template name="make-footnote"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="make-block-note"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- CNXML 0.6 and EiP cases -->
      <xsl:when test="@display='inline'">
        <xsl:call-template name="make-inline-note"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="make-block-note"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- FOOTNOTE -->
  <xsl:template match="cnx:footnote">
    <xsl:call-template name="make-footnote"/>
  </xsl:template>

  <!-- Footnote -->
  <xsl:template name="make-footnote">
    <xsl:variable name="footnote-number">
      <xsl:number level="any" count="//cnx:note[translate(@type,$upper,$lower)='footnote']|//cnx:footnote" format="1"/>
    </xsl:variable>
    <a class="footnote-reference" href="#footnote{$footnote-number}">
      <xsl:value-of select="$footnote-number"/>
    </a>
    <xsl:if test="following-sibling::node()[normalize-space()!=''][1][self::cnx:note[translate(@type,$upper,$lower)='footnote'] or self::cnx:footnote]">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- Block note -->
  <xsl:template name="make-block-note">
    <div>
      <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
      <xsl:attribute name="class">
        <xsl:text>note</xsl:text>
        <xsl:if test="$type = 'tip' or $type = 'concept-check'">
          <xsl:text> </xsl:text>
          <xsl:value-of select="$type"/>
        </xsl:if>
      </xsl:attribute>
      <xsl:if test="@display='none'">
        <xsl:attribute name="style">display: none</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:title or cnx:label[node()] or ((@type!='' or not(@type)) and not(cnx:label))">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">note-header</xsl:attribute>
          <xsl:call-template name="note-label"/>
        </xsl:element>
      </xsl:if>
      <div class="note-contents">
        <xsl:apply-templates select="*[not(self::cnx:label|self::cnx:title)]|text()"/>
      </div>
    </div>
  </xsl:template>

  <!-- Inline note -->
  <xsl:template name="make-inline-note">
    <span class="note inline">
      <xsl:call-template name="IdCheck"/>
      <xsl:call-template name="note-label"/>
      <xsl:apply-templates select="*[not(self::cnx:label|self::cnx:title)]|text()"/>
    </span>
  </xsl:template>

  <!-- Builds a label and puts a name in for inline and regular notes -->
  <xsl:template name="note-label">
    <xsl:if test="cnx:label[node()] or ((@type!='' or not(@type)) and not(cnx:label))">
      <span class="cnx_label">
        <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
        <xsl:choose>
          <xsl:when test="cnx:label">
            <xsl:apply-templates select="cnx:label"/>
          </xsl:when>
          <xsl:when test="$type='warning' or $type='important' or $type='aside' or $type='tip'">
            <xsl:call-template name="gentext">
              <xsl:with-param name="key" select="$type"/>
              <xsl:with-param name="lang" select="/module/metadata/language"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="$version='0.5' and @type">
            <xsl:value-of select="@type"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- Note -->
            <xsl:call-template name="gentext">
              <xsl:with-param name="key">Note</xsl:with-param>
              <xsl:with-param name="lang" select="/module/metadata/language"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>: </xsl:text>
      </span>
    </xsl:if>
    <xsl:apply-templates select="cnx:title"/>
  </xsl:template>

  <!--EXAMPLE-->
  <xsl:template match="cnx:example">
    <div class="example">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:name or cnx:title or not(cnx:label[not(node())])">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">example-header</xsl:attribute>
          <xsl:if test="not(cnx:label[not(node())])">
            <span class="cnx_label">
              <xsl:choose>
                <xsl:when test="cnx:label">
                  <xsl:apply-templates select="cnx:label"/>
                </xsl:when>
                <xsl:otherwise>
                  <!-- Example -->
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key">Example</xsl:with-param>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="not(ancestor::cnx:definition or                                 ancestor::cnx:rule or                                 ancestor::cnx:exercise or                                  ancestor::cnx:entry or                                 ancestor::cnx:footnote or                                  ancestor::cnx:text or                                 ancestor::cnx:longdesc)">
                <xsl:text> </xsl:text>
                <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
                <xsl:choose>
                  <xsl:when test="@type and $type!='example'">
                    <xsl:number level="any" count="cnx:example[not(ancestor::cnx:definition or                                                        ancestor::cnx:rule or                                                        ancestor::cnx:exercise or                                                        ancestor::cnx:entry or                                                        ancestor::cnx:footnote or                                                        ancestor::cnx:text or                                                        ancestor::cnx:longdesc)][translate(@type,$upper,$lower)=$type]"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:number level="any" count="cnx:example[not(ancestor::cnx:definition or                                                         ancestor::cnx:rule or                                                         ancestor::cnx:exercise or                                                         ancestor::cnx:entry or                                                         ancestor::cnx:footnote or                                                         ancestor::cnx:text or                                                         ancestor::cnx:longdesc)][not(@type) or translate(@type,$upper,$lower)='example']"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>
              <xsl:if test="cnx:name or cnx:title or ancestor::cnx:glossary">: </xsl:if>
            </span>
          </xsl:if>
          <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <div class="example-contents">
        <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title|self::cnx:label)]"/>
      </div>
    </div>
  </xsl:template>

  <!--DEFINITION-->
  <xsl:template match="cnx:definition">
    <dl>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="parent::cnx:glossary">definition glossary</xsl:when>
          <xsl:otherwise>definition</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:call-template name="IdCheck"/>
      <dt>
        <xsl:if test="not(parent::cnx:glossary) and not(cnx:label[not(node())])">
          <span class="cnx_label">
            <xsl:choose>
              <xsl:when test="cnx:label">
                <xsl:apply-templates select="cnx:label"/>
              </xsl:when>
              <xsl:otherwise>
                <!-- Definition -->
                <xsl:call-template name="gentext">
                  <xsl:with-param name="key">Definition</xsl:with-param>
                  <xsl:with-param name="lang" select="/module/metadata/language"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text> </xsl:text>
            <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
            <xsl:choose>
              <xsl:when test="@type and $type!='definition'">
                <xsl:number level="any" count="cnx:definition[translate(@type,$upper,$lower)=$type]"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:number level="any" count="cnx:definition[not(@type) or translate(@type,$upper,$lower)='definition']"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text>: </xsl:text>
          </span>
        </xsl:if>
        <xsl:apply-templates select="cnx:term"/>
      </dt>
      <xsl:for-each select="cnx:meaning">
        <dd>
          <xsl:apply-templates select=".|../cnx:example[generate-id(preceding-sibling::cnx:meaning[1]) = generate-id(current())]"/>
        </dd>
      </xsl:for-each>
      <xsl:apply-templates select="cnx:seealso"/>
    </dl>
  </xsl:template>

  <!--TERM-->
  <xsl:template match="cnx:term">
    <xsl:choose>
      <xsl:when test="ancestor::cnx:document/cnx:glossary/cnx:definition[@id=substring(current()/@src,2) or @id=current()/@target-id]">
        <span class="lensinfowrap">
          <dfn class="term">
            <xsl:call-template name="IdCheck"/>
            <a class="hovlink" onmouseover="createDefinition(this)" onmouseout="removeDefinition(this)">
              <xsl:attribute name="href">
                <xsl:choose>
                  <xsl:when test="@src">
                    <xsl:value-of select="@src"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text>#</xsl:text>
                    <xsl:value-of select="@target-id"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
              <xsl:apply-templates/>
            </a>
          </dfn>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <dfn class="term">
          <xsl:call-template name="IdCheck"/>
          <xsl:choose>
            <xsl:when test="@src">
              <a href="{@src}">
                <xsl:apply-templates/>
              </a>
            </xsl:when>
            <xsl:when test="@url[normalize-space()!=''] or                              @document[normalize-space()!=''] or                              @version[normalize-space()!=''] or                              @resource[normalize-space()!=''] or                              @target-id[normalize-space()!='']">
              <a>
                <xsl:call-template name="link-attributes"/>
                <xsl:apply-templates/>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="ancestor::cnx:glossary and parent::cnx:definition">
            <xsl:text>:</xsl:text>
          </xsl:if>
        </dfn>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- SEEALSO -->
  <xsl:template match="cnx:seealso">
    <dd class="seealso">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="not(cnx:label[not(node())])">
        <span class="cnx_label">
          <xsl:choose>
            <xsl:when test="cnx:label">
              <xsl:apply-templates select="cnx:label"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- See Also: -->
              <xsl:call-template name="gentext">
                <xsl:with-param name="key">GlossSeeAlso</xsl:with-param>
                <xsl:with-param name="lang" select="/module/metadata/language"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:text>: </xsl:text>
        </span>
      </xsl:if>
      <xsl:for-each select="cnx:term">
        <xsl:apply-templates select="."/>
        <xsl:if test="position()!=last()">, </xsl:if>
      </xsl:for-each>
    </dd>
  </xsl:template>
  
  <!--CITE-->
  <xsl:template match="cnx:cite">
    <xsl:variable name="href">
      <xsl:call-template name="make-href"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$href='' and not(node())">
        <xsl:comment>empty cite tag</xsl:comment>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="src" select="@src[normalize-space()!='']"/>
        <xsl:variable name="target-id" select="@target-id[normalize-space()!='']"/>
        <xsl:variable name="target" select="concat(substring-after($src,'#'),$target-id)"/>
        <xsl:variable name="url" select="@url[normalize-space()!='']"/>
        <xsl:variable name="bibentry" select="(starts-with($src,'#') or (concat('#',$target-id) = $href)) and                                               name(key('id',$target))='bib:entry'"/>
        <cite class="cite">
          <xsl:call-template name="IdCheck"/>
          <xsl:if test="not($bibentry)">
            <xsl:choose>
              <xsl:when test="$version='0.5'">
                <span class="cite-title">
                  <i>
                    <xsl:apply-templates/>
                  </i>
                </span>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="$href!=''">
              <xsl:text> </xsl:text>
            </xsl:if>
          </xsl:if>
          <xsl:if test="$href!='' and not($bibentry and node())">
            <xsl:text>[</xsl:text>
          </xsl:if>
          <xsl:if test="$href!=''">
            <a>
              <xsl:call-template name="link-attributes"/>
              <xsl:choose>
                <xsl:when test="$bibentry">
                  <xsl:choose>
                    <xsl:when test="node()">
                      <xsl:apply-templates/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:for-each select="key('id',$target)">
                        <xsl:number level="any" count="//bib:entry"/>
                      </xsl:for-each>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <!-- link -->
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key">citelink</xsl:with-param>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </a>
          </xsl:if>
          <xsl:if test="$href!='' and not($bibentry and node())">
            <xsl:text>]</xsl:text>
          </xsl:if>
        </cite>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- CITE-TITLE -->
  <xsl:template match="cnx:cite-title">
    <span class="cite-title">
      <xsl:choose>
        <xsl:when test="@pub-type='article' or                          @pub-type='inbook' or                          @pub-type='incollection' or                          @pub-type='inproceedings' or                          @pub-type='misc' or                          @pub-type='unpublished'">
          "<xsl:apply-templates/>"
        </xsl:when>
        <xsl:otherwise>
          <i><xsl:apply-templates/></i>
        </xsl:otherwise>
      </xsl:choose>
    </span>
  </xsl:template>

  <!--MEANING-->
  <xsl:template match="cnx:meaning">
    <div class="meaning">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="count(parent::cnx:definition/cnx:meaning) &gt; 1"> 
        <span class="cnx_label">
          <xsl:number level="single"/>. 
        </span>
      </xsl:if>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- RULE -->
  <xsl:template match="cnx:rule">
    <div class="rule">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:name or cnx:title or not(cnx:label[not(node())])">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">rule-header</xsl:attribute>
          <xsl:if test="not(cnx:label[not(node())])">
            <span class="cnx_label">
              <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
              <xsl:choose>
                <xsl:when test="cnx:label">
                  <xsl:apply-templates select="cnx:label"/>
                </xsl:when>
                <xsl:when test="$type='theorem' or $type='lemma' or $type='corollary' or $type='law' or $type='proposition'">
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key" select="$type"/>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="$version='0.5'">
                  <xsl:value-of select="@type"/>
                </xsl:when>
                <xsl:otherwise>
                  <!-- Rule -->
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key">Rule</xsl:with-param>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text> </xsl:text>
              <xsl:choose>
                <xsl:when test="$type='rule' or not(@type)">
                  <xsl:number level="any" count="cnx:rule[translate(@type,$upper,$lower)='rule' or not(@type)]"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:number level="any" count="cnx:rule[translate(@type,$upper,$lower)=$type]"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="cnx:name or cnx:title">
                <xsl:text>: </xsl:text>
              </xsl:if>
            </span>
          </xsl:if>
          <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <div class="rule-contents">
        <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title|self::cnx:label)]"/>
      </div>
    </div>
  </xsl:template>

  <!-- STATEMENT -->
  <xsl:template match="cnx:statement">
    <div class="statement">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:name or cnx:title or cnx:label[node()]">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">statement-header</xsl:attribute>
          <xsl:if test="cnx:label[node()]">
            <span class="cnx_label">
              <xsl:apply-templates select="cnx:label"/>
              <xsl:if test="cnx:name or cnx:title">: </xsl:if>
            </span>
          </xsl:if>
          <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title|self::cnx:label)]"/>
    </div>
  </xsl:template>

  <!--PROOF-->
  <xsl:template match="cnx:proof">
    <div class="proof">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:name or cnx:title or not(cnx:label[not(node())])">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">proof-header</xsl:attribute>
          <xsl:if test="not(cnx:label[not(node())])">
            <span class="cnx_label">
              <xsl:choose>
                <xsl:when test="cnx:label">
                  <xsl:apply-templates select="cnx:label"/>
                </xsl:when>
                <xsl:otherwise>
                  <!--Proof-->
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key">Proof</xsl:with-param>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="cnx:name or cnx:title">: </xsl:if>
            </span>
          </xsl:if>
          <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title|self::cnx:label)]"/>
    </div>
  </xsl:template>

  <!-- LIST -->
  <xsl:template match="cnx:list">
    <xsl:choose>
      <xsl:when test="$version='0.5'">
        <xsl:choose>
          <xsl:when test="@type='inline'">
            <xsl:call-template name="make-inline-list"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="make-block-list"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- CNXML 0.6 and EiP cases -->
      <xsl:when test="@display='inline'">
        <xsl:call-template name="make-inline-list"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="make-block-list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--LIST (block)-->
  <xsl:template name="make-block-list">
    <div class="list">
      <xsl:if test="@display='none'">
        <xsl:attribute name="style">display: none</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:name[node()] or cnx:title[node()] or cnx:label[node()]">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">list-header</xsl:attribute>
          <xsl:if test="cnx:label[node()]">
            <span class="cnx_label">
              <xsl:apply-templates select="cnx:label"/>
              <xsl:if test="cnx:title">
                <xsl:text>: </xsl:text>
              </xsl:if>
            </span>
          </xsl:if>
	  <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <xsl:variable name="stepwise">
        <xsl:call-template name="class-test">
          <xsl:with-param name="provided-class" select="normalize-space(@class)"/>
          <xsl:with-param name="wanted-class">stepwise</xsl:with-param>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="list-element">
        <xsl:choose>
          <xsl:when test="@list-type='enumerated' or (@type='enumerated' and $version='0.5')">ol</xsl:when>
          <xsl:otherwise>ul</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:element name="{$list-element}">
        <xsl:attribute name="class">
          <xsl:choose>
            <xsl:when test="@list-type='labeled-item' or (@type='named-item' and $version='0.5')">labeled-item</xsl:when>
            <xsl:when test="@mark-prefix or @mark-suffix or ($stepwise='1' and @list-type='enumerated')">other</xsl:when>
            <xsl:when test="@bullet-style='bullet' or                              (@list-type='bulleted' and not(@bullet-style)) or                              (not(@list-type) and not(@bullet-style))">bullet</xsl:when>
            <xsl:when test="@bullet-style='open-circle'">open-circle</xsl:when>
            <xsl:when test="@number-style='arabic' or (@list-type='enumerated' and not(@number-style))">arabic</xsl:when>
            <xsl:when test="@number-style='upper-alpha'">upper-alpha</xsl:when>
            <xsl:when test="@number-style='lower-alpha'">lower-alpha</xsl:when>
            <xsl:when test="@number-style='upper-roman'">upper-roman</xsl:when>
            <xsl:when test="@number-style='lower-roman'">lower-roman</xsl:when>
            <xsl:otherwise>other</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
        <xsl:for-each select="cnx:item">
          <li class="item">
            <xsl:call-template name="IdCheck"/>
            <xsl:if test="parent::cnx:list[@start-value] and position() = 1">
              <xsl:attribute name="value">
                <xsl:value-of select="parent::cnx:list/@start-value"/>
              </xsl:attribute>
            </xsl:if>
            <xsl:if test="parent::cnx:list[(@bullet-style!='bullet' and @bullet-style!='open-circle' and @bullet-style!='none') or                                             @list-type='labeled-item' or                                             @mark-prefix or                                             @mark-suffix or                                             ($stepwise='1' and @list-type='enumerated')]">
              <xsl:call-template name="item-decoration"/>
            </xsl:if>
            <xsl:call-template name="item-contents"/>
          </li>
        </xsl:for-each>
      </xsl:element>
    </div>
  </xsl:template>
  
  <!--LIST (inline)-->
  <xsl:template name="make-inline-list">
    <xsl:text> </xsl:text>
    <span class="list inline">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:label[node()]">
        <span class="cnx_label">
          <xsl:apply-templates select="cnx:label"/>
          <xsl:text>: </xsl:text>
        </span>
      </xsl:if>
      <xsl:apply-templates select="cnx:name|cnx:title"/>
      <xsl:for-each select="cnx:item">
        <span class="item">
          <xsl:call-template name="IdCheck"/>
          <xsl:call-template name="item-decoration"/>
          <xsl:call-template name="item-contents"/>
        </span>
      </xsl:for-each>
    </span>
  </xsl:template>

  <!-- Puts in @mark-prefix, @mark-suffix, <label> (for labeled-item lists), plus adds bullet or numbering where this can't be done by 
       the browser due to the presence of @mark-prefix, @mark-suffix, or @display='inline' -->
  <xsl:template name="item-decoration">
    <xsl:variable name="stepwise">
      <xsl:call-template name="class-test">
        <xsl:with-param name="provided-class" select="normalize-space(parent::cnx:list/@class)"/>
        <xsl:with-param name="wanted-class">stepwise</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="item-decoration-element">
      <xsl:choose>
        <xsl:when test="parent::cnx:list[@list-type='labeled-item']">strong</xsl:when>
        <xsl:otherwise>span</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$item-decoration-element}">
      <xsl:attribute name="class">item-decoration</xsl:attribute>
      <xsl:if test="parent::cnx:list[$stepwise='1' and @list-type='enumerated']">
        <!--Step-->
        <xsl:call-template name="gentext">
          <xsl:with-param name="key">Step</xsl:with-param>
          <xsl:with-param name="lang" select="/module/metadata/language"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:if test="not(parent::cnx:list[@list-type='labeled-item'] and (not(cnx:label) or cnx:label[not(node())]))">
        <xsl:value-of select="parent::cnx:list/@mark-prefix"/>
      </xsl:if>
      <xsl:if test="parent::cnx:list[not(@list-type='labeled-item' or @list-type='enumerated' or @bullet-style)]">
        <xsl:text>•</xsl:text>
      </xsl:if>
      <xsl:if test="parent::cnx:list[@bullet-style]">
        <xsl:choose>
          <xsl:when test="parent::cnx:list[@bullet-style='bullet']">•</xsl:when>
          <xsl:when test="parent::cnx:list[@bullet-style='open-circle']">○</xsl:when>
          <xsl:when test="parent::cnx:list[@bullet-style='pilcrow']">¶</xsl:when>
          <xsl:when test="parent::cnx:list[@bullet-style='rpilcrow']">⁋</xsl:when>
          <xsl:when test="parent::cnx:list[@bullet-style='asterisk']">*</xsl:when>
          <xsl:when test="parent::cnx:list[@bullet-style='dash']">–</xsl:when>
          <xsl:when test="parent::cnx:list[@bullet-style='section']">§</xsl:when>
          <xsl:when test="parent::cnx:list[@bullet-style='none']"/>
          <xsl:otherwise>
            <xsl:value-of select="parent::cnx:list/@bullet-style"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:if test="parent::cnx:list[@list-type='enumerated']">
        <xsl:variable name="start-value">
          <xsl:choose>
            <xsl:when test="parent::cnx:list[@start-value]">
              <xsl:value-of select="parent::cnx:list/@start-value"/>
            </xsl:when>
            <xsl:otherwise>1</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="parent::cnx:list[@number-style='upper-alpha']">
            <xsl:number format="A" value="position() + $start-value - 1"/>
          </xsl:when>
          <xsl:when test="parent::cnx:list[@number-style='lower-alpha']">
            <xsl:number format="a" value="position() + $start-value - 1"/>
          </xsl:when>
          <xsl:when test="parent::cnx:list[@number-style='upper-roman']">
            <xsl:number format="I" value="position() + $start-value - 1"/>
          </xsl:when>
          <xsl:when test="parent::cnx:list[@number-style='lower-roman']">
            <xsl:number format="i" value="position() + $start-value - 1"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:number format="1" value="position() + $start-value - 1"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
      <xsl:if test="parent::cnx:list[@list-type='labeled-item']">
        <xsl:apply-templates select="cnx:label"/>
        <xsl:if test="not(cnx:label) or cnx:label[not(node())]">
          <xsl:comment>empty label element</xsl:comment>
        </xsl:if>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="parent::cnx:list[@list-type='labeled-item'] and not(cnx:label[node()])"/>
        <xsl:when test="parent::cnx:list[@mark-suffix]">
          <xsl:value-of select="parent::cnx:list/@mark-suffix"/>
        </xsl:when>
        <xsl:when test="parent::cnx:list[@list-type='enumerated']">
          <xsl:text>.</xsl:text>
        </xsl:when>
        <xsl:when test="parent::cnx:list[@list-type='labeled-item']">
          <xsl:text>:</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:element>
    <xsl:if test="not(parent::cnx:list[@list-type='labeled-item'] and not(cnx:label[node()]))">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- After creating the decoration and putting in the labels for labeled-item lists -->
  <xsl:template name="item-contents">
    <xsl:choose>
      <xsl:when test="parent::cnx:list[@list-type='labeled-item']">
        <xsl:apply-templates select="*[not(self::cnx:label)]|text()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="position()!=last()">
      <xsl:choose>
        <xsl:when test="parent::cnx:list[@item-sep]">
          <xsl:value-of select="parent::cnx:list/@item-sep"/>
        </xsl:when>
        <xsl:when test="parent::cnx:list[(@type='inline' and $version='0.5') or @display='inline']">
          <xsl:text>;</xsl:text>
        </xsl:when>
      </xsl:choose>
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="class-test">
    <xsl:param name="provided-class"/>
    <xsl:param name="wanted-class"/>
    <xsl:if test="$provided-class = $wanted-class or                   starts-with($provided-class, concat($wanted-class, ' ')) or                   contains($provided-class, concat(' ', $wanted-class, ' ')) or                    substring($provided-class, string-length($provided-class) - string-length($wanted-class)) = concat(' ', $wanted-class)                  ">1</xsl:if>
  </xsl:template>

  <!-- EQUATION -->
  <xsl:template match="cnx:equation">
    <div class="equation">
      <xsl:call-template name="IdCheck"/> 
      <xsl:if test="cnx:name[node()] or cnx:title[node()] or @name or cnx:label[node()]">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">equation-header</xsl:attribute>
          <xsl:if test="cnx:label[node()]">
            <span class="cnx_label">
              <xsl:apply-templates select="cnx:label"/>
              <xsl:if test="cnx:title">
                <xsl:text>: </xsl:text>
              </xsl:if>
            </span>
          </xsl:if>
          <!-- for cnxml version 0.1 -->
	  <xsl:value-of select="@name"/>
          <!-- all other cnxml versions -->
          <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <div class="equation-contents">
        <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title|self::cnx:label)]|text()"/>
      </div>
      <xsl:choose>
        <xsl:when test="cnx:label[not(node())]"/>
        <xsl:otherwise>
          <span class="equation-number">
            <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
            <xsl:choose>
              <xsl:when test="@type and $type!='equation'">
                <xsl:number level="any" format="(1)" count="cnx:equation[translate(@type,$upper,$lower)=$type]"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:number level="any" format="(1)" count="cnx:equation[not(@type) or translate(@type,$upper,$lower)='equation']"/>
              </xsl:otherwise>
            </xsl:choose>
          </span>
        </xsl:otherwise>
      </xsl:choose>
    </div>
  </xsl:template>

  <!-- FIGURE -->
  <xsl:template match="cnx:figure">
    <xsl:call-template name="figure"/>
  </xsl:template>

  <!-- Suppress splash image for 'Modern Textbook' style in flow (process it in content_render.xsl instead). -->
  <xsl:template match="cnx:figure[@class='splash' and cnx:media/cnx:image[not(@for='pdf')]][1]">
    <xsl:if test="not($intro-module='1' and $modern-textbook)">
      <xsl:call-template name="figure"/>
    </xsl:if>
  </xsl:template>

  <!-- Actually process FIGURE output here. -->
  <xsl:template name="figure">
    <div class="figure">
      <xsl:call-template name="IdCheck"/>
      <table border="0" cellpadding="0" cellspacing="0" align="center" width="50%">
        <xsl:call-template name="caption"/>
        <xsl:if test="cnx:name[node()] or cnx:title[node()] or @name">
          <thead>
            <tr>
              <th class="figure-name">
                <xsl:value-of select="@name"/>
                <xsl:apply-templates select="cnx:name|cnx:title"/>
              </th>
            </tr>
          </thead>
        </xsl:if>
        <tbody>
          <tr>
            <td class="inner-figure">
              <xsl:choose>
                <xsl:when test="cnx:subfigure">
                  <xsl:choose>
                    <xsl:when test="@orient='vertical'">
                      <xsl:apply-templates select="cnx:subfigure"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:call-template name="horizontal"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="*[not(self::cnx:caption|self::cnx:name|self::cnx:title|self::cnx:label)]"/>
                </xsl:otherwise>
              </xsl:choose>
	    </td>
          </tr>
        </tbody>
      </table>
    </div>
  </xsl:template>
  
  <!-- SUBFIGURE vertical -->
  <xsl:template match="cnx:subfigure[parent::cnx:figure[@orient='vertical']]">
    <table border="0" cellpadding="0" cellspacing="0" align="center" class="vertical-subfigure">
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="cnx:name or cnx:title">
        <thead>
          <tr>
            <th class="vertical-subfigure-name">
              <xsl:apply-templates select="cnx:name|cnx:title"/>
            </th>
          </tr>
        </thead>
      </xsl:if>
      <tfoot>
        <tr>
          <xsl:call-template name="caption"/>
        </tr>
      </tfoot>
      <tbody>
        <tr>
          <td class="inner-vertical-subfigure">
            <xsl:apply-templates select="*[not(self::cnx:caption|self::cnx:name|self::cnx:title|self::cnx:label)]"/>
	  </td>
        </tr>
      </tbody>
    </table>
  </xsl:template>

  <!-- SUBFIGURE horizontal -->
  <xsl:template name="horizontal">
    <table border="0" cellpadding="0" cellspacing="0" class="horizontal-subfigure">
      <xsl:if test="cnx:subfigure/cnx:name or cnx:subfigure/cnx:title">
        <thead valign="bottom">
          <tr>
            <xsl:for-each select="cnx:subfigure">
              <th class="horizontal-subfigure-name">
                <xsl:apply-templates select="cnx:name|cnx:title"/>
              </th>
            </xsl:for-each>
          </tr>
        </thead>
      </xsl:if>
      <tfoot>
        <tr>
          <xsl:for-each select="cnx:subfigure">
            <xsl:call-template name="caption"/>
          </xsl:for-each>
        </tr>
      </tfoot>
      <tbody>
        <tr>
          <xsl:for-each select="cnx:subfigure">
            <td class="inner-horizontal-subfigure">
              <xsl:call-template name="IdCheck"/>
              <xsl:apply-templates select="*[not(self::cnx:caption|self::cnx:name|self::cnx:title|self::cnx:label)]"/>
            </td>
          </xsl:for-each>
        </tr>
      </tbody>
    </table>
  </xsl:template>

  <!-- CAPTION -->
  <xsl:template name="caption">
    <xsl:param name="captionelement">
      <xsl:choose>
        <xsl:when test="parent::cnx:figure">th</xsl:when>
        <xsl:otherwise>caption</xsl:otherwise>
      </xsl:choose>
    </xsl:param>
    <xsl:element name="{$captionelement}">
      <xsl:if test="cnx:caption[@id]">
        <xsl:attribute name="id">
          <xsl:value-of select="cnx:caption/@id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="parent::cnx:figure[@orient='vertical']">vertical-subfigure-caption</xsl:when>
          <xsl:when test="parent::cnx:figure">horizontal-subfigure-caption</xsl:when>
          <xsl:otherwise>figure-caption</xsl:otherwise>
        </xsl:choose>
        <xsl:text> caption</xsl:text>
      </xsl:attribute>
      <xsl:if test="$captionelement='caption'">
        <xsl:attribute name="align">bottom</xsl:attribute>
      </xsl:if>
      <strong class="cnx_label">
        <xsl:choose>
          <xsl:when test="self::cnx:subfigure and not(cnx:label[not(node())])">
            <xsl:if test="cnx:label">
              <xsl:apply-templates select="cnx:label"/>
              <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
            <xsl:choose>
              <xsl:when test="@type and $type!='subfigure'">
                <xsl:number level="any" count="cnx:subfigure[translate(@type,$upper,$lower)=$type]"/>
                <xsl:if test="cnx:caption">
                  <xsl:text>:</xsl:text>
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <xsl:number format="(a)" count="cnx:subfigure[not(@type) or translate(@type,$upper,$lower)='subfigure']"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text> </xsl:text>
	  </xsl:when>
          <xsl:otherwise>
            <xsl:if test="not(cnx:label[not(node())])">
              <xsl:choose>
                <xsl:when test="cnx:label[node()]">
                  <xsl:apply-templates select="cnx:label"/>
                </xsl:when>
                <xsl:otherwise>
                  <!-- Figure -->
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key">Figure</xsl:with-param>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text> </xsl:text>
              <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
              <xsl:choose>
                <xsl:when test="@type and $type!='figure'">
                  <xsl:number level="any" count="cnx:figure[translate(@type,$upper,$lower)=$type]"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:number level="any" count="cnx:figure[not(@type) or translate(@type,$upper,$lower)='figure']"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="cnx:caption">
                <xsl:text>: </xsl:text>
              </xsl:if>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </strong>
      <xsl:apply-templates select="cnx:caption"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="cnx:caption">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!-- Actually process EXERCISE ouput here -->
  <xsl:template match="cnx:exercise">
    <div>
      <xsl:attribute name="class">
        <xsl:text>exercise</xsl:text>
        <xsl:if test="translate(@type,$upper,$lower) = 'check-understanding'">
          <xsl:text> check-understanding</xsl:text>
        </xsl:if>
      </xsl:attribute>
      <xsl:call-template name="IdCheck"/>
      <xsl:if test="$case-diagnosis = '0' and (cnx:name or cnx:title or not(cnx:label[not(node())]))">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">exercise-header</xsl:attribute>
          <xsl:if test="not(cnx:label[not(node())])">
            <span class="cnx_label">
              <xsl:choose>
                <xsl:when test="cnx:label">
                  <xsl:apply-templates select="cnx:label"/>
                </xsl:when>
                <xsl:when test="ancestor::cnx:example or qml:item">
                  <!-- Problem -->
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key">Problem</xsl:with-param>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                  <!-- Exercise -->
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key">Exercise</xsl:with-param>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:text> </xsl:text>
              <xsl:variable name="type" select="translate(@type,$upper,$lower)"/>
              <xsl:choose>
                <xsl:when test="@type and $type!='exercise'">
                  <xsl:number level="any" count="cnx:exercise[translate(@type,$upper,$lower)=$type]"/>
                </xsl:when>
                <xsl:when test="ancestor::cnx:example">
                  <xsl:number level="any" from="cnx:example" count="cnx:exercise[not(@type) or translate(@type,$upper,$lower)='exercise']"/>
                </xsl:when>
                <xsl:when test="qml:item">
                  <xsl:number level="any" count="cnx:exercise[qml:item]"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:number level="any" count="cnx:exercise[not(ancestor::cnx:example|qml:item) and (not(@type) or translate(@type,$upper,$lower)='exercise')]"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="cnx:name or cnx:title">
                <xsl:text>: </xsl:text>
              </xsl:if>
            </span>
          </xsl:if>
          <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <div class="exercise-contents">
        <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title|self::cnx:label)]"/>
      </div>
    </div>
  </xsl:template>

  <!-- PROBLEM and COMMENTARY -->
  <xsl:template match="cnx:problem|cnx:commentary">
    <div class="problem">
      <xsl:call-template name="IdCheck"/>
      <xsl:attribute name="class">
        <xsl:value-of select="local-name()"/>
      </xsl:attribute>
      <xsl:if test="cnx:label[node()] or cnx:name or cnx:title">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">
            <xsl:value-of select="local-name()"/>
            <xsl:text>-header</xsl:text>
          </xsl:attribute>
          <xsl:if test="cnx:label[node()]">
            <span class="cnx_label">
              <xsl:apply-templates select="cnx:label"/>
              <xsl:if test="cnx:name or cnx:title">: </xsl:if>
            </span>
          </xsl:if>
          <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <div>
        <xsl:attribute name="class">
          <xsl:value-of select="local-name()"/>
          <xsl:text>-contents</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title|self::cnx:label)]|text()"/>
      </div>
    </div>
  </xsl:template>

  <!--SOLUTION -->
  <xsl:template match="cnx:solution">
    <xsl:variable name="solution-number">
      <xsl:number count="cnx:solution"/>
    </xsl:variable>
    <xsl:variable name="solution-type" select="translate(@type,$upper,$lower)"/>
    <xsl:variable name="solution-letter">
      <xsl:choose>
        <xsl:when test="count(parent::cnx:exercise/cnx:solution[translate(@type,$upper,$lower) = $solution-type]) &gt; 1">
          <xsl:number count="cnx:solution[translate(@type,$upper,$lower) = $solution-type]" format=" A"/>
        </xsl:when>
        <xsl:when test="count(parent::cnx:exercise/cnx:solution[translate(@type,$upper,$lower) = 'solution' or not(@type)]) &gt; 1">
          <xsl:number count="cnx:solution[translate(@type,$upper,$lower) = 'solution' or not(@type)]" format=" A"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="solution-string">
      <xsl:choose>
        <xsl:when test="$case-diagnosis = '1'">Diagnosis</xsl:when>
        <xsl:otherwise>Solution</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="javascriptpresent" select="/module/display/javascriptpresent"/>
    <div class="solution">
      <xsl:call-template name="IdCheck"/>
      <xsl:attribute name="style">
        <xsl:choose>
          <xsl:when test="$javascriptpresent='true'">
            <xsl:text>display: none;</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>display: block;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="$case-diagnosis = '0' and (cnx:name or cnx:title or not(cnx:label[not(node())]))">
        <xsl:variable name="level-number">
          <xsl:call-template name="level-count"/>
        </xsl:variable>
        <!-- h2, h3, etc... -->
        <xsl:element name="h{$level-number}">
          <xsl:attribute name="class">solution-header</xsl:attribute>
          <xsl:if test="not(cnx:label[not(node())])">
            <span class="cnx_label">
              <xsl:choose>
                <xsl:when test="cnx:label">
                  <xsl:apply-templates select="cnx:label"/>
                </xsl:when>
                <xsl:otherwise>
                  <!--Solution-->
                  <xsl:call-template name="gentext">
                    <xsl:with-param name="key" select="$solution-string"/>
                    <xsl:with-param name="lang" select="/module/metadata/language"/>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="$solution-letter"/>
              <xsl:if test="cnx:name or cnx:title">: </xsl:if>
            </span>
          </xsl:if>
          <xsl:apply-templates select="cnx:name|cnx:title"/>
        </xsl:element>
      </xsl:if>
      <div class="solution-contents">
        <xsl:apply-templates select="*[not(self::cnx:name|self::cnx:title|self::cnx:label)]"/>
      </div>
    </div>
    <div class="solution-toggles">
      <xsl:attribute name="style">
        <xsl:choose>
          <xsl:when test="$javascriptpresent='true'">
            <xsl:text>display: block;</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>display: none;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <a href="#" onclick="toggleSolution('{../@id}',{$solution-number}); return false;">
        <span class="solution-toggle">
          [
          <!-- Show Solution/Diagnosis -->
          <xsl:call-template name="gentext">
            <xsl:with-param name="key">Show</xsl:with-param>
            <xsl:with-param name="lang" select="/module/metadata/language"/>
          </xsl:call-template>
          <xsl:text> </xsl:text>
          <xsl:choose>
            <xsl:when test="cnx:label">
              <xsl:apply-templates select="cnx:label"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="gentext">
                <xsl:with-param name="key" select="$solution-string"/>
                <xsl:with-param name="lang" select="/module/metadata/language"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
          ]
        </span>
        <span class="solution-toggle" style="display: none;">
          [ 
          <!-- Hide Solution/Diagnosis -->
          <xsl:call-template name="gentext">
            <xsl:with-param name="key">Hide</xsl:with-param>
            <xsl:with-param name="lang" select="/module/metadata/language"/>
          </xsl:call-template>
          <xsl:text> </xsl:text>
          <xsl:choose>
            <xsl:when test="cnx:label">
              <xsl:apply-templates select="cnx:label"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="gentext">
                <xsl:with-param name="key" select="$solution-string"/>
                <xsl:with-param name="lang" select="/module/metadata/language"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
          ]
        </span>
      </a>
    </div>
  </xsl:template>

</xsl:stylesheet>
