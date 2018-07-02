<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:qml="http://cnx.rice.edu/qml/1.0"
  xmlns:cnx="http://cnx.rice.edu/cnxml">

  <!--added to detect problemset as a tag in a module-->
  <xsl:template match="qml:problemset">
    <div class="problemset">
      <h2 class="problemset-header">
        <span class="cnx_label">
          <xsl:call-template name="gentext">
            <xsl:with-param name="key">ProblemSet</xsl:with-param>
            <xsl:with-param name="lang" select="/module/metadata/language" />
          </xsl:call-template>
        </span>
      </h2>
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  
  <xsl:template match="qml:item">
    <div id="{@id}" name='item' class="qmlitem">

      <!-- Label and number the problems if they are part of a problemset.  Otherwise, let the parent exercise do the numbering, since 
           that label and numbering scheming is more complex. -->
      <xsl:if test="parent::qml:problemset">
        <h3 class="qmlitem-header">
          <span class="cnx_label">
            <xsl:call-template name="gentext">
              <xsl:with-param name="key">Problem</xsl:with-param>
              <xsl:with-param name="lang" select="/module/metadata/language" />
            </xsl:call-template>
            <xsl:text> </xsl:text>
            <xsl:number level="any" count="qml:item"/>
          </span>
        </h3>
      </xsl:if>

      <xsl:apply-templates select="qml:question" />

      <!--  The form.  Different depending on item-type.  -->

      <xsl:if test='qml:answer'>
      <form id="{@type}_{@id}">
	<xsl:apply-templates select="qml:answer" />
	<xsl:if test="not(@type='single-response')">
	  <input type="button" class="button">
	    <xsl:attribute name="value">
              <xsl:call-template name="gentext">
                <xsl:with-param name="key">
                  <xsl:choose>
                    <xsl:when test="@type='text-response'">ShowAnswer</xsl:when>
                    <xsl:otherwise>CheckAnswer</xsl:otherwise>
                  </xsl:choose>
                </xsl:with-param>
                <xsl:with-param name="lang" select="/module/metadata/language" />
              </xsl:call-template>
	    </xsl:attribute>
	    <!-- if there is a key, onclick submit the item
	    id, the response option id, and the key -->
	    <xsl:if test="qml:key">
	      <xsl:attribute name="onclick">showAnswer('<xsl:value-of select="@id" />', document.getElementById['<xsl:value-of select="@type"/>_<xsl:value-of select="@id"/>'], '<xsl:value-of select="qml:key/@answer" />')</xsl:attribute>
	    </xsl:if>
	    <!-- if there is no key, onclick submit the item
	    id, the response option id, and an indicator of
	    the key not being there -->
	    <xsl:if test="not(qml:key)">
	      <xsl:attribute name="onclick">showAnswer('<xsl:value-of select="@id" />', document.getElementById['<xsl:value-of select="../@type"/>_<xsl:value-of select="@id"/>'], 'no-key-present')</xsl:attribute>
	    </xsl:if>
          </input>
        </xsl:if>
      </form>
      </xsl:if>

      <!-- Feedback starts here in div tags that are hidden till the user takes an action. -->
      <div class="feedback correct-incorrect correct" id='correct_{@id}'>
        <xsl:call-template name="gentext">
          <xsl:with-param name="key">Correct</xsl:with-param>
          <xsl:with-param name="lang" select="/module/metadata/language" />
        </xsl:call-template>
      </div>
      
      <div class="feedback correct-incorrect incorrect" id='incorrect_{@id}'>
        <xsl:call-template name="gentext">
          <xsl:with-param name="key">Incorrect</xsl:with-param>
          <xsl:with-param name="lang" select="/module/metadata/language" />
        </xsl:call-template>
      </div>
      
      <!-- Answer-specific feedback. -->
      <xsl:for-each select="qml:answer">
	<!-- for single, multiple, and ordered-response -->
	<xsl:if test="count(qml:feedback) = 1">
	  <xsl:choose>
	    <xsl:when test="qml:feedback/@correct='yes'">
	      <div id='feedbaq_{@id}_{../@id}' class="feedback correct">
		<xsl:apply-templates select="qml:feedback/*|qml:feedback/text()" />
	      </div>
	    </xsl:when>
	    <xsl:when test="qml:feedback/@correct='no'">
	      <div id='feedbaq_{@id}_{../@id}' class="feedback incorrect">
	        <xsl:apply-templates select="qml:feedback/*|qml:feedback/text()" />
	      </div> 
	    </xsl:when>
	    <xsl:otherwise>
	      <div id='feedbaq_{@id}_{../@id}' class="feedback">
	        <xsl:apply-templates select="qml:feedback/*|qml:feedback/text()" />
	      </div> 
	    </xsl:otherwise>
	  </xsl:choose>
	</xsl:if>
	<!-- for text-response -->
	<xsl:if test="count(qml:feedback) = 2">
	  <xsl:for-each select="qml:feedback">
	    <xsl:choose>
	      <xsl:when test="@correct='yes'">
		<div id='feedbaq_{@correct}_{../../@id}' class="feedback correct">
		  <xsl:apply-templates />
		</div>
	      </xsl:when>
	      <xsl:when test="@correct='no'">
		<div id='feedbaq_{@correct}_{../../@id}' class="feedback incorrect">
		  <xsl:apply-templates />
		</div>
	      </xsl:when>
	      <xsl:otherwise>
		<div id='feedbaq_{@correct}_{../../@id}' class="feedback">
		   <xsl:apply-templates />
		</div>
	      </xsl:otherwise>
	    </xsl:choose>
	  </xsl:for-each>
	</xsl:if>
      </xsl:for-each>

      <!-- General feedback. -->
      <xsl:if test="qml:feedback">
	<div class="feedback" id='general_{@id}'>
	  <xsl:apply-templates select="qml:feedback/*|qml:feedback/text()" />
	</div>
      </xsl:if>
      
      <!-- The hint button and the hints.  Hint button is only
      made for items containing hints.  -->
      <xsl:if test="qml:hint">
	<form>
	  <input type="button" class="button" onclick="showHint('{@id}')">
            <xsl:attribute name="value">
              <xsl:call-template name="gentext">
                <xsl:with-param name="key">Hint</xsl:with-param>
                <xsl:with-param name="lang" select="/module/metadata/language" />
              </xsl:call-template>
            </xsl:attribute>
	  </input>
	</form>
	<xsl:apply-templates select="qml:hint" />
      </xsl:if>

    </div>
  </xsl:template>

  <!-- ANSWER -->
  <xsl:template match="qml:answer">
    <div class="answer">
      <xsl:choose>
	<xsl:when test="parent::qml:item[@type='text-response']">
	  <textarea cols='30' rows='3'><xsl:text> </xsl:text></textarea> 
	</xsl:when>
	<xsl:otherwise>
	  <input value="{@id}" name="{../@id}">
	    <xsl:choose>
	      <xsl:when test="parent::qml:item[@type='single-response']">
		<xsl:attribute name="type">radio</xsl:attribute>
		<xsl:attribute name="class">radio</xsl:attribute>
		<!-- if there is a key, onclick submit the item id, the response option id, and the key -->
		<xsl:if test="../qml:key">
		  <xsl:attribute name="onclick">showAnswer('<xsl:value-of select="../@id" />', '<xsl:value-of select="@id"/>', '<xsl:value-of select="../qml:key/@answer" />')</xsl:attribute>
		</xsl:if>
		<!-- if there is no key, onclick submit the item id, the
		response option id, and an indicator of the key not being there -->
		<xsl:if test="not(../qml:key)">
		  <xsl:attribute name="onclick">showAnswer('<xsl:value-of select="../@id" />', '<xsl:value-of select="@id"/>', 'no-key-present')</xsl:attribute>
		</xsl:if>
	      </xsl:when>
	      <xsl:otherwise>
		<xsl:attribute name="type">checkbox</xsl:attribute>
		<xsl:attribute name="class">checkbox</xsl:attribute>
		<xsl:attribute name="onclick">
		  addMe('<xsl:value-of select="../@id"/>', this)
		</xsl:attribute>
	      </xsl:otherwise>
	    </xsl:choose>
	  </input>
	</xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="qml:response" />
    </div>
  </xsl:template>

  <!-- QUESTION and RESPONSE -->
  <!-- Match the question and keep on going -->
  <xsl:template match="qml:question|qml:response">
    <xsl:apply-templates />
  </xsl:template>

  <!-- HINT -->
  <xsl:template match="qml:hint">
    <div class="hint" name="hint">
      <xsl:attribute name="id">hint<xsl:number level="single" count="hint" format="0"/>_<xsl:value-of select="../@id" /></xsl:attribute>
      <xsl:apply-templates />
    </div>
  </xsl:template>

  <xsl:template match="qml:feedback|qml:key|qml:resource" />

</xsl:stylesheet>
