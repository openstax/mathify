<?xml version="1.0"?>

<xsl:stylesheet version="1.0"
  xmlns:bibtex="http://bibtexml.sf.net/"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml" >

  <!-- Bibtex File -->
  <xsl:template match="bibtex:file">
    <div class='references'>
      <h2 class='references-header'>References</h2>
      <ol>
	<xsl:for-each select='bibtex:entry'>
	  <li>
	    <a name="{@id}"><xsl:text> </xsl:text></a>
	    <xsl:apply-templates/>
	  </li>
	</xsl:for-each>
      </ol>
    </div>
  </xsl:template>

  <!-- BOOK and BOOKLET and INBOOK -->
  <xsl:template match="bibtex:book|bibtex:booklet|bibtex:inbook">
    <xsl:apply-templates select="bibtex:author|bibtex:editor"/>
    <xsl:if test="bibtex:editor[string-length(normalize-space(text()))>0]">
      <xsl:text>. </xsl:text>
    </xsl:if>
    <xsl:call-template name="year-month"/>
    <xsl:apply-templates select="bibtex:chapter"/>
    <xsl:apply-templates select="bibtex:series"/>
    <xsl:if test="bibtex:series[string-length(normalize-space(text()))>0]">
      <xsl:apply-templates select="bibtex:volume"/>
    </xsl:if>
    <xsl:apply-templates select="bibtex:title"/>
    <xsl:call-template name="edition-volume-number-pages"/>
    <xsl:apply-templates select="bibtex:howpublished"/>
    <xsl:apply-templates select="bibtex:note"/>
    <xsl:apply-templates select="bibtex:type"/>
    <xsl:apply-templates select="bibtex:address"/>
    <xsl:apply-templates select="bibtex:publisher"/>
  </xsl:template>

  <!-- ARTICLE -->
  <xsl:template match="bibtex:article">
    <xsl:apply-templates select="bibtex:author"/>
    <xsl:call-template name="year-month"/>
    <xsl:apply-templates select="bibtex:title"/>
    <xsl:apply-templates select="bibtex:note"/>
    <xsl:apply-templates select="bibtex:journal"/>
    <xsl:apply-templates select="bibtex:volume"/>
    <xsl:apply-templates select="bibtex:number"/>
    <xsl:apply-templates select="bibtex:pages"/>
  </xsl:template>

  <!-- THESES and TECHREPORT -->
  <xsl:template match="bibtex:mastersthesis|bibtex:phdthesis|bibtex:techreport">
    <xsl:apply-templates select="bibtex:author"/>
    <xsl:call-template name="year-month"/>
    <xsl:apply-templates select="bibtex:title"/>
    <xsl:apply-templates select="bibtex:number"/>
    <xsl:apply-templates select="bibtex:note"/>
    <xsl:apply-templates select="bibtex:type"/>
    <xsl:apply-templates select="bibtex:school"/>
    <xsl:apply-templates select="bibtex:address"/>
    <xsl:apply-templates select="bibtex:institution"/>
  </xsl:template>

  <!-- PROCEEDINGS -->
  <xsl:template match="bibtex:proceedings">
    <xsl:apply-templates select="bibtex:editor"/>
    <xsl:if test="bibtex:editor[string-length(normalize-space(text()))>0]">
      <xsl:text>. </xsl:text>
    </xsl:if>
    <xsl:call-template name="year-month"/>
    <xsl:apply-templates select="bibtex:series"/>
    <xsl:apply-templates select="bibtex:title"/>
    <xsl:apply-templates select="bibtex:volume"/>
    <xsl:apply-templates select="bibtex:number"/>
    <xsl:apply-templates select="bibtex:note"/>
    <xsl:apply-templates select="bibtex:organization"/>
    <xsl:apply-templates select="bibtex:address"/>
    <xsl:apply-templates select="bibtex:publisher"/>
  </xsl:template>

  <!-- CONFERENCE and INCOLLECTION and INPROCEEDINGS -->
  <xsl:template match="bibtex:conference|bibtex:incollection|bibtex:inproceedings">
    <xsl:apply-templates select="bibtex:author"/>
    <xsl:call-template name="year-month"/>
    <xsl:apply-templates select="bibtex:title"/>
    <xsl:text>In </xsl:text>
    <xsl:apply-templates select="bibtex:editor"/>
    <xsl:if test="bibtex:editor[string-length(normalize-space(text()))>0]">
      <xsl:text>, </xsl:text>
    </xsl:if>
    <xsl:apply-templates select="bibtex:series"/>
    <xsl:if test="bibtex:series[string-length(normalize-space(text()))>0]">
      <xsl:apply-templates select="bibtex:volume"/>
    </xsl:if>
    <xsl:apply-templates select="bibtex:booktitle"/>
    <xsl:call-template name="edition-volume-number-pages"/>
    <xsl:apply-templates select="bibtex:note"/>
    <xsl:apply-templates select="bibtex:type"/>
    <xsl:apply-templates select="bibtex:organization"/>
    <xsl:apply-templates select="bibtex:address"/>
    <xsl:apply-templates select="bibtex:publisher"/>
  </xsl:template>

  <!-- MANUAL and MISC and UNPUBLISHED -->
  <xsl:template match="bibtex:manual|bibtex:misc|bibtex:unpublished">
    <xsl:apply-templates select="bibtex:author"/>
    <xsl:call-template name="year-month"/>
    <xsl:apply-templates select="bibtex:title"/>
    <xsl:call-template name="edition-volume-number-pages"/>
    <xsl:apply-templates select="bibtex:note"/>
    <xsl:apply-templates select="bibtex:organization"/>
    <xsl:apply-templates select="bibtex:howpublished"/>
  </xsl:template>

  <!-- Variables for handy use later on -->
  <xsl:variable name="period">.</xsl:variable>
  <xsl:variable name="exclamation">!</xsl:variable>
  <xsl:variable name="question">?</xsl:variable>
  <xsl:variable name="comma">,</xsl:variable>
  <xsl:variable name="ampersand">&amp;</xsl:variable>
  <xsl:variable name="semicolon">;</xsl:variable>

  <!-- AUTHOR, BOOKTITLE, CHAPTER, INSTITUTION, ORGANIZATION, PUBLISHER, TYPE, HOWPUBLISHED (adds period, unless element already ends in punctuation) -->
  <xsl:template match="bibtex:author[string-length(normalize-space(text()))>0]       |
                       bibtex:booktitle[string-length(normalize-space(text()))>0]    |
                       bibtex:chapter[string-length(normalize-space(text()))>0]      |
                       bibtex:institution[string-length(normalize-space(text()))>0]  |
                       bibtex:organization[string-length(normalize-space(text()))>0] |
                       bibtex:publisher[string-length(normalize-space(text()))>0]    |
                       bibtex:type[string-length(normalize-space(text()))>0]         |
                       bibtex:howpublished[string-length(normalize-space(text()))>0]">
    <xsl:for-each select=".">
      <xsl:variable name="last-character" select="substring(string(normalize-space()),string-length(normalize-space()),1)"/>
      <xsl:value-of select="normalize-space(.)"/>
      <xsl:if test="not($last-character=$period or $last-character=$exclamation or $last-character=$question)">
	<xsl:text>.</xsl:text>
      </xsl:if>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- EDITION-VOLUME-NUMBER-PAGES templates (for Book, Conference, Inbook, Incollection, Inproceedings, Proceedings, ???) -->
  <xsl:template name="edition-volume-number-pages">
    <xsl:if test="bibtex:edition[string-length(normalize-space(text()))>0] or
                  bibtex:volume[string-length(normalize-space(text()))>0] or
                  bibtex:number[string-length(normalize-space(text()))>0] or
                  bibtex:pages[string-length(normalize-space(text()))>0]">
      <xsl:text>(</xsl:text>
	<xsl:apply-templates select="bibtex:edition"/>
	<xsl:if test="not(bibtex:series[string-length(normalize-space(text()))>0])">
	  <xsl:apply-templates select="bibtex:volume"/>
	</xsl:if>
	<xsl:apply-templates select="bibtex:number"/>
	<xsl:apply-templates select="bibtex:pages"/>
      <xsl:text>). </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- EDITION -->
  <xsl:template match="bibtex:edition[string-length(normalize-space(text()))>0]">
    <xsl:value-of select="normalize-space(.)"/>
    <xsl:if test="(../bibtex:volume[string-length(normalize-space(text()))>0] and
                   not(../bibtex:series[string-length(normalize-space(text()))>0])) or
                   ../bibtex:number[string-length(normalize-space(text()))>0] or
                   ../bibtex:pages[string-length(normalize-space(text()))>0]">
      <xsl:text>, </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- VOLUME (explicitly states that it's a Volume, unless it's in an Article) -->
  <xsl:template match="bibtex:volume[string-length(normalize-space(text()))>0]">
    <xsl:choose>
      <xsl:when test="parent::bibtex:article or
                      ../bibtex:series[string-length(normalize-space(text()))>0]">
	<i>
	  <xsl:if test="../bibtex:series[string-length(normalize-space(text()))>0]">
	    <xsl:text>Vol. </xsl:text>
	  </xsl:if>
	  <xsl:value-of select="normalize-space(.)"/>
	</i>
	<xsl:if test="parent::bibtex:article and
                      not(../bibtex:number[string-length(normalize-space(text()))>0])">
	  <xsl:text>, </xsl:text>
	</xsl:if>
	<xsl:if test="../bibtex:series[string-length(normalize-space(text()))>0]">
	  <xsl:text>. </xsl:text>
	</xsl:if>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>Vol. </xsl:text>
	<xsl:value-of select="normalize-space(.)"/>
	<xsl:if test="../bibtex:number[string-length(normalize-space(text()))>0] or
                      ../bibtex:pages[string-length(normalize-space(text()))>0]">
	  <xsl:text>, </xsl:text>
	</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- NUMBER -->
  <xsl:template match="bibtex:number[string-length(normalize-space(text()))>0]">
    <xsl:choose>
      <xsl:when test="parent::bibtex:article or parent::bibtex:techreport">
	<xsl:text>(</xsl:text>
	<xsl:value-of select="normalize-space(.)"/>
	<xsl:text>)</xsl:text>
	<xsl:if test="parent::bibtex:article">
	  <xsl:text>, </xsl:text>
	</xsl:if>
	<xsl:if test="parent::bibtex:techreport">
	  <xsl:text>. </xsl:text>
	</xsl:if>
      </xsl:when>
      <xsl:otherwise>
	<xsl:value-of select="normalize-space(.)"/>
	<xsl:if test="../bibtex:pages[string-length(normalize-space(text()))>0]">
	  <xsl:text>, </xsl:text>
	</xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- PAGES (in non-articles, precedes by "p. ", or "pp. " if more than one page (only knows to do this if hyphen is used)) -->
  <xsl:template match="bibtex:pages[string-length(normalize-space(text()))>0]">
    <xsl:choose>
      <xsl:when test="parent::bibtex:article">
	<xsl:value-of select="normalize-space(.)"/>
	<xsl:text>. </xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>p</xsl:text>
	<xsl:if test="contains(string(),'-')">
	  <xsl:text>p</xsl:text>
	</xsl:if>
	<xsl:text>. </xsl:text>
	<xsl:value-of select="normalize-space(.)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- EDITOR (adds "(Ed.)" if singular or "(Eds.)" if plural - this might not always work, however) -->
  <xsl:template match="bibtex:editor[string-length(normalize-space(text()))>0]">
    <xsl:value-of select="normalize-space(.)"/>
    <xsl:text> (Ed</xsl:text>
    <xsl:if test="contains(string(),' and ') or contains(string(),' with ') or contains(string(),$ampersand) or contains(string(),$semicolon)">
      <xsl:text>s</xsl:text>
    </xsl:if>
    <xsl:text>.)</xsl:text>
  </xsl:template>

  <!-- YEAR-MONTH template (surrounds with parentheses and adds period) -->
  <xsl:template name="year-month">
    <xsl:if test="bibtex:year[string-length(normalize-space(text()))>0]">
      <xsl:text>(</xsl:text>
      <xsl:value-of select="normalize-space(bibtex:year)"/>
      <xsl:if test="bibtex:month[string-length(normalize-space(text()))>0]">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="normalize-space(bibtex:month)"/>
      </xsl:if>
      <xsl:text>). </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- NOTE (surrounds with bracket and adds period) -->
  <xsl:template match="bibtex:note[string-length(normalize-space(text()))>0]">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="normalize-space(.)"/>
    <xsl:text>]. </xsl:text>
  </xsl:template>

  <!-- ADDRESS (adds semicolon if followed by publisher, otherwise adds period unless address already ends in punctutation) -->
  <xsl:template match="bibtex:address[string-length(normalize-space(text()))>0]">
    <xsl:for-each select=".">
      <xsl:variable name="last-character" select="substring(string(normalize-space()),string-length(normalize-space()),1)"/>
      <xsl:value-of select="normalize-space(.)"/>
      <xsl:if test="../bibtex:publisher[string-length(normalize-space(text()))>0] or
                    ../bibtex:institution[string-length(normalize-space(text()))>0]">
	<xsl:text>: </xsl:text>
      </xsl:if>
      <xsl:if test="../bibtex:school[string-length(normalize-space(text()))>0] and
                    not($last-character=$period or $last-character=$exclamation or $last-character=$question)">
	<xsl:text>. </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- TITLE (italicizes if appropriate, adds period unless title already ends in punctuation) -->
  <xsl:template match="bibtex:title|bibtex:booktitle[string-length(normalize-space(text()))>0]">
    <xsl:for-each select=".">
      <xsl:variable name="last-character" select="substring(string(normalize-space()),string-length(normalize-space()),1)"/>
      <xsl:variable name="italicized" select="not(parent::bibtex:article or parent::bibtex:proceedings or ../bibtex:booktitle)"/>
      <xsl:choose>
	<xsl:when test="$italicized or self::bibtex:booktitle">
	  <i>
	    <xsl:value-of select="normalize-space(.)"/>
	  </i>
	</xsl:when>
	<xsl:otherwise>
	  <xsl:value-of select="normalize-space(.)"/>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:if test="not($last-character=$period or $last-character=$exclamation or $last-character=$question)">
	<xsl:text>.</xsl:text>
      </xsl:if>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- JOURNAL (italicizes and adds appropriate punctuation) -->
  <xsl:template match="bibtex:journal[string-length(normalize-space(text()))>0]">
    <i>
      <xsl:value-of select="normalize-space(.)"/>
    </i>
    <xsl:choose>
      <xsl:when test="../bibtex:volume[string-length(normalize-space(text()))>0] or
                      ../bibtex:number[string-length(normalize-space(text()))>0] or
                      ../bibtex:pages[string-length(normalize-space(text()))>0]">
	<xsl:text>, </xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>. </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- SCHOOL (adds comma if followed by Address, otherwise adds period) -->
  <xsl:template match="bibtex:school[string-length(normalize-space(text()))>0]">
    <xsl:value-of select="normalize-space(.)"/>
    <xsl:choose>
      <xsl:when test="../bibtex:address[string-length(normalize-space(text()))>0]">
	<xsl:text>, </xsl:text>
      </xsl:when>
      <xsl:otherwise>
	<xsl:text>. </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- SERIES (italicizes and adds colon) -->
  <xsl:template match="bibtex:series[string-length(normalize-space(text()))>0]">
    <i>
     <xsl:value-of select="normalize-space(.)"/>
     <xsl:text>: </xsl:text>
    </i>
  </xsl:template>

</xsl:stylesheet>
