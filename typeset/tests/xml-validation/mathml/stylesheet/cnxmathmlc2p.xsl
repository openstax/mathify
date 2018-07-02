<?xml version="1.0" encoding="ASCII"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:m="http://www.w3.org/1998/Math/MathML" xmlns="http://www.w3.org/1999/xhtml" version="1.0" exclude-result-prefixes="m">


  <!-- Import mathmlc2p to minimize space required by new material -->
  <xsl:import href="w3-c2p.xsl"/>

  <xsl:output method="xml" indent="yes" encoding="ASCII"/>

  <!--  This file contains changes to the content to presentation mathml -->
  <!--  stylesheet. See the end of the file for modifications made to the original c2p XSLT -->

  <!--  Created 2001-02-01.  -->

  <!-- paramaters -->
  <xsl:param name="meannotation" select="''"/>
  <xsl:param name="forallequation" select="0"/>
  <xsl:param name="vectornotation" select="''"/>
  <xsl:param name="andornotation" select="''"/>
  <xsl:param name="realimaginarynotation" select="''"/>
  <xsl:param name="scalarproductnotation" select="''"/>
  <xsl:param name="vectorproductnotation" select="''"/>
  <xsl:param name="conjugatenotation" select="''"/>
  <xsl:param name="curlnotation" select="''"/>
  <xsl:param name="gradnotation" select="''"/>
  <xsl:param name="remainder" select="''"/>
  <xsl:param name="complementnotation" select="''"/>
  <xsl:param name="imaginaryi" select="''"/>

  <!--This is the template for math.-->
  <xsl:template match="m:math">
    <m:math>
      <xsl:choose>
        <!-- Otherwise, explicitly set equations to mode 'display' -->
        <xsl:when test="parent::*[local-name()='equation']">
          <xsl:attribute name="display">block</xsl:attribute>
        </xsl:when>
        <xsl:when test="@display">
          <xsl:attribute name="display"><xsl:value-of select="@display"/></xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="display">inline</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <m:semantics>
        <m:mrow>
          <xsl:apply-templates/>
        </m:mrow>
        <m:annotation-xml encoding="MathML-Content">
          <xsl:copy-of select="child::*"/>
        </m:annotation-xml>
      </m:semantics>
    </m:math>
  </xsl:template>

  <!-- New equal for equation -->

  <xsl:template mode="c2p" match="m:apply[*[1][self::m:eq] and parent::*[parent::*[local-name()='equation']]]">
    <xsl:choose>
      <xsl:when test="count(child::*)&gt;3">
        <m:mtable align="center" columnalign="right center left">
          <m:mtr>
            <m:mtd columnalign="right">
              <m:mrow><xsl:apply-templates select="child::*[position()=2]"/></m:mrow>
            </m:mtd>
            <m:mtd columnalign="center"><m:mo>=</m:mo></m:mtd>
            <m:mtd columnalign="left">
              <m:mrow><xsl:apply-templates select="child::*[position()=3]"/></m:mrow>
            </m:mtd>
          </m:mtr>
          <xsl:for-each select="child::*[position()&gt;3]">
            <m:mtr>
              <m:mtd columnalign="right"/>
              <m:mtd columnalign="center"><m:mo>=</m:mo></m:mtd>
              <m:mtd columnalign="left">
            <m:mrow><xsl:apply-templates select="."/></m:mrow>
              </m:mtd>
            </m:mtr>
          </xsl:for-each>
        </m:mtable>
      </xsl:when>
      <xsl:otherwise>
        <m:mrow><xsl:apply-templates select="child::*[position()=2]"/></m:mrow>
        <m:mrow><m:mo>=</m:mo></m:mrow>
        <m:mrow><xsl:apply-templates select="child::*[position()=last()]"/></m:mrow>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Places the power of a function or a trig function in the middle
  of it -->

  <xsl:template mode="c2p" match="m:apply[*[1][self::m:power]]">
    <xsl:choose>
      <!-- checks to see if it is a function then formats -->

      <xsl:when test="child::*[position()=2 and child::*[local-name()='ci' and @type='fn']]">
        <m:mrow>
          <m:msup>
            <xsl:apply-templates select="child::*/child::*[local-name()='ci' and @type='fn']"/>
            <xsl:apply-templates select="child::*[position()=3]"/>
          </m:msup>
          <m:mfenced>
            <xsl:if test="child::*[position()=2 and child::*[local-name()='ci' and @class='discrete']]">
              <xsl:attribute name="open">[</xsl:attribute>
              <xsl:attribute name="close">]</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select="child::*/child::*[position()!=1]"/>
          </m:mfenced>
        </m:mrow>
      </xsl:when>
      <!-- puts the exponent of a sin function between the sin and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='sin']]">
        <m:msup>
          <m:mi>sin</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a cos function between the cos and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='cos']]">
        <m:msup>
          <m:mi>cos</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a tan function between the tan and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='tan']]">
        <m:msup>
          <m:mi>tan</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a sec function between the sec and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='sec']]">
        <m:msup>
          <m:mi>sec</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a sec function between the csc and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='csc']]">
        <m:msup>
          <m:mi>csc</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a cot function between the cot and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='cot']]">
        <m:msup>
          <m:mi>cot</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a sinh function between the sinh and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='sinh']]">
        <m:msup>
          <m:mi>sinh</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a cosh function between the cosh and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='cosh']]">
        <m:msup>
          <m:mi>cosh</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a tanh function between the tanh and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='tanh']]">
        <m:msup>
          <m:mi>tanh</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a sech function between the sech and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='sech']]">
        <m:msup>
          <m:mi>sech</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a csch function between the csch and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='csch']]">
        <m:msup>
          <m:mi>csch</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of a coth function between the coth and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='coth']]">
        <m:msup>
          <m:mi>coth</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arcsin function between the arcsin and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and          local-name()='arcsin']]">
        <m:msup>
          <m:mi>arcsin</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arccos function between the arccos and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and          local-name()='arccos']]">
        <m:msup>
          <m:mi>arccos</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arctan function between the arctan and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arctan']]">
        <m:msup>
          <m:mi>arctan</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arccosh function between the arccosh and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arccosh']]">
        <m:msup>
          <m:mi>arccosh</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arccot function between the arccot and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arccot']]">
        <m:msup>
          <m:mi>arccot</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arccoth function between the arccoth and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arccoth']]">
        <m:msup>
          <m:mi>arccoth</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arccsc function between the arccsc and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arccsc']]">
        <m:msup>
          <m:mi>arccsc</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arccsch function between the arccsch and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arccsch']]">
        <m:msup>
          <m:mi>arccsch</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arcsec function between the arcsec and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arcsec']]">
        <m:msup>
          <m:mi>arcsec</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arcsech function between the arcsech and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arcsech']]">
        <m:msup>
          <m:mi>arcsech</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arcsinh function between the arcsinh and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arcsinh']]">
        <m:msup>
          <m:mi>arcsinh</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- puts the exponent of an arctanh function between the arctanh and the
      rest -->
      <xsl:when test="m:apply[child::*[position()=1 and
            local-name()='arctanh']]">
        <m:msup>
          <m:mi>arctanh</m:mi>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
        <m:mfenced separators=" ">
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <!-- for normal power applications -->
      <xsl:when test="local-name(*[position()=2])='apply'">
        <m:msup>
          <m:mfenced separators=" ">
            <xsl:apply-templates select="child::*[position()=2]"/></m:mfenced>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
      </xsl:when>
      <xsl:otherwise>
        <m:msup>
          <xsl:apply-templates select="child::*[position()=2]"/>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:msup>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- places the -1 of a inverted function or trig function in the -->
  <!-- middle of the function -->
  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='inverse']]">
    <xsl:choose>
      <xsl:when test="descendant::*[position()=3 and @type='fn']">
        <m:msup>
          <xsl:apply-templates select="descendant::*[position()=3]"/>
          <m:mo>-1</m:mo>
        </m:msup>
        <m:mfenced>
          <xsl:apply-templates select="descendant::*[position()=4]"/>
        </m:mfenced>
      </xsl:when>
      <xsl:when test="local-name(*[position()=2])='apply'">
        <m:msup>
          <m:mfenced separators=" ">
            <m:mrow>
              <xsl:apply-templates select="*[position()=2]"/>
            </m:mrow>
          </m:mfenced>
          <m:mn>-1</m:mn>
        </m:msup>
      </xsl:when>
      <xsl:otherwise>
        <m:msup> <!-- elementary classical functions have two templates: apply[func] for standard case, func[position()!=1] for inverse and compose case-->
          <m:mrow><xsl:apply-templates select="*[position()=2]"/></m:mrow><!-- function to be inversed-->
          <m:mn>-1</m:mn>
        </m:msup>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- csymbol stuff: Connexions MathML extensions -->

  <!-- Combination -->
  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='csymbol' and @definitionURL='http://www.openmath.org/cd/combinat1.ocd']]">
    <m:mrow>

      <m:mfenced>
        <m:mtable>
          <m:mtr>
            <m:mtd>
              <xsl:apply-templates select="child::*[position()=2]"/>
            </m:mtd>
          </m:mtr>
          <m:mtr>
            <m:mtd>
              <xsl:apply-templates select="child::*[position()=3]"/>
            </m:mtd>
          </m:mtr>
        </m:mtable>
      </m:mfenced>
    </m:mrow>
  </xsl:template>

  <!-- Probability -->

  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#probability']]">
    <xsl:choose>
      <xsl:when test="m:condition">
        <m:mrow>
          <m:mi>Pr</m:mi>
          <m:mfenced open="[" close="]" separators=" ">
          <m:mfenced open=" " close=" ">
             <xsl:apply-templates select="*[local-name()!='condition' and local-name()!='csymbol']"/>
            </m:mfenced>
            <m:mspace width=".3em"/>
            <m:mo>|</m:mo>
            <m:mspace width=".3em"/>
            <xsl:apply-templates select="m:condition"/>
          </m:mfenced>
        </m:mrow>
      </xsl:when>
      <xsl:otherwise>
        <m:mrow>
          <m:mi>Pr</m:mi>
          <m:mfenced open="[" close="]">
            <xsl:apply-templates select="*[local-name()!='csymbol']"/>
          </m:mfenced>
        </m:mrow>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Complement -->
  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
    local-name()='csymbol' and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#complement']]">
    <xsl:choose>
      <xsl:when test="$complementnotation='overbar'">
        <m:mover>
           <xsl:choose>
            <xsl:when test="local-name(*[position()=2])='apply'">
              <m:mfenced separators=" ">
            <xsl:apply-templates select="child::*[position()=2]"/>
              </m:mfenced>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="child::*[position()=2]"/>
            </xsl:otherwise>
          </xsl:choose>
          <m:mo>&#175;<!--OverBar--></m:mo>
        </m:mover>
      </xsl:when>
      <xsl:otherwise>
        <m:msup>
          <xsl:choose>
            <xsl:when test="local-name(*[position()=2])='apply'">
              <m:mfenced separators=" ">
            <xsl:apply-templates select="child::*[position()=2]"/>
              </m:mfenced>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="child::*[position()=2]"/>
            </xsl:otherwise>
          </xsl:choose>
          <m:mo>&#8242;<!--prime--></m:mo>
        </m:msup>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Expected value -->

  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
    local-name()='csymbol' and
    @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#expectedvalue']]">
    <m:mrow>
      <xsl:choose>
        <xsl:when test="m:bvar">
          <m:msub>
            <m:mi>E</m:mi>
            <xsl:apply-templates select="m:bvar"/>
          </m:msub>
          <m:mfenced open="[" close="]" seperators=" ">
            <m:mrow>
              <xsl:apply-templates select="child::*[local-name()!='condition' and position()=last()]"/>
              <xsl:if test="m:condition">
            <m:mrow>
              <m:mspace width=".1em"/>
              <m:mo>|</m:mo>
              <m:mspace width=".1em"/>
              <m:mfenced open=" " close=" ">
              <xsl:apply-templates select="m:condition"/>
              </m:mfenced>
            </m:mrow>
              </xsl:if>
            </m:mrow>
          </m:mfenced>
        </xsl:when>
        <xsl:otherwise>
          <m:mi>E</m:mi>
          <m:mfenced open="[" close="]" seperators=" ">
            <m:mrow>
              <xsl:apply-templates select="child::*[local-name()!='condition' and position()=last()]"/>
              <xsl:if test="m:condition">
            <m:mrow>
              <m:mspace width=".1em"/>
              <m:mo>|</m:mo>
              <m:mspace width=".1em"/>
              <m:mfenced open=" " close=" ">
              <xsl:apply-templates select="m:condition"/>
              </m:mfenced>
            </m:mrow>
              </xsl:if>
            </m:mrow>
          </m:mfenced>
        </xsl:otherwise>
      </xsl:choose>
    </m:mrow>
  </xsl:template>

  <!-- Estimate -->
  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#estimate']]">
    <xsl:choose>
      <xsl:when test="child::*[position()=2 and local-name()='ci' and m:msub]">
        <m:msub>
          <m:mover>
            <xsl:apply-templates select="m:ci/m:msub/*[1]"/>
            <m:mo>^<!--Hat--></m:mo>
          </m:mover>
          <m:mrow>
            <xsl:apply-templates select="m:ci/m:msub/*[2]"/>
          </m:mrow>
        </m:msub>
      </xsl:when>
      <xsl:otherwise>
    <m:mover>
      <m:mrow><xsl:apply-templates/></m:mrow>
      <m:mo>^<!--Hat--></m:mo>
    </m:mover>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

 <!--PDF (Probability Density Function)-->

  <xsl:template mode="c2p" match="m:apply[*[1][self::m:csymbol and
    @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#pdf']]">
    <m:mrow>
      <m:mrow>
        <xsl:choose>
          <xsl:when test="m:bvar">
            <m:msub>
              <m:mrow><xsl:apply-templates select="m:csymbol"/></m:mrow>
              <m:mfenced open="" close="">
            <m:mrow>
              <m:mfenced open=" " close=" ">
                <xsl:apply-templates select="m:bvar/node()"/>
              </m:mfenced>
              <xsl:if test="m:condition">
                <m:mrow>
                  <m:mspace width=".1em"/>
                  <m:mo>|</m:mo>
                  <m:mspace width=".1em"/>
                  <xsl:apply-templates select="m:condition"/>
                </m:mrow>
              </xsl:if>
            </m:mrow>
              </m:mfenced>
            </m:msub>
          </xsl:when>
          <xsl:otherwise>
            <m:mrow><xsl:apply-templates select="m:csymbol"/></m:mrow>
          </xsl:otherwise>
        </xsl:choose>
      </m:mrow>
      <m:mfenced>
        <m:mrow>
          <m:mfenced open=" " close=" ">
            <xsl:apply-templates select="child::*[not(local-name()='condition' or local-name()='csymbol' or local-name()='bvar')]"/>
          </m:mfenced>
          <xsl:if test="m:condition and not(m:bvar)">
            <m:mrow>
              <m:mspace width=".1em"/>
              <m:mo>|</m:mo>
              <m:mspace width=".1em"/>
              <xsl:apply-templates select="m:condition"/>
            </m:mrow>
          </xsl:if>
        </m:mrow>
      </m:mfenced>
    </m:mrow>
  </xsl:template>

<!-- CDF (Cumulative Distribution Function) -->

  <xsl:template mode="c2p" match="m:apply[*[1][self::m:csymbol and
    @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#cdf']]">
    <m:mrow>
      <m:mrow>
        <xsl:choose>
          <xsl:when test="m:bvar">
            <m:msub>
              <m:mrow><xsl:apply-templates select="m:csymbol"/></m:mrow>
              <m:mfenced open="" close="">
            <m:mrow>
              <m:mfenced open=" " close=" ">
                <xsl:apply-templates select="m:bvar"/>
              </m:mfenced>
              <xsl:if test="m:condition">
                <m:mrow>
                  <m:mspace width=".1em"/>
                  <m:mo>|</m:mo>
                  <m:mspace width=".1em"/>
                  <xsl:apply-templates select="m:condition"/>
                </m:mrow>
              </xsl:if>
            </m:mrow>
              </m:mfenced>
            </m:msub>
          </xsl:when>
          <xsl:otherwise>
            <m:mrow><xsl:apply-templates select="m:csymbol"/></m:mrow>
          </xsl:otherwise>
        </xsl:choose>
      </m:mrow>
      <m:mfenced>
        <m:mrow>
          <m:mfenced open=" " close=" ">
            <xsl:apply-templates select="child::*[not(local-name()='condition' or local-name()='csymbol' or local-name()='bvar')]"/>
          </m:mfenced>
           <xsl:if test="m:condition and not(m:bvar)">
            <m:mrow>
              <m:mspace width=".1em"/>
              <m:mo>|</m:mo>
              <m:mspace width=".1em"/>
              <xsl:apply-templates select="m:condition"/>
            </m:mrow>
          </xsl:if>
        </m:mrow>
      </m:mfenced>
    </m:mrow>
  </xsl:template>

<!-- Normal Distribution -->
<xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#normaldistribution']]">
    <m:mrow>
      <m:mi>&#119977;<!--Nscr--></m:mi>
      <m:mfenced>
        <xsl:apply-templates select="child::*[position()=2 or position()=3]"/>
      </m:mfenced>
    </m:mrow>
  </xsl:template>

<!-- Distributed In -->
<xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#distributedin']]">
    <m:mrow>
      <xsl:apply-templates select="child::*[position()=2]"/>
      <m:mo>&#8764;<!--Tilde--></m:mo>
      <xsl:apply-templates select="child::*[position()=3]"/>
    </m:mrow>
  </xsl:template>

<!-- Distance -->
<xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#distance']]">
    <m:mrow>
      <m:mi>&#119967;<!--Dscr--></m:mi>
      <m:mfenced>
        <m:mrow>
          <xsl:apply-templates select="child::*[position()=2]"/>
          <m:mo>&#8741;<!--DoubleVerticalBar--></m:mo>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:mrow>
      </m:mfenced>
    </m:mrow>
  </xsl:template>

<!-- Mutual Information -->
<xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#mutualinformation']]">
    <m:mrow>
      <m:mi>&#8464;<!--Iscr--></m:mi>
      <m:mfenced>
        <m:mrow>
          <xsl:apply-templates select="child::*[position()=2]"/>
          <m:mo>;<!--semi--></m:mo>
          <xsl:apply-templates select="child::*[position()=3]"/>
        </m:mrow>
      </m:mfenced>
    </m:mrow>
  </xsl:template>

 <!-- Peicewise Stochastic Process -->

  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
    local-name()='csymbol' and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#stochastic']]">
   <m:mrow>
      <xsl:element name="m:mfenced" namespace="http://www.w3.org/1998/Math/MathML">
        <xsl:attribute name="open">{</xsl:attribute>
        <xsl:attribute name="close"/>
        <m:mtable>
          <xsl:for-each select="m:apply[child::*[position()=1 and
            local-name()='csymbol' and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#stochasticpiece']]">
            <m:mtr><m:mtd>
            <xsl:apply-templates select="*[position()=2]"/>
            <m:mspace width="0.3em"/><m:mtext>Prob</m:mtext><m:mspace width="0.3em"/>
            <xsl:apply-templates select="*[position()=3]"/>
              </m:mtd></m:mtr>
          </xsl:for-each>
        </m:mtable>
      </xsl:element>
    </m:mrow>
  </xsl:template>

  <!-- Vector Derivative -->

  <xsl:template mode="c2p" match="m:apply[*[1][self::m:diff and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#vectorderivative']]">
    <m:mrow>
      <xsl:choose>
        <xsl:when test="m:degree">
          <m:msubsup>
            <m:mi>&#8711;<!--Del--></m:mi>
            <xsl:apply-templates select="m:bvar"/>
            <xsl:apply-templates select="m:degree"/>
          </m:msubsup>
        </xsl:when>
        <xsl:otherwise>
          <m:msub>
            <m:mi>&#8711;<!--Del--></m:mi>
            <xsl:apply-templates select="m:bvar"/>
          </m:msub>
        </xsl:otherwise>
      </xsl:choose>
      <m:mfenced>
        <xsl:apply-templates select="*[position()=last()]"/>
      </m:mfenced>
    </m:mrow>
  </xsl:template>

  <!-- infimum -->
  <xsl:template  match="m:apply[child::*[position()=1 and
    local-name()='csymbol' and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#infimum']]">
    <m:mrow>
      <xsl:choose>
        <xsl:when test="m:bvar"> <!-- if there are bvars-->
          <m:msub>
            <m:mi>inf</m:mi>
            <m:mrow>
              <xsl:for-each select="m:bvar[position()!=last()]">  <!--select every bvar except the last one (position() only counts bvars, not the other siblings)-->
            <xsl:apply-templates select="."/><m:mo>,</m:mo>
              </xsl:for-each>
              <xsl:apply-templates select="m:bvar[position()=last()]"/>
            </m:mrow>
          </m:msub>
          <m:mrow><m:mo>{</m:mo>
            <xsl:apply-templates select="*[local-name()!='condition' and local-name()!='bvar']"/>
            <xsl:if test="m:condition">
              <m:mo>|</m:mo><xsl:apply-templates select="m:condition"/>
            </xsl:if>
            <m:mo>}</m:mo></m:mrow>
        </xsl:when>
        <xsl:otherwise> <!-- if there are no bvars-->
          <m:mo>inf</m:mo>
          <m:mrow><m:mo>{</m:mo>
            <m:mfenced open="" close=""><xsl:apply-templates select="*[local-name()!='condition' and local-name()!='min']"/></m:mfenced>
            <xsl:if test="m:condition">
              <m:mo>|</m:mo><xsl:apply-templates select="m:condition"/>
            </xsl:if>
            <m:mo>}</m:mo></m:mrow>
        </xsl:otherwise>
      </xsl:choose>
    </m:mrow>
  </xsl:template>





  <!-- Horizontally Partitioned Matrix -->
  <!-- FIXME: not in use till futher discussion-->

  <!--
<xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#partitionedmatrix'
  and @type='horizontal']]">
<m:mrow>
<m:mfenced separators=" ">
<mtable>
<xsl:apply-templates select="child::*[position()=2]"/>
</mtable>
<m:mo>|</m:mo>
<mtable>
<xsl:apply-templates select="child::*[position()=3]"/>
</mtable>
</m:mfenced>
</m:mrow>
</xsl:template>
  -->

  <!-- Vertically Partitioned Matrix -->
  <!-- FIXME: not in use till futher discussion-->
  <!-- FIXME: Doesn't work -->

  <!--
<xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#partitionedmatrix'
  and @type='vertical']]">
<m:mrow>
<m:mfenced>
<mtable>
<mtr>
<mtd>
<mtable>
<xsl:apply-templates select="child::*[position()=2]"/>
</mtable>
</mtd>
</mtr>
<mtr>
<mtd>
  &HorizontalLine;
</mtd>
</mtr>
<mtr>
<mtd>
<mtable>
<xsl:apply-templates select="child::*[position()=3]"/>
</mtable>
</mtd>
</mtr>
</mtable>
</m:mfenced>
</m:mrow>
</xsl:template>
  -->

  <!-- Quad Partitioned Matrix -->
  <!-- FIXME: not in use till futher discussion-->
  <!-- FIXME: Doesn't work -->

  <!--
<xsl:template mode="c2p" match="m:apply[*[1][self::m:csymbol and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#partitionedmatrix' and @type='quad']]">

<m:mrow>
<m:mfenced separators=" ">
<mfrac>
<mtable>
<xsl:apply-templates select="child::*[position()=2]"/>
</mtable>
<mtable>
<xsl:apply-templates select="child::*[position()=3]"/>
</mtable>
</mfrac>
<m:mo>|</m:mo>
<mfrac>
<mtable>
<xsl:apply-templates select="child::*[position()=4]"/>
</mtable>
<mtable>
<xsl:apply-templates select="child::*[position()=5]"/>
</mtable>
</mfrac>
</m:mfenced>
</m:mrow>
</xsl:template>
  -->

  <!--<xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
  local-name()='csymbol' and
  @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#partition']]">
<xsl:apply-templates select="*"/>
</xsl:template>
  -->


  <!-- Convolution -->
  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='csymbol' and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#convolve']]">
    <xsl:choose>
      <xsl:when test="count(child::*)&gt;=3">
        <m:mrow>
          <xsl:for-each select="child::*[position()!=last() and  position()!=1]">
            <xsl:choose>
              <xsl:when test="m:plus"> <!--add brackets around + children for priority purpose-->
            <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>*<!--midast--></m:mo>
              </xsl:when>
              <xsl:when test="m:minus"> <!--add brackets around - children for priority purpose-->
            <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>*<!--midast--></m:mo>
              </xsl:when>
              <!-- if some csymbol is used put parentheses around it -->
              <xsl:when test="m:csymbol"> <!--add brackets around - children for priority purpose-->
            <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>*<!--midast--></m:mo>
              </xsl:when>
              <xsl:otherwise>
            <xsl:apply-templates select="."/><m:mo>*<!--midast--></m:mo>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
          <xsl:for-each select="child::*[position()=last()]">
            <xsl:choose>
              <xsl:when test="m:plus">
            <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
              </xsl:when>
              <xsl:when test="m:minus">
            <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
              </xsl:when>
              <!-- if some csymbol is used put parentheses around it -->
              <xsl:when test="m:csymbol">
            <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
              </xsl:when>
              <xsl:when test="(local-name(.)='ci' or local-name(.)='cn') and contains(text(),'-')"> <!-- have to do it using contains because starts-with doesn't seem to work well in  XT-->
            <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
              </xsl:when>
              <xsl:otherwise>
            <xsl:apply-templates select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </m:mrow>
      </xsl:when>
      <xsl:when test="count(child::*)=2">  <!-- unary -->
        <m:mrow>
          <m:mo>*<!--midast--></m:mo>
          <xsl:choose>
            <xsl:when test="m:plus">
              <m:mfenced separators=" "><xsl:apply-templates select="*[position()=2]"/></m:mfenced>
            </xsl:when>
            <xsl:when test="m:minus">
              <m:mfenced separators=" "><xsl:apply-templates select="*[position()=2]"/></m:mfenced>
            </xsl:when>
            <xsl:when test="(*[position()=2 and self::m:ci] or *[position()=2 and self::m:cn]) and contains(*[position()=2]/text(),'-')">
              <m:mfenced separators=" "><xsl:apply-templates select="*[position()=2]"/></m:mfenced>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="*[position()=2]"/>
            </xsl:otherwise>
          </xsl:choose>
        </m:mrow>
      </xsl:when>
      <xsl:otherwise>  <!-- no operand -->
        <m:mo>*<!--midast--></m:mo>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Adjoint -->
  <!-- FIXME: the notation here really needs to be customizable -->
  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='csymbol' and
            @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#adjoint']]">
    <m:msup accent="true">
      <xsl:choose>
        <xsl:when test="child::m:apply">
          <m:mfenced><m:mrow><xsl:apply-templates select="*[position()=2]"/></m:mrow></m:mfenced>
        </xsl:when>
        <xsl:otherwise>
          <m:mrow><xsl:apply-templates select="*[position()=2]"/></m:mrow>
        </xsl:otherwise>
      </xsl:choose>
      <m:mo>H</m:mo>
    </m:msup>
  </xsl:template>

 <!-- norm -->
  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='csymbol' and
            @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#norm']]">
    <xsl:choose>
      <xsl:when test="m:domainofapplication">
        <m:mrow>
          <m:msub>
            <m:mrow>
              <m:mo>&#8741;<!--DoubleVerticalBar--></m:mo>
              <xsl:apply-templates select="child::*[position()=3]"/>
              <m:mo>&#8741;<!--DoubleVerticalBar--></m:mo>
            </m:mrow>
            <m:mrow>
              <xsl:apply-templates select="*[position()=2 and
              local-name()='domainofapplication']"/>
            </m:mrow>
          </m:msub>
        </m:mrow>
      </xsl:when>
      <xsl:otherwise>
        <m:mrow>
          <m:mo>&#8741;<!--DoubleVerticalBar--></m:mo>
          <xsl:apply-templates select="child::*[position()=2]"/>
          <m:mo>&#8741;<!--DoubleVerticalBar--></m:mo>
        </m:mrow>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Evaluated At -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:csymbol and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#evaluateat']]">
    <m:mrow>
      <xsl:choose>
        <xsl:when test="m:condition"> <!-- evaluation expressed by a condition-->
          <xsl:apply-templates select="*[position()=last()]"/>
          <xsl:choose>
            <xsl:when test="m:bvar">
              <m:msub>
            <m:mo>|</m:mo>
            <m:mrow>
              <xsl:apply-templates select="m:bvar"/>
              <m:mo>,</m:mo>
              <xsl:apply-templates select="m:bvar"/>
              <m:mo>=</m:mo>
              <xsl:apply-templates select="m:condition"/>
            </m:mrow>
              </m:msub>
            </xsl:when>
            <xsl:otherwise>
              <m:msub>
            <m:mrow><m:mo>|</m:mo></m:mrow>
            <m:mrow>
              <xsl:for-each select="m:condition[position()!=last()]"><xsl:apply-templates/><m:mo>,</m:mo></xsl:for-each>
              <xsl:for-each select="m:condition[position()=last()]"><xsl:apply-templates/></xsl:for-each>
            </m:mrow>
              </m:msub>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="m:interval"> <!-- evaluation expressed by an interval-->
              <xsl:apply-templates select="*[position()=last()]"/>
              <xsl:choose>
            <xsl:when test="m:bvar">
              <m:msubsup>
                <m:mo>|</m:mo>
                <m:mrow>
                  <xsl:apply-templates select="m:bvar"/>
                  <m:mo>=</m:mo>
                  <xsl:apply-templates select="m:interval/*[position()=1]"/>
                </m:mrow>
                <xsl:apply-templates select="m:interval/*[position()=2]"/>
              </m:msubsup>
            </xsl:when>
            <xsl:otherwise>
              <m:msubsup>
                <m:mo>|</m:mo>
                <xsl:apply-templates select="m:interval/*[position()=1]"/>
                <xsl:apply-templates select="m:interval/*[position()=2]"/>
              </m:msubsup>
            </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="m:lowlimit"> <!-- evaluation domain expressed by lower and upper limits-->
              <xsl:apply-templates select="*[position()=last()]"/>
              <xsl:choose>
            <xsl:when test="m:bvar">
              <m:msubsup>
                <m:mo>|</m:mo>
                <m:mrow>
                  <xsl:apply-templates select="m:bvar"/>
                  <m:mo>=</m:mo>
                  <xsl:apply-templates select="m:lowlimit/*"/>
                </m:mrow>
                <m:mrow><xsl:apply-templates select="m:uplimit/*"/></m:mrow>
              </m:msubsup>
            </xsl:when>
            <xsl:otherwise>
              <m:msubsup>
                <m:mo>|</m:mo>
                <xsl:apply-templates select="m:lowlimit/*"/>
                <xsl:apply-templates select="m:uplimit/*"/>
              </m:msubsup>
            </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </m:mrow>
  </xsl:template>

  <!-- Surface Integral -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:csymbol and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#surfaceintegral']]">
    <m:mrow>
      <xsl:choose>
        <xsl:when test="m:condition"> <!-- surface integration domain expressed by a condition-->
          <m:munder>
            <m:mo>&#8750;<!--conint--></m:mo>
            <xsl:apply-templates select="m:condition"/>
          </m:munder>
          <m:mrow><xsl:apply-templates select="*[position()=last()]"/></m:mrow>
          <m:mrow><m:mo>d<!--DifferentialD does not work--></m:mo><xsl:apply-templates select="m:bvar"/></m:mrow>
        </xsl:when>
        <xsl:when test="m:domainofapplication"> <!-- surface integration domain expressed by a domain of application-->
          <m:munder>
            <m:mo>&#8750;<!--conint--></m:mo>
            <xsl:apply-templates select="m:domainofapplication"/>
          </m:munder>
          <m:mrow><xsl:apply-templates select="*[position()=last()]"/></m:mrow>
          <m:mrow><m:mo>d<!--DifferentialD does not work--></m:mo><xsl:apply-templates select="m:bvar"/></m:mrow>  <!--not sure about this line: can get rid of it if there is never a bvar elem when integ domain specified by domainofapplication-->
        </xsl:when>
        <xsl:when test="m:lowlimit"><!-- surface integration expressed
          by lowlimit and uplimit -->
          <m:munderover>
            <m:mo>&#8750;<!--conint--></m:mo>
            <m:mrow><xsl:apply-templates select="m:lowlimit/*"/></m:mrow>
            <m:mrow><xsl:apply-templates select="m:uplimit/*"/></m:mrow>
          </m:munderover>
          <m:mrow><xsl:apply-templates select="*[position()=last()]"/></m:mrow>
          <m:mrow><m:mo>d<!--DifferentialD does not work--></m:mo><xsl:apply-templates select="m:bvar"/></m:mrow>
        </xsl:when>
        <xsl:otherwise><!-- surface integral with no condition -->
          <m:mo>&#8750;<!--conint--></m:mo>
          <m:mrow><xsl:apply-templates select="*[position()=last()]"/></m:mrow>
          <m:mrow><m:mo>d<!--DifferentialD does not
              work--></m:mo><xsl:apply-templates select="m:bvar"/></m:mrow>
        </xsl:otherwise>
      </xsl:choose>
    </m:mrow>
  </xsl:template>

  <!-- arg min -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:csymbol and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#argmin']]">
    <m:mrow>
      <xsl:choose>
        <xsl:when test="m:condition"> <!-- arg min domain expressed by
          a condition-->
          <m:mrow>
            <m:mo>arg</m:mo>
            <m:munder>
              <m:mo>min</m:mo>
              <xsl:apply-templates select="m:condition"/>
            </m:munder>
          </m:mrow>
          <m:mrow><xsl:apply-templates select="*[position()=3]"/></m:mrow>
        </xsl:when>
        <xsl:when test="m:domainofapplication"> <!-- arg min domain
          expressed with domain of application-->
          <m:mrow>
            <m:mo>arg</m:mo>
            <m:munder>
              <m:mo>min</m:mo>
              <xsl:apply-templates select="m:domainofapplication"/>
            </m:munder>
          </m:mrow>
          <m:mrow><xsl:apply-templates select="*[position()=3]"/></m:mrow>
        </xsl:when>
        <xsl:otherwise><!--condition with no condition -->
          <m:mrow>
            <m:mo>arg</m:mo>
            <m:mo>min</m:mo>
            <m:mrow><xsl:apply-templates select="*[position()=last()]"/></m:mrow>
          </m:mrow>
        </xsl:otherwise>
      </xsl:choose>
    </m:mrow>
  </xsl:template>

  <!-- arg max -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:csymbol and @definitionURL='http://cnx.rice.edu/cd/cnxmath.ocd#argmax']]">
    <m:mrow>
      <xsl:choose>
        <xsl:when test="m:condition"> <!-- arg max domain expressed by
          a condition-->
          <m:mrow>
            <m:mo>arg</m:mo>
            <m:munder>
              <m:mo>max</m:mo>
              <xsl:apply-templates select="m:condition"/>
            </m:munder>
          </m:mrow>
          <m:mrow><xsl:apply-templates select="*[position()=3]"/></m:mrow>
        </xsl:when>
        <xsl:when test="m:domainofapplication"> <!-- arg max domain
          expressed with domain of application-->
          <m:mrow>
            <m:mo>arg</m:mo>
            <m:munder>
              <m:mo>max</m:mo>
              <xsl:apply-templates select="m:domainofapplication"/>
            </m:munder>
          </m:mrow>
          <m:mrow><xsl:apply-templates select="*[position()=3]"/></m:mrow>
        </xsl:when>
        <xsl:otherwise><!-- arg max with no condition -->
          <m:mrow>
            <m:mo>arg</m:mo>
            <m:mo>max</m:mo>
            <m:mrow><xsl:apply-templates select="*[position()=last()]"/></m:mrow>
          </m:mrow>
        </xsl:otherwise>
      </xsl:choose>
    </m:mrow>
  </xsl:template>

  <!-- Presentation Changes -->

  <!-- apply/apply/diff formatting change-->

  <xsl:template mode="c2p" match="m:apply[*[1][self::m:apply and *[1][self::m:diff] ]]">
    <xsl:choose>
      <xsl:when test="count(child::*)&gt;=2">
        <m:mrow>
          <xsl:apply-templates select="*[1]"/>
          <m:mfenced><xsl:apply-templates select="*[position()!=1]"/></m:mfenced>
        </m:mrow>
      </xsl:when>
      <xsl:otherwise><!-- apply only contains apply, no operand
        -->
        <m:mfenced separators=" "><xsl:apply-templates select="child::*"/></m:mfenced>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--apply/forall formatting change with parameter -->

  <xsl:template mode="c2p" match="m:apply[*[1][self::m:forall]]">
    <xsl:choose>
      <xsl:when test="$forallequation">
        <m:mrow>
          <xsl:apply-templates select="child::*[local-name()='ci' or local-name()='apply'or local-name()='cn' or local-name()='mo']"/>
          <m:mo>&#160;<!--nbsp-->&#160;<!--nbsp--></m:mo>
          <xsl:if test="m:condition">
            <m:mo>,</m:mo>
            <m:mo>&#160;<!--nbsp-->&#160;<!--nbsp--></m:mo>
            <xsl:for-each select="m:condition">
              <xsl:apply-templates/>
              <m:mo>&#160;<!--nbsp-->&#160;<!--nbsp--></m:mo>
            </xsl:for-each>
          </xsl:if>
        </m:mrow>
      </xsl:when>
      <xsl:otherwise>
 <m:mrow>
  <m:mi>&#8704;<!--forall--></m:mi>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:bvar"/></m:mrow>
 <xsl:if test="m:bvar and m:condition">
   <m:mo>,</m:mo>
 </xsl:if>
 <xsl:apply-templates mode="c2p" select="m:condition/*"/>
 <m:mo>:</m:mo>
 <m:mfenced>
  <xsl:apply-templates mode="c2p" select="*[last()]"/>
 </m:mfenced>
</m:mrow>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- Parameters -->

  <!-- Mean Notation choice -->

  <xsl:template mode="c2p" match="m:apply[*[1][self::m:mean]]">
    <xsl:choose>
      <xsl:when test="$meannotation='anglebracket'"><!--use angle
        notation -->
        <xsl:choose>
          <xsl:when test="count(*)&gt;2">
            <m:mo>&#9001;<!--lang--></m:mo>
            <xsl:for-each select="*[position()!=1 and position()!=last()]">
              <xsl:apply-templates select="."/><m:mo>,</m:mo>
            </xsl:for-each>
            <xsl:apply-templates select="*[position()=last()]"/>
            <m:mo>&#9002;<!--rang--></m:mo>
          </xsl:when>
          <xsl:otherwise>
            <m:mo>&#9001;<!--lang--></m:mo>
              <xsl:apply-templates select="*[position()=last()]"/>
            <m:mo>&#9002;<!--rang--></m:mo>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- Use an overbar instead of angle brackets -->
        <!-- 4.4.9.1 mean -->
        <m:mover>
          <m:mrow>
            <xsl:for-each select="*[position()&gt;1]">
              <xsl:apply-templates mode="c2p" select="."/>
              <xsl:if test="position() !=last()"><m:mo>,</m:mo></xsl:if>
            </xsl:for-each>
          </m:mrow>
          <m:mo stretchy="true">-<!--dash--></m:mo>
        </m:mover>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Vector notation choice -->

  <xsl:template mode="c2p" match="m:ci[@type='vector']">
    <xsl:choose>

      <xsl:when test="$vectornotation='overbar'">
        <!--vector with overbar -->
        <xsl:choose>
          <xsl:when test="count(node()) != count(text())">
            <!--test if children are not all text nodes, meaning there
            is markup assumed to be presentation markup-->
            <xsl:choose>
              <xsl:when test="child::*[position()=1 and
                local-name()='msub']"><!-- test to see if the first
            child is msub so that the subscript will not be bolded -->
            <m:msub>
              <m:mover><m:mi><xsl:apply-templates select="./m:msub/child::*[position()=1]"/></m:mi><m:mo>&#8722;<!--minus--></m:mo></m:mover>
              <m:mrow><xsl:apply-templates select="./m:msub/child::*[position()=2]"/></m:mrow>
            </m:msub>
              </xsl:when>
              <xsl:otherwise>
            <m:mrow><xsl:copy-of select="child::*"/></m:mrow>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>  <!-- common case -->
            <m:mover><m:mi><xsl:value-of select="text()"/></m:mi><m:mo>&#8722;<!--minus--></m:mo></m:mover>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="$vectornotation='rightarrow'">
        <!--vector with rightarrow over -->
        <xsl:choose>
          <xsl:when test="count(node()) != count(text())">
            <!--test if children are not all text nodes, meaning there
            is markup assumed to be presentation markup-->
            <xsl:choose>
              <xsl:when test="child::*[position()=1 and
                local-name()='msub']"><!-- test to see if the first child
            is msub so that the subscript will not be bolded -->
            <m:msub>
              <m:mover><m:mi><xsl:apply-templates select="./m:msub/child::*[position()=1]"/></m:mi><m:mo>&#8640;<!--rharu--></m:mo></m:mover>
              <m:mrow><xsl:apply-templates select="./m:msub/child::*[position()=2]"/></m:mrow>
            </m:msub>
              </xsl:when>
              <xsl:otherwise>
            <m:mrow><xsl:copy-of select="child::*"/></m:mrow>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>  <!-- common case -->
            <m:mover><m:mi><xsl:value-of select="text()"/></m:mi><m:mo>&#8640;<!--rharu--></m:mo></m:mover>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <!-- vector bolded -->
        <m:mrow>
          <xsl:apply-imports/>
        </m:mrow>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<xsl:template mode="c2p" match="m:ci[@type='vector']/text()">
  <xsl:choose>
    <xsl:when test="$vectornotation=''">
      <m:mi fontweight="bold"><xsl:value-of select="."/></m:mi>
    </xsl:when>
    <xsl:otherwise>
      <xsl:apply-imports/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

  <!-- And/Or notation choice -->

  <!-- AND -->
  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='and']]">
    <xsl:choose>
      <xsl:when test="$andornotation='text'"><!-- text notation -->
        <xsl:choose>
          <xsl:when test="count(*)&gt;=3"> <!-- at least two operands (common case)-->
            <xsl:for-each select="child::*[position()!=last() and  position()!=1]">
              <xsl:choose>
            <xsl:when test="m:or"> <!--add brackets around OR children for priority purpose-->
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>&#160;<!--nbsp-->and&#160;<!--nbsp--></m:mo>
            </xsl:when>
            <xsl:when test="m:xor"> <!--add brackets around XOR children for priority purpose-->
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>&#160;<!--nbsp-->and&#160;<!--nbsp--></m:mo>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="."/><m:mo>&#160;<!--nbsp-->and&#160;<!--nbsp--></m:mo>
            </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <xsl:for-each select="child::*[position()=last()]">
              <xsl:choose>
            <xsl:when test="m:or">
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
            </xsl:when>
            <xsl:when test="m:xor">
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="."/>
            </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="count(*)=2">
            <m:mo>&#160;<!--nbsp-->and&#160;<!--nbsp--></m:mo><xsl:apply-templates select="*[position()=last()]"/>
          </xsl:when>
          <xsl:otherwise>
            <m:mo>&#160;<!--nbsp-->and&#160;<!--nbsp--></m:mo>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- statistical logic notation -->
      <xsl:when test="$andornotation='statlogicnotation'">
        <xsl:choose>
          <xsl:when test="count(*)&gt;=3"> <!-- at least two operands (common case)-->
            <xsl:for-each select="child::*[position()!=last() and  position()!=1]">
              <xsl:choose>
            <xsl:when test="m:or"> <!--add brackets around OR children for priority purpose-->
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>&#160;<!--nbsp-->&amp;&#160;<!--nbsp--></m:mo>
            </xsl:when>
            <xsl:when test="m:xor"> <!--add brackets around XOR children for priority purpose-->
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>&#160;<!--nbsp-->&amp;&#160;<!--nbsp--></m:mo>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="."/><m:mo>&#160;<!--nbsp-->&amp;&#160;<!--nbsp--></m:mo>
            </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <xsl:for-each select="child::*[position()=last()]">
              <xsl:choose>
            <xsl:when test="m:or">
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
            </xsl:when>
            <xsl:when test="m:xor">
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="."/>
            </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="count(*)=2">
            <m:mo>&#160;<!--nbsp-->&amp;&#160;<!--nbsp--></m:mo><xsl:apply-templates select="*[position()=last()]"/>
          </xsl:when>
          <xsl:otherwise>
            <m:mo>&#160;<!--nbsp-->&amp;&#160;<!--nbsp--></m:mo>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <!-- dsp logic notation -->
      <xsl:when test="$andornotation='dsplogicnotation'">
        <xsl:choose>
          <xsl:when test="count(*)&gt;=3"> <!-- at least two operands (common case)-->
            <xsl:for-each select="child::*[position()!=last() and  position()!=1]">
              <xsl:choose>
            <xsl:when test="m:or"> <!--add brackets around OR children for priority purpose-->
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>&#160;<!--nbsp-->&#183;<!--middot-->&#160;<!--nbsp--></m:mo>
            </xsl:when>
            <xsl:when test="m:xor"> <!--add brackets around XOR children for priority purpose-->
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced><m:mo>&#160;<!--nbsp-->&#183;<!--middot-->&#160;<!--nbsp--></m:mo>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="."/><m:mo>&#160;<!--nbsp-->&#183;<!--middot-->&#160;<!--nbsp--></m:mo>
            </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <xsl:for-each select="child::*[position()=last()]">
              <xsl:choose>
            <xsl:when test="m:or">
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
            </xsl:when>
            <xsl:when test="m:xor">
              <m:mfenced separators=" "><xsl:apply-templates select="."/></m:mfenced>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="."/>
            </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </xsl:when>
          <xsl:when test="count(*)=2">
            <m:mo>&#160;<!--nbsp-->&#183;<!--middot-->&#160;<!--nbsp--></m:mo><xsl:apply-templates select="*[position()=last()]"/>
          </xsl:when>
          <xsl:otherwise>
            <m:mo>&#160;<!--nbsp-->&#183;<!--middot-->&#160;<!--nbsp--></m:mo>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='or']]">
    <xsl:choose>
      <xsl:when test="$andornotation='text'"><!-- text
      notation -->
        <m:mrow>
          <xsl:choose>
            <xsl:when test="count(*)&gt;=3">
              <xsl:for-each select="child::*[position()!=last() and  position()!=1]">
            <xsl:apply-templates select="."/><m:mo>&#160;<!--nbsp-->or&#160;<!--nbsp--></m:mo>
              </xsl:for-each>
              <xsl:apply-templates select="child::*[position()=last()]"/>
            </xsl:when>
            <xsl:when test="count(*)=2">
              <m:mo>&#160;<!--nbsp-->or&#160;<!--nbsp--></m:mo><xsl:apply-templates select="*[position()=last()]"/>
            </xsl:when>
            <xsl:otherwise>
              <m:mo>&#160;<!--nbsp-->or&#160;<!--nbsp--></m:mo>
            </xsl:otherwise>
          </xsl:choose>
        </m:mrow>
      </xsl:when>
      <!--statistical logic notation -->
      <xsl:when test="$andornotation='statlogicnotation'">
        <m:mrow>
          <xsl:choose>
            <xsl:when test="count(*)&gt;=3">
              <xsl:for-each select="child::*[position()!=last() and  position()!=1]">
            <xsl:apply-templates select="."/><m:mo>|</m:mo>
              </xsl:for-each>
              <xsl:apply-templates select="child::*[position()=last()]"/>
            </xsl:when>
            <xsl:when test="count(*)=2">
              <m:mo>&#160;<!--nbsp-->|&#160;<!--nbsp--></m:mo><xsl:apply-templates select="*[position()=last()]"/>
            </xsl:when>
            <xsl:otherwise>
              <m:mo>&#160;<!--nbsp-->|&#160;<!--nbsp--></m:mo>
            </xsl:otherwise>
          </xsl:choose>
        </m:mrow>
      </xsl:when>
      <!-- dsp logic notation -->
      <xsl:when test="$andornotation='dsplogicnotation'">
        <m:mrow>
          <xsl:choose>
            <xsl:when test="count(*)&gt;=3">
              <xsl:for-each select="child::*[position()!=last() and  position()!=1]">
            <xsl:apply-templates select="."/><m:mo>&#160;<!--nbsp-->+&#160;<!--nbsp--></m:mo>
              </xsl:for-each>
              <xsl:apply-templates select="child::*[position()=last()]"/>
            </xsl:when>
            <xsl:when test="count(*)=2">
              <m:mo>&#160;<!--nbsp-->+&#160;<!--nbsp--></m:mo><xsl:apply-templates select="*[position()=last()]"/>
            </xsl:when>
            <xsl:otherwise>
              <m:mo>&#160;<!--nbsp-->+&#160;<!--nbsp--></m:mo>
            </xsl:otherwise>
          </xsl:choose>
        </m:mrow>
      </xsl:when>

      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Real/Imaginary notation choice -->

  <!-- real part of complex number -->
  <xsl:template mode="c2p" match="m:real">
    <xsl:choose>
      <xsl:when test="$realimaginarynotation='text'">
        <m:mi>Re</m:mi>
      </xsl:when>
      <xsl:otherwise>
        <!-- 4.4.3.22 real -->
        <m:mo>&#8476;<!-- real --></m:mo>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- imaginary part of complex number -->
  <xsl:template mode="c2p" match="m:imaginary">
    <xsl:choose>
      <xsl:when test="$realimaginarynotation='text'">
        <m:mi>Im</m:mi>
      </xsl:when>
      <xsl:otherwise>
        <!-- 4.4.3.23 imaginary -->
        <m:mo>&#8465;<!-- imaginary --></m:mo>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Conjugate Notation -->

  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='conjugate']]">
    <xsl:choose>
      <xsl:when test="$conjugatenotation='engineeringnotation'"><!-- asterik notation -->
        <m:msup>
          <xsl:apply-templates mode="c2p" select="child::*[position()=2]">
            <xsl:with-param name="p" select="5"/>
          </xsl:apply-templates>
          <m:mo>*</m:mo>
        </m:msup>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Gradient and Curl Notation -->

  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='grad']]">
    <xsl:choose>
      <xsl:when test="$gradnotation='symbolicnotation'">
        <m:mrow>
          <m:mo>&#8711;<!--nabla--></m:mo>
          <xsl:choose>
            <xsl:when test="local-name(*[position()=2])='apply' or ((local-name(*[position()=2])='ci' or local-name(*[position()=2])='cn') and contains(*[position()=2]/text(),'-'))">
              <m:mfenced separators=" ">
            <xsl:apply-templates select="child::*[position()=2]"/>
              </m:mfenced>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="child::*[position()=2]"/>
            </xsl:otherwise>
          </xsl:choose>
        </m:mrow>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template mode="c2p" match="m:apply[child::*[position()=1 and
            local-name()='curl']]">
    <xsl:choose>
      <xsl:when test="$curlnotation='symbolicnotation'">
        <m:mrow>
          <m:mo>&#8711;<!--nabla--></m:mo>
          <m:mo>&#215;<!--times--></m:mo>
          <xsl:choose>
            <xsl:when test="local-name(*[position()=2])='apply' or ((local-name(*[position()=2])='ci' or local-name(*[position()=2])='cn') and contains(*[position()=2]/text(),'-'))">
              <m:mfenced separators=" ">
            <xsl:apply-templates select="child::*[position()=2]"/>
              </m:mfenced>
            </xsl:when>
            <xsl:otherwise>
              <xsl:apply-templates select="child::*[position()=2]"/>
            </xsl:otherwise>
          </xsl:choose>
        </m:mrow>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Remainder Notation -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:rem]]">
    <xsl:choose>
      <xsl:when test="$remainder='remainder_anglebrackets'">
        <m:mrow>
          <m:msub>
            <m:mrow>
              <m:mo>&#9001;<!--lang--></m:mo>
              <xsl:apply-templates select="child::*[position()=2]"/>
              <m:mo>&#9002;<!--rang--></m:mo>
            </m:mrow>
            <xsl:apply-templates select="child::*[position()=3]"/>
          </m:msub>
        </m:mrow>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- differentiation -->
<xsl:template match="m:apply[*[1][self::m:diff and not(@definitionURL)]]">
  <m:mrow>
    <xsl:choose>
      <!-- If there's a bound-variable, use Leibniz notation-->
      <xsl:when test="m:bvar">
        <xsl:choose>
          <xsl:when test="m:bvar/m:degree">
            <!-- if the order of the derivative is specified-->
            <xsl:choose>
              <xsl:when test="normalize-space(m:bvar/m:degree/m:cn/text()) = '1'">
                <m:mfrac>
                  <m:mo>d<!--DifferentialD does not work--></m:mo>
                  <m:mrow>
                    <m:mo>d<!--DifferentialD does not work--></m:mo>
                    <xsl:apply-templates select="m:bvar/*[not(self::m:degree)]"/>
                  </m:mrow>
                </m:mfrac>
                <m:mrow>
                  <xsl:choose>
                    <xsl:when test="m:apply[position()=last()]/*[1][self::m:fn] or m:apply[position()=last()]/m:ci[@type='fn'] or m:matrix">
                      <xsl:apply-templates select="*[position()=last()]"/>
                    </xsl:when>
                    <!--add brackets around expression if not a function-->
                    <xsl:otherwise>
                      <m:mfenced separators=" ">
                        <xsl:apply-templates select="*[position()=last()]"/>
                      </m:mfenced>
                    </xsl:otherwise>
                  </xsl:choose>
                </m:mrow>
              </xsl:when>
              <xsl:otherwise>
                <!-- if the order of the derivative is not 1-->
                <m:mfrac>
                  <m:mrow>
                    <m:msup>
                      <m:mo>d<!--DifferentialD does not work-->
                      </m:mo>
                      <m:mrow>
                        <xsl:apply-templates select="m:bvar/m:degree"/>
                      </m:mrow>
                    </m:msup>
                  </m:mrow>
                  <m:mrow>
                    <m:mo>d<!--DifferentialD does not work-->
                    </m:mo>
                    <m:msup>
                      <m:mrow>
                        <xsl:apply-templates select="m:bvar/*[not(self::m:degree)]"/>
                      </m:mrow>
                      <m:mrow>
                        <xsl:apply-templates select="m:bvar/m:degree"/>
                      </m:mrow>
                    </m:msup>
                  </m:mrow>
                </m:mfrac>
                <m:mrow>
                  <xsl:choose>
                    <xsl:when test="m:apply[position()=last()]/*[1][self::m:fn] or m:apply[position()=last()]/m:ci[@type='fn'] or m:matrix">
                      <xsl:apply-templates select="*[position()=last()]"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <m:mfenced separators=" ">
                        <xsl:apply-templates select="*[position()=last()]"/>
                      </m:mfenced>
                    </xsl:otherwise>
                  </xsl:choose>
                </m:mrow>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <!-- if no order is specified, default to 1-->
            <m:mfrac>
              <m:mo>d<!--DifferentialD does not work-->
              </m:mo>
              <m:mrow>
                <m:mo>d<!--DifferentialD does not work-->
                </m:mo>
                <xsl:apply-templates select="m:bvar"/>
              </m:mrow>
            </m:mfrac>
            <m:mrow>
              <xsl:choose>
                <xsl:when test="m:apply[position()=last()]/*[1][self::m:fn] or m:apply[position()=last()]/m:ci[@type='fn'] or m:matrix">
                  <xsl:apply-templates select="*[position()=last()]"/>
                </xsl:when>
                <xsl:otherwise>
                  <m:mfenced separators=" ">
                    <xsl:apply-templates select="*[position()=last()]"/>
                  </m:mfenced>
                </xsl:otherwise>
              </xsl:choose>
            </m:mrow>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Otherwise use prime notation -->
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="m:degree">
            <m:msup>
              <m:mrow>
                <xsl:apply-templates select="child::*[not(self::m:degree) and position() &gt; 1]"/>
              </m:mrow>
              <m:mrow>
                <xsl:choose>
                  <xsl:when test="m:degree/m:ci">
                    <xsl:apply-templates select="m:degree/m:ci"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="normalize-space(m:degree/m:cn/text()) >= '4'">
                        <m:mn><xsl:value-of select="m:degree/m:cn/text()"/></m:mn>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:call-template name="c2p.differentiation-degree">
                          <xsl:with-param name="degreemax">
                            <xsl:value-of select="m:degree/m:cn/text()"/>
                          </xsl:with-param>
                        </xsl:call-template>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </m:mrow>
            </m:msup>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="m:apply/m:ci[@type='fn']">
                <m:mrow>
                  <m:msup>
                    <xsl:apply-templates select="m:apply/m:ci[1]"/>
                    <m:mo accent="true">&#8242;<!--prime--></m:mo>
                  </m:msup>
                </m:mrow>
                <m:mfenced>
                  <xsl:apply-templates select="child::m:apply/*[position()!='1']"/>
                </m:mfenced>
              </xsl:when>
              <xsl:otherwise>
                <m:msup>
                  <m:mrow>
                    <xsl:apply-templates select="*[position() &gt; 1]"/>
                  </m:mrow>
                  <m:mo accent="true">&#8242;<!--prime--></m:mo>
                </m:msup>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </m:mrow>
</xsl:template>
<xsl:template name="c2p.differentiation-degree">
  <xsl:param name="degreemax"/>
  <m:mo accent="true">&#8242;<!--prime--></m:mo>
  <xsl:if test="not($degreemax = 1)">
    <xsl:call-template name="c2p.differentiation-degree">
      <xsl:with-param name="degreemax">
        <xsl:value-of select="$degreemax - 1"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:template>


  <!-- Override the default match for m:domainofapplication (which produces an m:error) -->
  <xsl:template mode="c2p" match="m:domainofapplication">
    <m:mrow>
      <xsl:apply-templates select="*"/>
      <xsl:if test="following-sibling::m:bvar"><m:mo>,</m:mo></xsl:if>
    </m:mrow>
  </xsl:template>

<!-- 4.4.5.5 uplimit-->
<!-- 4.4.5.7 degree-->
<!-- 4.4.9.5 momentabout -->
<xsl:template mode="c2p" match="m:uplimit|m:degree|m:momentabout">
    <m:error>Did not convert <xsl:value-of select="local-name(..)"/>/<xsl:value-of select="local-name()"/></m:error>
</xsl:template>

<!-- 4.4.5.7 degree -->
<xsl:template mode="c2p" match="m:bvar/m:degree|m:apply/m:degree">
    <xsl:apply-templates mode="c2p"/>
</xsl:template>


<!-- 4.4.1.2 csymbol -->
<!-- Has a type-o in the original code. -->
<xsl:template mode="c2p" match="m:csymbol/text()">
 <m:mo><xsl:value-of select="."/></m:mo>
</xsl:template>

  <!-- Division using the new c2p renders a "/" instead of a fraction bar. This overrides that default -->

  <!-- 4.4.3.3 divide -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:divide]]">
    <m:mfrac>
      <xsl:apply-templates select="*[position()!=1]"/>
    </m:mfrac>
  </xsl:template>

<!-- Only display the "x" between 2 m:cn elements. The rest is verbatim from w3-c2p.xsl -->
<!-- 4.4.3.9  times-->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:times]]" name="times">
  <xsl:param name="p" select="0"/>
  <xsl:param name="first" select="1"/>
  <m:mrow>
  <xsl:if test="($p &gt; 3) or parent::m:apply[*[1][self::m:times]]"><m:mo>(</m:mo></xsl:if>
  <xsl:for-each select="*[position()&gt;1]">
   <xsl:if test="position() &gt; 1">
    <m:mo>
    <xsl:choose>
      <xsl:when test="(self::m:cn and preceding-sibling::m:*[position()=1 and self::m:cn]) or (preceding-sibling::m:cn and self::m:apply[*[position() &lt; 3 and (self::m:cn or self::m:mn)]])">&#215;<!-- times --></xsl:when>
      <xsl:otherwise>&#8290;<!--invisible times--></xsl:otherwise>
    </xsl:choose>
    </m:mo>
   </xsl:if>
   <xsl:if test="position()&gt;= $first">
   <xsl:apply-templates mode="c2p" select=".">
     <xsl:with-param name="p" select="3"/>
   </xsl:apply-templates>
   </xsl:if>
  </xsl:for-each>
  <xsl:if test="($p &gt; 3) or parent::m:apply[*[1][self::m:times]]"><m:mo>)</m:mo></xsl:if>
  </m:mrow>
</xsl:template>


<!-- customize m:sum and m:product to use m:underover instead of m:msubsup -->
<!-- customize how/when m:bvar is rendered -->
<!-- 4.4.7.1 sum -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:sum]]">
  <xsl:call-template name="c2p.sum-product">
    <xsl:with-param name="symbol">&#8721;<!--sum--></xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!-- 4.4.7.2 product -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:product]]">
  <xsl:call-template name="c2p.sum-product">
    <xsl:with-param name="symbol">&#8719;<!--product--></xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="c2p.sum-product">
 <xsl:param name="symbol"/>
 <m:mrow>
 <m:munderover>
  <m:mo><xsl:value-of select="$symbol"/></m:mo>
 <m:mrow>
   <xsl:if test="m:bvar and (m:lowlimit or m:interval or not(m:condition))">
     <xsl:apply-templates select="m:bvar"/>
     <xsl:if test="m:lowlimit|m:interval">
        <m:mi>=</m:mi>
     </xsl:if>
   </xsl:if>
   <xsl:for-each select="m:domainofapplication|m:lowlimit/*|m:interval/*[1]|m:condition/*">
     <xsl:apply-templates mode="c2p" select="."/>
     <xsl:if test="position() != last()">
       <m:mo>,</m:mo>
     </xsl:if>
   </xsl:for-each>
 </m:mrow>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:uplimit/*|m:interval/*[2]"/></m:mrow>
 </m:munderover>
 <xsl:apply-templates mode="c2p" select="*[last()]"/>
</m:mrow>
</xsl:template>

<!-- Either use an 'i' or a 'j' for the imaginary i -->

<!-- 4.4.1.1 cn -->
<xsl:template mode="c2p" match="m:cn[@type='complex-cartesian']">
  <m:mrow>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[1]"/></m:mn>
    <m:mo>+</m:mo>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[2]"/></m:mn>
    <m:mo>&#8290;<!--invisible times--></m:mo>
    <xsl:call-template name="cnx.c2p.imaginaryi"/>
  </m:mrow>
</xsl:template>

<!-- 4.4.12.8 imaginaryi -->
<xsl:template mode="c2p" match="m:imaginaryi" name="cnx.c2p.imaginaryi">
  <xsl:choose>
    <xsl:when test="$imaginaryi = 'j'">
      <m:mi>j<!-- imaginary j--></m:mi>
    </xsl:when>
    <xsl:otherwise>
      <m:mi>i<!-- imaginary i--></m:mi>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Use angle brackets instead of a period -->
<!-- 4.4.10.7 scalarproduct-->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:scalarproduct]]">
<xsl:param name="p" select="0"/>
<xsl:choose>
  <xsl:when test="$scalarproductnotation='dotnotation'"><!--dot
  notation -->
    <m:mrow>
      <xsl:apply-templates select="*[position()=2]"/>
      <m:mo>&#160;<!--nbsp-->&#183;<!--middot-->&#160;<!--nbsp--></m:mo>
      <xsl:apply-templates select="*[position()=3]"/>
    </m:mrow>
  </xsl:when>
  <xsl:otherwise>
    <m:mrow>
      <m:mo>&#9001;<!--langle--></m:mo>
      <xsl:call-template name="infix">
        <xsl:with-param name="this-p" select="2"/>
        <xsl:with-param name="p" select="$p"/>
        <xsl:with-param name="mo"><m:mo>,</m:mo></xsl:with-param>
      </xsl:call-template>
      <m:mo>&#9002;<!--rangle--></m:mo>
    </m:mrow>
  </xsl:otherwise>
</xsl:choose>
</xsl:template>

<!-- 4.4.9.10 outerproduct -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:outerproduct]]">
<xsl:param name="p" select="0"/>
  <xsl:call-template name="binary">
    <xsl:with-param name="this-p" select="2"/>
    <xsl:with-param name="p" select="$p"/>
    <xsl:with-param name="mo"><m:mo>&#x2295;<!--circledPlus--></m:mo></xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!-- Add parentheses around the trig func -->
<!-- 4.4.8.1 trig -->
<xsl:template mode="c2p" match="m:apply[*[1][
 self::m:sin or self::m:cos or self::m:tan or self::m:sec or
 self::m:csc or self::m:cot or self::m:sinh or self::m:cosh or
 self::m:tanh or self::m:sech or self::m:csch or self::m:coth or
 self::m:arcsin or self::m:arccos or self::m:arctan or self::m:arccosh
 or self::m:arccot or self::m:arccoth or self::m:arccsc or
 self::m:arccsch or self::m:arcsec or self::m:arcsech or
 self::m:arcsinh or self::m:arctanh or self::m:ln]]">
<m:mrow>
<m:mi><xsl:value-of select="local-name(*[1])"/></m:mi>
<m:mfenced open="(" close=")">
  <xsl:apply-templates mode="c2p" select="*[2]">
    <xsl:with-param name="p" select="0"/>
  </xsl:apply-templates>
</m:mfenced>
</m:mrow>
</xsl:template>


<!-- Display vectors vectors vertically instead of horizontally -->
<!-- 4.4.10.1 vector  -->
<xsl:template mode="c2p" match="m:vector">
<m:mfenced separator=" ">
  <m:mtable>
    <xsl:for-each select="*">
      <m:mtr><m:mtd>
        <xsl:apply-templates mode="c2p" select="."/>
      </m:mtd></m:mtr>
    </xsl:for-each>
  </m:mtable>
</m:mfenced>
</xsl:template>

<!-- Display vectors horizontally when inline -->
<xsl:template mode="c2p" match="m:math[@display='inline']//m:vector">
<m:msup>
<m:mfenced separator=" ">
  <xsl:apply-templates mode="c2p" select="*"/>
</m:mfenced>
<m:mi>T</m:mi>
</m:msup>
</xsl:template>

<!-- Use the angle character instead of "arg" since people misuse it (see m0028) -->
<!-- 4.4.3.21 arg -->
<xsl:template mode="c2p" match="m:arg">
 <m:mo>&#x2220;<!--langle--></m:mo>
</xsl:template>


<!-- Use circledPlus for xor -->
<!-- 4.4.3.14 xor -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:xor]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="3"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#x2295;<!--circledPlus--></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>


<!-- Lists should render with square brackets not parentheses -->
<!-- 4.4.6.2 list -->
<xsl:template mode="c2p" match="m:list">
  <xsl:call-template name="set">
   <xsl:with-param name="o" select="'['"/>
   <xsl:with-param name="c" select="']'"/>
  </xsl:call-template>
</xsl:template>

<!-- Add a case for m:otherwise -->
<!-- 4.4.2.16 piecewise -->
<xsl:template mode="c2p" match="m:piecewise">
<m:mrow>
  <m:mo>{</m:mo>
  <m:mtable columnalign="left">
    <xsl:for-each select="m:piece">
      <m:mtr>
        <m:mtd>
          <xsl:apply-templates mode="c2p" select="*[1]"/>
          <m:mtext>&#160; if &#160;</m:mtext>
          <xsl:apply-templates mode="c2p" select="*[2]"/>
        </m:mtd>
      </m:mtr>
    </xsl:for-each>
    <xsl:if test="m:otherwise">
      <m:mtr>
        <m:mtd>
          <xsl:apply-templates mode="c2p" select="m:otherwise/*[1]"/>
          <m:mtext>&#160; otherwise &#160;</m:mtext>
        </m:mtd>
      </m:mtr>
    </xsl:if>
  </m:mtable>
</m:mrow>
</xsl:template>

<!-- always render bvar's. Change "." to ":". Add in a comma between bvars and condition -->
<!-- 4.4.3.18 exists -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:exists]]">
<m:mrow>
 <m:mi>&#8707;<!--exists--></m:mi>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:bvar"/></m:mrow>
 <xsl:if test="m:bvar and m:condition">
   <m:mo>,</m:mo>
 </xsl:if>
 <xsl:apply-templates mode="c2p" select="m:condition/*"/>
 <m:mo>:</m:mo>
 <m:mfenced>
  <xsl:apply-templates mode="c2p" select="*[last()]"/>
 </m:mfenced>
</m:mrow>
</xsl:template>

<!-- MathJax has a problem rendering m:mn[.//m:mn] so convert m:cn's with a m:mn into m:mrow -->
<xsl:template mode="c2p" match="m:cn[.//m:mn]">
<m:mrow>
  <xsl:apply-templates mode="c2p" select="node()"/>
</m:mrow>
</xsl:template>

<!--
  This is added to fix the "a & b => c" bug which should add parentheses around "b => c".
  Note: I swapped the order of precedence from the original c2p XSLT.
  https://trac.rhaptos.org/trac/rhaptos/ticket/8045

  Also, m:implies and m:minus did not add parentheses around nested implies
  which should also be fixed.

  - Phil Schatz
-->

  <!-- 4.4.3.5  minus-->
  <!-- m:minus is NOT associative, so pass an extra param to "binary"
-->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:minus] and count(*)&gt;2]">
    <xsl:param name="p" select="0"/>
    <xsl:call-template name="binary">
      <xsl:with-param name="mo"><m:mo>&#8722;<!--minus--></m:mo></xsl:with-param>
      <xsl:with-param name="p" select="$p"/>
      <xsl:with-param name="this-p" select="2.1"/>
      <xsl:with-param name="associative" select="'left'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Custom "implies" -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:implies]]">
    <xsl:param name="p" select="0"/>
    <xsl:call-template name="binary">
      <xsl:with-param name="mo">
        <m:mo>&#8658;<!-- Rightarrow --></m:mo>
      </xsl:with-param>
      <xsl:with-param name="p" select="$p"/>
      <xsl:with-param name="this-p" select="1.5"/>
      <xsl:with-param name="associative" select="'left'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- Custom "and" -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:and]]">
    <xsl:param name="p" select="0"/>
    <xsl:variable name="separator">
    <xsl:choose>
        <xsl:when test="$andornotation = 'text'"> and </xsl:when>
        <xsl:when test="$andornotation = 'statlogicnotation'">&amp;</xsl:when>
        <xsl:when test="$andornotation = 'dsplogicnotation'">&#183;<!-- TODO Middle dot entity --></xsl:when>
        <xsl:otherwise>&#8743;<!-- and --></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="infix">
      <xsl:with-param name="this-p" select="3"/>
      <xsl:with-param name="p" select="$p"/>
      <xsl:with-param name="mo">
        <m:mspace width=".3em"/><m:mo><xsl:value-of select="$separator"/></m:mo><m:mspace width=".3em"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- Custom "or" -->
  <xsl:template mode="c2p" match="m:apply[*[1][self::m:or]]">
    <xsl:param name="p" select="0"/>
    <xsl:variable name="separator">
    <xsl:choose>
        <xsl:when test="$andornotation = 'text'"> or </xsl:when>
        <xsl:when test="$andornotation = 'statlogicnotation'">|</xsl:when>
        <xsl:when test="$andornotation = 'dsplogicnotation'">+</xsl:when>
        <xsl:otherwise>&#8744;<!-- or --></xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="infix">
      <xsl:with-param name="this-p" select="2"/>
      <xsl:with-param name="p" select="$p"/>
      <xsl:with-param name="mo">
        <m:mspace width=".3em"/><m:mo><xsl:value-of select="$separator"/></m:mo><m:mspace width=".3em"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

<!-- ****************************** -->
<xsl:template name="infix">
  <xsl:param name="mo"/>
  <xsl:param name="p" select="0"/>
  <xsl:param name="this-p" select="0"/>
  <m:mrow>
  <xsl:if test="$this-p &lt; $p"><m:mo>(</m:mo></xsl:if>
  <xsl:if test="count(*) = 1">
   <xsl:copy-of select="$mo"/>
  </xsl:if>
  <xsl:for-each select="*[position()&gt;1]">
   <xsl:if test="position() &gt; 1">
    <xsl:copy-of select="$mo"/>
   </xsl:if>
   <xsl:apply-templates mdoe="c2p" select=".">
     <xsl:with-param name="p" select="$this-p"/>
   </xsl:apply-templates>
  </xsl:for-each>
  <xsl:if test="$this-p &lt; $p"><m:mo>)</m:mo></xsl:if>
  </m:mrow>
</xsl:template>

  <!-- m:implies and m:minus are NOT associative, so we need to add parentheses
-->
  <xsl:template name="binary">
    <xsl:param name="mo"/>
    <xsl:param name="p" select="0"/>
    <xsl:param name="this-p" select="0"/>
    <xsl:param name="associative" select="''"/><!-- can be: '' (both), 'none', or TODO 'left', 'right'
-->
    <xsl:variable name="parent-op" select="local-name(../m:*[1])"/>
    <m:mrow>
    <xsl:if test="$this-p &lt; $p or ($associative='none' and $parent-op = local-name(m:*[1])) or ($associative='left' and $parent-op = local-name(m:*[1]) and not(following-sibling::*[position()=1]))"><m:mo>(</m:mo></xsl:if>
     <xsl:apply-templates select="*[2]">
       <xsl:with-param name="p" select="$this-p"/>
     </xsl:apply-templates>
     <xsl:copy-of select="$mo"/>
     <xsl:apply-templates select="*[3]">
       <xsl:with-param name="p" select="$this-p"/>
     </xsl:apply-templates>
    <xsl:if test="$this-p &lt; $p or ($associative='none' and $parent-op = local-name(m:*[1])) or ($associative='left' and $parent-op = local-name(m:*[1]) and not(following-sibling::*[position()=1]))"><m:mo>)</m:mo></xsl:if>
    </m:mrow>
  </xsl:template>

<!-- Use infix style for m:ci when there is more than one argument
     For example, "a + b" instead of "+(a, b)"
     See m0046 "We express Fourier transform"
-->
<xsl:template mode="c2p" match="m:apply[*[1][(self::m:ci and m:mo) or self::m:mo] and count(m:*) &gt; 2]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><xsl:apply-templates mode="c2p" select="*[1]"/></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- m:apply with m:ci[@class="discrete"]. Use square brackets -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:ci and @class='discrete'] and count(*) &gt; 1]">
<m:mrow>
  <xsl:apply-templates mode="c2p" select="*[1]">
    <xsl:with-param name="p" select="10"/>
  </xsl:apply-templates>
  <m:mo>&#8290;<!--invisible times--></m:mo>
  <m:mfenced open="[" close="]" separators=",">
    <xsl:apply-templates mode="c2p" select="*[position()>1]"/>
  </m:mfenced>
</m:mrow>
</xsl:template>

<!-- for a m:ci/m:mo just render the m:mo -->
<xsl:template mode="c2p" match="m:ci[m:mo and count(node()) = 1]">
  <xsl:apply-templates mode="c2p" select="m:mo"/>
</xsl:template>

<!-- By default run the rest of the math through the Content-to-Presentation conversion -->
<xsl:template match="m:*">
    <xsl:param name="p" select="0"/>
    <xsl:apply-templates mode="c2p" select=".">
      <xsl:with-param name="p" select="$p"/>
    </xsl:apply-templates>
</xsl:template>


<!-- Any other elements should be copied as-is -->
<xsl:template match="node()|processing-instruction()">
    <xsl:copy>
        <xsl:apply-templates select="@*|node()|processing-instruction()"/>
    </xsl:copy>
</xsl:template>

</xsl:stylesheet>
