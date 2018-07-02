<!--
     This file has been slightly customized for cnx.org.
     This has only been done when editing the cnx-specific XSL cannot be customized
     Search for "HACK"
-->

<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:m="http://www.w3.org/1998/Math/MathML"
>

<!--
$Id: ctop.xsl,v 1.3 2002/09/20 08:41:39 davidc Exp $

Copyright David Carlisle 2001, 2002.

Use and distribution of this code are permitted under the terms of the <a
href="http://www.w3.org/Consortium/Legal/copyright-software-19980720"
>W3C Software Notice and License</a>.
-->

<xsl:output method="xml" />

<!-- Since cnxmathmlc2p.xsl uses xsl:apply-imports to sometimes override the default rendering,
     this needs to be here so the MathML is converted
-->
<xsl:template match="m:*">
  <xsl:param name="p" select="0"/>
  <xsl:apply-templates mode="c2p" select=".">
    <xsl:with-param name="p" select="$p"/>
  </xsl:apply-templates>
</xsl:template>

<xsl:template mode="c2p" match="*">
<xsl:copy>
  <xsl:copy-of select="@*"/>
  <xsl:apply-templates mode="c2p"/>
</xsl:copy>
</xsl:template>


<!-- 4.4.1.1 cn -->

<xsl:template mode="c2p" match="m:cn">
 <m:mn><xsl:apply-templates mode="c2p"/></m:mn>
</xsl:template>

<xsl:template mode="c2p" match="m:cn[@type='complex-cartesian']">
  <m:mrow>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[1]"/></m:mn>
    <m:mo>+</m:mo>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[2]"/></m:mn>
    <m:mo>&#8290;<!--invisible times--></m:mo>
    <m:mi>i<!-- imaginary i --></m:mi>
  </m:mrow>
</xsl:template>

<xsl:template mode="c2p" match="m:cn[@type='rational']">
  <m:mrow>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[1]"/></m:mn>
    <m:mo>/</m:mo>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[2]"/></m:mn>
  </m:mrow>
</xsl:template>

<xsl:template mode="c2p" match="m:cn[@type='integer']">
  <xsl:choose>
  <xsl:when test="not(@base) or @base=10">
       <m:mn><xsl:apply-templates mode="c2p"/></m:mn>
  </xsl:when>
  <xsl:otherwise>
  <m:msub>
    <m:mn><xsl:apply-templates mode="c2p"/></m:mn>
    <m:mn><xsl:value-of select="@base"/></m:mn>
  </m:msub>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template mode="c2p" match="m:cn[@type='complex-polar']">
  <m:mrow>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[1]"/></m:mn>
    <m:mo>&#x2220;<!--langle--></m:mo>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[2]"/></m:mn>
  </m:mrow>
</xsl:template>

<xsl:template mode="c2p" match="m:cn[@type='e-notation']">
  <m:mrow>
    <m:mn><xsl:apply-templates mode="c2p" select="text()[1]"/></m:mn>
    <m:mo>&#215;<!-- times --></m:mo>
    <m:msup>
      <m:mn>10</m:mn>
      <m:mn><xsl:apply-templates mode="c2p" select="text()[2]"/></m:mn>
    </m:msup>
  </m:mrow>
</xsl:template>

<!-- 4.2.4 Relations (Deprecated) -->
<xsl:template mode="c2p" match="m:reln[*[1][self::m:neq]]">
    <xsl:call-template name="c2p.reln.neq"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:equivalent]]">
    <xsl:call-template name="c2p.reln.equivalent"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:approx]]">
    <xsl:call-template name="c2p.reln.approx"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:factorof]]">
    <xsl:call-template name="c2p.reln.factorof"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:implies]]">
    <xsl:call-template name="c2p.reln.implies"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:in]]">
    <xsl:call-template name="c2p.reln.in"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:notin]]">
    <xsl:call-template name="c2p.reln.notin"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:notsubset]]">
    <xsl:call-template name="c2p.reln.notsubset"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:notprsubset]]">
    <xsl:call-template name="c2p.reln.notprsubset"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:tendsto]]">
    <xsl:call-template name="c2p.reln.tendsto"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:eq]]">
    <xsl:call-template name="c2p.reln.eq"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:leq]]">
    <xsl:call-template name="c2p.reln.leq"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:lt]]">
    <xsl:call-template name="c2p.reln.lt"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:geq]]">
    <xsl:call-template name="c2p.reln.geq"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:gt]]">
    <xsl:call-template name="c2p.reln.gt"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:subset]]">
    <xsl:call-template name="c2p.reln.subset"/>
</xsl:template>
<xsl:template mode="c2p" match="m:reln[*[1][self::m:prsubset]]">
    <xsl:call-template name="c2p.reln.prsubset"/>
</xsl:template>

<!-- 4.4.1.1 ci  -->

<xsl:template mode="c2p" match="m:ci/text()">
 <m:mi><xsl:value-of select="."/></m:mi>
</xsl:template>

<xsl:template mode="c2p" match="m:ci">
 <m:mrow><xsl:apply-templates mode="c2p"/></m:mrow>
</xsl:template>

<!-- 4.4.1.2 csymbol -->

<xsl:template mode="c2p" match="m:csymbol/text()">
 <m:mo><xsl:apply-templates mode="c2p"/></m:mo>
</xsl:template>

<xsl:template mode="c2p" match="m:csymbol">
 <m:mrow><xsl:apply-templates mode="c2p"/></m:mrow>
</xsl:template>

<!-- 4.4.2.1 apply 4.4.2.2 reln -->

<xsl:template mode="c2p" match="m:apply|m:reln">
 <m:mrow>
 <xsl:apply-templates mode="c2p" select="*[1]">
  <xsl:with-param name="p" select="10"/>
 </xsl:apply-templates>
 <!-- Parentheses HACK: An apply with no arguments SHOULD render as empty parentheses but we have enough legacy code that this isn't an option -->
 <xsl:if test="count(m:*) &gt; 1">
 <m:mo>&#8290;<!--invisible times--></m:mo>
 <m:mfenced open="(" close=")" separators=",">
 <xsl:apply-templates mode="c2p" select="*[position()>1]"/>
 </m:mfenced>
 </xsl:if>
 </m:mrow>
</xsl:template>

<!-- 4.4.2.3 fn -->
<xsl:template mode="c2p" match="m:fn">
 <m:mrow><xsl:apply-templates mode="c2p"/></m:mrow>
</xsl:template>

<!-- 4.4.2.4 interval -->
<xsl:template mode="c2p" match="m:interval[*[2]]">
 <m:mfenced open="[" close="]"><xsl:apply-templates mode="c2p"/></m:mfenced>
</xsl:template>
<xsl:template mode="c2p" match="m:interval[*[2]][@closure='open']">
 <m:mfenced open="(" close=")"><xsl:apply-templates mode="c2p"/></m:mfenced>
</xsl:template>
<xsl:template mode="c2p" match="m:interval[*[2]][@closure='open-closed']">
 <m:mfenced open="(" close="]"><xsl:apply-templates mode="c2p"/></m:mfenced>
</xsl:template>
<xsl:template mode="c2p" match="m:interval[*[2]][@closure='closed-open']">
 <m:mfenced open="[" close=")"><xsl:apply-templates mode="c2p"/></m:mfenced>
</xsl:template>

<xsl:template mode="c2p" match="m:interval">
 <m:mfenced open="{{" close="}}"><xsl:apply-templates mode="c2p"/></m:mfenced>
</xsl:template>

<!-- 4.4.2.5 inverse -->

<xsl:template mode="c2p" match="m:apply[*[1][self::m:inverse]]">
 <m:msup>
  <xsl:apply-templates mode="c2p" select="*[2]"/>
  <m:mrow><m:mo>(</m:mo><m:mn>-1</m:mn><m:mo>)</m:mo></m:mrow>
 </m:msup>
</xsl:template>

<!-- 4.4.2.6 sep -->

<!-- 4.4.2.7 condition -->
<xsl:template mode="c2p" match="m:condition">
 <m:mrow><xsl:apply-templates mode="c2p"/></m:mrow>
</xsl:template>

<!-- 4.4.2.8 declare -->
<xsl:template mode="c2p" match="m:declare"/>

<!-- 4.4.2.9 lambda -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:lambda]]">
 <m:mrow>
  <m:mi>&#955;<!--lambda--></m:mi>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:bvar/*"/></m:mrow>
 <m:mo>.</m:mo>
 <m:mfenced>
  <xsl:apply-templates mode="c2p" select="*[last()]"/>
 </m:mfenced>
</m:mrow>
</xsl:template>


<!-- 4.4.2.10 compose -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:compose]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8728;<!-- o --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>


<!-- 4.4.2.11` ident -->
<xsl:template mode="c2p" match="m:ident">
<m:mo>id</m:mo>
</xsl:template>

<!-- 4.4.2.12` domain -->
<xsl:template mode="c2p" match="m:domain">
<m:mo>domain</m:mo>
</xsl:template>

<!-- 4.4.2.13` codomain -->
<xsl:template mode="c2p" match="m:codomain">
<m:mo>codomain</m:mo>
</xsl:template>

<!-- 4.4.2.14` image -->
<xsl:template mode="c2p" match="m:image">
<m:mo>image</m:mo>
</xsl:template>

<!-- 4.4.2.15` domainofapplication -->
<xsl:template mode="c2p" match="m:domainofapplication">
 <m:error/>
</xsl:template>

<!-- 4.4.2.16` piecewise -->
<xsl:template mode="c2p" match="m:piecewise">
<m:mrow>
<m:mo>{</m:mo>
<m:mtable>
 <xsl:for-each select="m:piece|m:otherwise">
 <m:mtr>
 <m:mtd><xsl:apply-templates mode="c2p" select="*[1]"/></m:mtd>
 <m:mtd><m:mtext>&#160; if &#160;</m:mtext></m:mtd>
 <m:mtd><xsl:apply-templates mode="c2p" select="*[2]"/></m:mtd>
 </m:mtr>
 </xsl:for-each>
</m:mtable>
</m:mrow>
</xsl:template>


<!-- 4.4.3.1 quotient -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:quotient]]">
<m:mrow>
<m:mo>&#8970;<!-- lfloor--></m:mo>
<xsl:apply-templates mode="c2p" select="*[2]"/>
<m:mo>/</m:mo>
<xsl:apply-templates mode="c2p" select="*[3]"/>
<m:mo>&#8971;<!-- rfloor--></m:mo>
</m:mrow>
</xsl:template>



<!-- 4.4.3.2 factorial -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:factorial]]">
<m:mrow>
<xsl:apply-templates mode="c2p" select="*[2]">
  <xsl:with-param name="p" select="7"/>
</xsl:apply-templates>
<m:mo>!</m:mo>
</m:mrow>
</xsl:template>


<!-- 4.4.3.3 divide -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:divide]]">
  <xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
  <xsl:with-param name="mo"><m:mo>/</m:mo></xsl:with-param>
  <xsl:with-param name="p" select="$p"/>
  <xsl:with-param name="this-p" select="3"/>
</xsl:call-template>
</xsl:template>


<!-- 4.4.3.4 max  min-->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:max]]">
<m:mrow>
  <m:mo>max</m:mo>
  <xsl:call-template name="set">
    <xsl:with-param name="a" select="true()"/>
  </xsl:call-template>
</m:mrow>
</xsl:template>

<xsl:template mode="c2p" match="m:apply[*[1][self::m:min]]">
<m:mrow>
  <m:mo>min</m:mo>
  <xsl:call-template name="set">
    <xsl:with-param name="a" select="true()"/>
  </xsl:call-template>
</m:mrow>
</xsl:template>

<!-- Use a subscript for min/max with domainofapplication -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:min or self::m:max] and (m:domainofapplication or m:bvar)]">
<m:mrow>
  <m:msub>
    <m:mo><xsl:value-of select="local-name(*[1])"/></m:mo>
    <m:mrow>
      <xsl:apply-templates mode="c2p" select="m:domainofapplication/node()"/>
      <xsl:apply-templates mode="c2p" select="m:bvar"/>
    </m:mrow>
  </m:msub>
  <xsl:call-template name="set">
    <xsl:with-param name="a" select="true()"/>
  </xsl:call-template>
</m:mrow>
</xsl:template>
<xsl:template mode="c2p" match="m:domainofapplication[preceding-sibling::m:min or preceding-sibling::m:max]"/>


<!-- 4.4.3.5  minus-->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:minus] and count(*)=2]">
<xsl:param name="p" select="0"/>
<m:mrow>
  <xsl:if test="$p &gt; 2"><m:mo>(</m:mo></xsl:if>
  <m:mo>&#8722;<!--minus--></m:mo>
  <xsl:apply-templates mode="c2p" select="*[2]">
      <xsl:with-param name="p" select="5"/>
  </xsl:apply-templates>
  <xsl:if test="$p &gt; 2"><m:mo>)</m:mo></xsl:if>
</m:mrow>
</xsl:template>

<xsl:template mode="c2p" match="m:apply[*[1][self::m:minus] and count(*)&gt;2]">
  <xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
  <xsl:with-param name="mo"><m:mo>&#8722;<!--minus--></m:mo></xsl:with-param>
  <xsl:with-param name="p" select="$p"/>
  <xsl:with-param name="this-p" select="2"/>
</xsl:call-template>
</xsl:template>

<!-- 4.4.3.6  plus-->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:plus]]">
  <xsl:param name="p" select="0"/>
  <m:mrow>
  <xsl:if test="$p &gt; 2.5"><m:mo>(</m:mo></xsl:if>
  <xsl:for-each select="*[position()&gt;1]">
   <xsl:if test="position() &gt; 1">
    <m:mo>
    <xsl:choose>
      <xsl:when test="self::m:apply[*[1][self::m:times] and
      *[2][self::m:apply/*[1][self::m:minus] or self::m:cn[not(m:sep) and
      (number(.) &lt; 0)]]]">&#8722;<!--minus--></xsl:when>
      <xsl:otherwise>+</xsl:otherwise>
    </xsl:choose>
    </m:mo>
   </xsl:if>   
    <xsl:choose>
      <xsl:when test="self::m:apply[*[1][self::m:times] and
      *[2][self::m:cn[not(m:sep) and (number(.) &lt;0)]]]">
     <m:mrow>
     <m:mn><xsl:value-of select="-(*[2])"/></m:mn>
      <m:mo>&#8290;<!--invisible times--></m:mo>
     <xsl:apply-templates mode="c2p" select=".">
     <xsl:with-param name="first" select="2"/>
     <xsl:with-param name="p" select="2"/>
   </xsl:apply-templates>
     </m:mrow>
      </xsl:when>
      <xsl:when test="self::m:apply[*[1][self::m:times] and
      *[2][self::m:apply/*[1][self::m:minus]]]">
     <m:mrow>
     <xsl:apply-templates mode="c2p" select="./*[2]/*[2]"/>
     <xsl:apply-templates mode="c2p" select=".">
     <xsl:with-param name="first" select="2"/>
     <xsl:with-param name="p" select="2"/>
   </xsl:apply-templates>
     </m:mrow>
      </xsl:when>
      <xsl:otherwise>
     <xsl:apply-templates mode="c2p" select=".">
     <xsl:with-param name="p" select="2"/>
   </xsl:apply-templates>
   </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
  <xsl:if test="$p &gt; 2.5"><m:mo>)</m:mo></xsl:if>
  </m:mrow>
</xsl:template>


<!-- 4.4.3.7 power -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:power]]">
<m:msup>
<xsl:apply-templates mode="c2p" select="*[2]">
  <xsl:with-param name="p" select="5"/>
</xsl:apply-templates>
<xsl:apply-templates mode="c2p" select="*[3]">
  <xsl:with-param name="p" select="5"/>
</xsl:apply-templates>
</m:msup>
</xsl:template>

<!-- 4.4.3.8 remainder -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:rem]]">
  <xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
  <xsl:with-param name="mo"><m:mo>mod</m:mo></xsl:with-param>
  <xsl:with-param name="p" select="$p"/>
  <xsl:with-param name="this-p" select="3"/>
</xsl:call-template>
</xsl:template>

<!-- 4.4.3.9  times-->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:times]]" name="times">
  <xsl:param name="p" select="0"/>
  <xsl:param name="first" select="1"/>
  <m:mrow>
  <xsl:if test="$p &gt; 3"><m:mo>(</m:mo></xsl:if>
  <xsl:for-each select="*[position()&gt;1]">
   <xsl:if test="position() &gt; 1">
    <m:mo>
    <xsl:choose>
      <xsl:when test="self::m:cn">&#215;<!-- times --></xsl:when>
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
  <xsl:if test="$p &gt; 3"><m:mo>)</m:mo></xsl:if>
  </m:mrow>
</xsl:template>


<!-- 4.4.3.10 root -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:root] and (not(m:degree) or m:degree=2)]" priority="4">
<m:msqrt>
<xsl:apply-templates mode="c2p" select="*[position()&gt;1]"/>
</m:msqrt>
</xsl:template>

<xsl:template mode="c2p" match="m:apply[*[1][self::m:root]]">
<m:mroot>
<xsl:apply-templates mode="c2p" select="*[position()&gt;1 and not(self::m:degree)]"/>
<m:mrow><xsl:apply-templates mode="c2p" select="m:degree/*"/></m:mrow>
</m:mroot>
</xsl:template>

<!-- 4.4.3.11 gcd -->
<xsl:template mode="c2p" match="m:gcd">
<m:mo>gcd</m:mo>
</xsl:template>

<!-- 4.4.3.12 and -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:and]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8743;<!-- and --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>


<!-- 4.4.3.13 or -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:or]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="3"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8744;<!-- or --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.3.14 xor -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:xor]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="3"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>xor</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>


<!-- 4.4.3.15 not -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:not]]">
<m:mrow>
<m:mo>&#172;<!-- not --></m:mo>
<xsl:apply-templates mode="c2p" select="*[2]">
  <xsl:with-param name="p" select="7"/>
</xsl:apply-templates>
</m:mrow>
</xsl:template>




<!-- 4.4.3.16 implies -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:implies]]" name="c2p.reln.implies">
  <xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
  <xsl:with-param name="mo"><m:mo>&#8658;<!-- Rightarrow --></m:mo></xsl:with-param>
  <xsl:with-param name="p" select="$p"/>
  <xsl:with-param name="this-p" select="3"/>
</xsl:call-template>
</xsl:template>


<!-- 4.4.3.17 forall -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:forall]]">
 <m:mrow>
  <m:mi>&#8704;<!--forall--></m:mi>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:bvar[not(current()/m:condition)]/*|m:condition/*"/></m:mrow>
 <m:mo>.</m:mo>
 <m:mfenced>
  <xsl:apply-templates mode="c2p" select="*[last()]"/>
 </m:mfenced>
</m:mrow>
</xsl:template>



<!-- 4.4.3.18 exists -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:exists]]">
 <m:mrow>
  <m:mi>&#8707;<!--exists--></m:mi>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:bvar[not(current()/m:condition)]/*|m:condition/*"/></m:mrow>
 <m:mo>.</m:mo>
 <m:mfenced>
  <xsl:apply-templates mode="c2p" select="*[last()]"/>
 </m:mfenced>
</m:mrow>
</xsl:template>


<!-- 4.4.3.19 abs -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:abs]]">
<m:mrow>
<m:mo>|</m:mo>
<xsl:apply-templates mode="c2p" select="*[2]"/>
<m:mo>|</m:mo>
</m:mrow>
</xsl:template>



<!-- 4.4.3.20 conjugate -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:conjugate]]">
<m:mover>
<xsl:apply-templates mode="c2p" select="*[2]"/>
<m:mo>&#175;<!-- overline --></m:mo>
</m:mover>
</xsl:template>

<!-- 4.4.3.21 arg -->
<xsl:template mode="c2p" match="m:arg">
 <m:mo>arg</m:mo>
</xsl:template>


<!-- 4.4.3.22 real -->
<xsl:template mode="c2p" match="m:real">
 <m:mo>&#8475;<!-- real --></m:mo>
</xsl:template>

<!-- 4.4.3.23 imaginary -->
<xsl:template mode="c2p" match="m:imaginary">
 <m:mo>&#8465;<!-- imaginary --></m:mo>
</xsl:template>

<!-- 4.4.3.24 lcm -->
<xsl:template mode="c2p" match="m:lcm">
 <m:mo>lcm</m:mo>
</xsl:template>


<!-- 4.4.3.25 floor -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:floor]]">
<m:mrow>
<m:mo>&#8970;<!-- lfloor--></m:mo>
<xsl:apply-templates mode="c2p" select="*[2]"/>
<m:mo>&#8971;<!-- rfloor--></m:mo>
</m:mrow>
</xsl:template>


<!-- 4.4.3.25 ceiling -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:ceiling]]">
<m:mrow>
<m:mo>&#8968;<!-- lceil--></m:mo>
<xsl:apply-templates mode="c2p" select="*[2]"/>
<m:mo>&#8969;<!-- rceil--></m:mo>
</m:mrow>
</xsl:template>

<!-- 4.4.4.1 eq -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:eq]]" name="c2p.reln.eq">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>=</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.4.2 neq -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:neq]]" name="c2p.reln.neq">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8800;<!-- neq --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.4.3 gt -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:gt]]" name="c2p.reln.gt">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&gt;</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.4.4 lt -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:lt]]" name="c2p.reln.lt">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&lt;</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.4.5 geq -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:geq]]" name="c2p.reln.geq">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8805;</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.4.6 leq -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:leq]]" name="c2p.reln.leq">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8804;</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.4.7 equivalent -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:equivalent]]" name="c2p.reln.equivalent">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8801;</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.4.8 approx -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:approx]]" name="c2p.reln.approx">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="1"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8771;</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>


<!-- 4.4.4.9 factorof -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:factorof]]" name="c2p.reln.factorof">
  <xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
  <xsl:with-param name="mo"><m:mo>|</m:mo></xsl:with-param>
  <xsl:with-param name="p" select="$p"/>
  <xsl:with-param name="this-p" select="3"/>
</xsl:call-template>
</xsl:template>

<!-- 4.4.5.1 int -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:int]]">
 <m:mrow>
 <m:msubsup>
  <m:mo>&#8747;<!--int--></m:mo>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:lowlimit/*|m:interval/*[1]|m:condition/*"/></m:mrow>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:uplimit/*|m:interval/*[2]"/></m:mrow>
 </m:msubsup>
 <xsl:apply-templates mode="c2p" select="*[last()]"/>
 <m:mo>d</m:mo><xsl:apply-templates mode="c2p" select="m:bvar"/>
</m:mrow>
</xsl:template>

<!-- 4.4.5.2 diff -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:diff] and m:ci and count(*)=2]" priority="2">
 <m:msup>
 <m:mrow><xsl:apply-templates mode="c2p" select="*[2]"/></m:mrow>
 <m:mo>&#8242;<!--prime--></m:mo>
 </m:msup>
</xsl:template>

<xsl:template mode="c2p" match="m:apply[*[1][self::m:diff]]" priority="1">
 <m:mfrac>
 <xsl:choose>
 <xsl:when test="m:bvar/m:degree">
 <m:mrow><m:msup><m:mo>d</m:mo><xsl:apply-templates mode="c2p" select="m:bvar/m:degree/node()"/></m:msup>
     <xsl:apply-templates mode="c2p"  select="*[last()]"/></m:mrow>
 <m:mrow><m:mo>d</m:mo><m:msup><xsl:apply-templates mode="c2p"
 select="m:bvar/node()[not(self::m:degree)]"/><xsl:apply-templates mode="c2p"
 select="m:bvar/m:degree/node()"/></m:msup>
</m:mrow>
</xsl:when>
<xsl:otherwise>
 <m:mrow><m:mo>d</m:mo><xsl:apply-templates mode="c2p" select="*[last()]"/></m:mrow>
 <m:mrow><m:mo>d</m:mo><xsl:apply-templates mode="c2p" select="m:bvar"/></m:mrow>
</xsl:otherwise>
 </xsl:choose>
 </m:mfrac>
</xsl:template>


<!-- 4.4.5.3 partialdiff -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:partialdiff] and m:list and m:ci and count(*)=3]" priority="2">
<m:mrow>
 <m:msub><m:mo>D</m:mo><m:mrow>
<xsl:for-each select="m:list[1]/*">
<xsl:apply-templates mode="c2p" select="."/>
<xsl:if test="position()&lt;last()"><m:mo>,</m:mo></xsl:if>
</xsl:for-each>
</m:mrow></m:msub>
 <m:mrow><xsl:apply-templates mode="c2p" select="*[3]"/></m:mrow>
</m:mrow>
</xsl:template>

<xsl:template mode="c2p" match="m:apply[*[1][self::m:partialdiff]]" priority="1">
 <m:mfrac>
 <m:mrow><m:msup><m:mo>&#8706;<!-- partial --></m:mo>
<m:mrow>
 <xsl:choose>
 <xsl:when test="m:degree">
<xsl:apply-templates mode="c2p" select="m:degree/node()"/>
</xsl:when>
<xsl:when test="m:bvar/m:degree[string(number(.))='NaN']">
<xsl:for-each select="m:bvar/m:degree">
<xsl:apply-templates mode="c2p" select="node()"/>
<xsl:if test="position()&lt;last()"><m:mo>+</m:mo></xsl:if>
</xsl:for-each>
<xsl:if test="count(m:bvar[not(m:degree)])&gt;0">
<m:mo>+</m:mo><m:mn><xsl:value-of select="count(m:bvar[not(m:degree)])"/></m:mn>
</xsl:if>
</xsl:when>
<xsl:otherwise>
<xsl:if test="sum(m:bvar/m:degree)+count(m:bvar[not(m:degree)]) != 1">
<m:mn><xsl:value-of select="sum(m:bvar/m:degree)+count(m:bvar[not(m:degree)])"/></m:mn>
</xsl:if>
</xsl:otherwise>
 </xsl:choose>
</m:mrow>
</m:msup>
     <xsl:apply-templates mode="c2p"  select="*[last()]">
       <xsl:with-param name="p" select="9"/>
     </xsl:apply-templates>
</m:mrow>
<m:mrow>
<xsl:for-each select="m:bvar">
<m:mrow>
<m:mo>&#8706;<!-- partial --></m:mo><m:msup><xsl:apply-templates mode="c2p" select="node()"/>
                     <m:mrow><xsl:apply-templates mode="c2p" select="m:degree/node()"/></m:mrow>
</m:msup>
</m:mrow>
</xsl:for-each>
</m:mrow>
 </m:mfrac>
</xsl:template>

<!-- 4.4.5.4  lowlimit-->
<xsl:template mode="c2p" match="m:lowlimit"/>

<!-- 4.4.5.5 uplimit-->
<xsl:template mode="c2p" match="m:uplimit"/>

<!-- 4.4.5.6  bvar-->
<xsl:template mode="c2p" match="m:bvar">
 <m:mi><xsl:apply-templates mode="c2p"/></m:mi>
 <xsl:if test="following-sibling::m:bvar"><m:mo>,</m:mo></xsl:if>
</xsl:template>

<!-- 4.4.5.7 degree-->
<xsl:template mode="c2p" match="m:degree"/>

<!-- 4.4.5.8 divergence-->
<xsl:template mode="c2p" match="m:divergence">
<m:mo>div</m:mo>
</xsl:template>

<!-- 4.4.5.9 grad-->
<xsl:template mode="c2p" match="m:grad">
<m:mo>grad</m:mo>
</xsl:template>

<!-- 4.4.5.10 curl -->
<xsl:template mode="c2p" match="m:curl">
<m:mo>curl</m:mo>
</xsl:template>


<!-- 4.4.5.11 laplacian-->
<xsl:template mode="c2p" match="m:laplacian">
<m:msup><m:mo>&#8711;<!-- nabla --></m:mo><m:mn>2</m:mn></m:msup>
</xsl:template>

<!-- 4.4.6.1 set -->

<xsl:template mode="c2p" match="m:set">
  <xsl:call-template name="set"/>
</xsl:template>

<!-- 4.4.6.2 list -->

<xsl:template mode="c2p" match="m:list">
  <xsl:call-template name="set">
   <xsl:with-param name="o" select="'('"/>
   <xsl:with-param name="c" select="')'"/>
  </xsl:call-template>
</xsl:template>

<!-- 4.4.6.3 union -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:union]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8746;<!-- union --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.4 intersect -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:intersect]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="3"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8745;<!-- intersect --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.5 in -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:in]]" name="c2p.reln.in">
  <xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
  <xsl:with-param name="mo"><m:mo>&#8712;<!-- in --></m:mo></xsl:with-param>
  <xsl:with-param name="p" select="$p"/>
  <xsl:with-param name="this-p" select="3"/>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.5 notin -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:notin]]" name="c2p.reln.notin">
  <xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
  <xsl:with-param name="mo"><m:mo>&#8713;<!-- not in --></m:mo></xsl:with-param>
  <xsl:with-param name="p" select="$p"/>
  <xsl:with-param name="this-p" select="3"/>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.7 subset -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:subset]]" name="c2p.reln.subset">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8838;<!-- subseteq --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.8 prsubset -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:prsubset]]" name="c2p.reln.prsubset">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8834;<!-- prsubset --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.9 notsubset -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:notsubset]]" name="c2p.reln.notsubset">
<xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8840;<!-- notsubseteq --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.10 notprsubset -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:notprsubset]]" name="c2p.reln.notprsubset">
<xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8836;<!-- prsubset --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.11 setdiff -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:setdiff]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="binary">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#8726;<!-- setminus --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.6.12 card -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:card]]">
<m:mrow>
<m:mo>|</m:mo>
<xsl:apply-templates mode="c2p" select="*[2]"/>
<m:mo>|</m:mo>
</m:mrow>
</xsl:template>

<!-- 4.4.6.13 cartesianproduct -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:cartesianproduct or self::m:vectorproduct]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>&#215;<!-- times --></m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<xsl:template
match="m:apply[*[1][self::m:cartesianproduct][count(following-sibling::m:reals)=count(following-sibling::*)]]"
priority="2">
<m:msup>
<xsl:apply-templates mode="c2p" select="*[2]">
  <xsl:with-param name="p" select="5"/>
</xsl:apply-templates>
<m:mn><xsl:value-of select="count(*)-1"/></m:mn>
</m:msup>
</xsl:template>


<!-- 4.4.7.1 sum -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:sum]]">
 <m:mrow>
 <m:msubsup>
  <m:mo>&#8721;<!--sum--></m:mo>
 <m:mrow>
   <xsl:if test="m:bvar">
     <xsl:apply-templates mode="c2p" select="m:bvar"/>
     <m:mo>=</m:mo>
   </xsl:if>
   <xsl:apply-templates mode="c2p" select="m:lowlimit/*|m:interval/*[1]|m:condition/*"/>
 </m:mrow>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:uplimit/*|m:interval/*[2]"/></m:mrow>
 </m:msubsup>
 <xsl:apply-templates mode="c2p" select="*[last()]"/>
</m:mrow>
</xsl:template>

<!-- 4.4.7.2 product -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:product]]">
 <m:mrow>
 <m:msubsup>
  <m:mo>&#8719;<!--product--></m:mo>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:lowlimit/*|m:interval/*[1]|m:condition/*"/></m:mrow>
 <m:mrow><xsl:apply-templates mode="c2p" select="m:uplimit/*|m:interval/*[2]"/></m:mrow>
 </m:msubsup>
 <xsl:apply-templates mode="c2p" select="*[last()]"/>
</m:mrow>
</xsl:template>

<!-- 4.4.7.3 limit -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:limit]]">
 <m:mrow>
 <m:munder>
  <m:mi>limit &#160;</m:mi>
  <m:mrow>
    <xsl:apply-templates mode="c2p" select="m:lowlimit|m:condition/*|m:bvar[not(parent::*/m:lowlimit)]"/>
  </m:mrow>
 </m:munder>
 <xsl:apply-templates mode="c2p" select="*[last()][not(self::m:bvar or self::m:lowlimit or self::m:condition)]"/>
</m:mrow>
</xsl:template>

<xsl:template mode="c2p" match="m:apply[m:limit]/m:lowlimit" priority="3">
<m:mrow>
<xsl:apply-templates mode="c2p" select="../m:bvar/node()"/>
<m:mo>&#8594;<!--rightarrow--></m:mo>
<xsl:apply-templates mode="c2p"/>
</m:mrow>
</xsl:template>


<!-- 4.4.7.4 tendsto -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:tendsto]]" name="c2p.reln.tendsto">
 <xsl:param name="p"/>
<xsl:call-template name="binary">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>
  <xsl:choose>
   <xsl:when test="@type='above'">&#8600;<!--searrow--></xsl:when>
   <xsl:when test="@type='below'">&#8599;<!--nearrow--></xsl:when>
   <xsl:when test="@type='two-sided'">&#8594;<!--rightarrow--></xsl:when>
   <xsl:otherwise>&#8594;<!--rightarrow--></xsl:otherwise>
  </xsl:choose>
  </m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

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
<xsl:apply-templates mode="c2p" select="*[2]">
  <xsl:with-param name="p" select="7"/>
</xsl:apply-templates>
</m:mrow>
</xsl:template>

<!-- 4.4.8.1 trig as a child other than the first -->
<xsl:template mode="c2p" match="m:apply/*[position()!=1 and (
 self::m:sin or self::m:cos or self::m:tan or self::m:sec or
 self::m:csc or self::m:cot or self::m:sinh or self::m:cosh or
 self::m:tanh or self::m:sech or self::m:csch or self::m:coth or
 self::m:arcsin or self::m:arccos or self::m:arctan or self::m:arccosh
 or self::m:arccot or self::m:arccoth or self::m:arccsc or
 self::m:arccsch or self::m:arcsec or self::m:arcsech or
 self::m:arcsinh or self::m:arctanh or self::m:ln)]">
<m:mi><xsl:value-of select="local-name(.)"/></m:mi>
</xsl:template>



<!-- 4.4.8.2 exp -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:exp]]">
<m:msup>
<m:mi>e<!-- exponential e--></m:mi>
<m:mrow><xsl:apply-templates mode="c2p" select="*[2]"/></m:mrow>
</m:msup>
</xsl:template>

<!-- 4.4.8.3 ln -->
<!-- with trig -->

<!-- 4.4.8.4 log -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:log]]">
<m:mrow>
<xsl:choose>
<xsl:when test="not(m:logbase) or m:logbase=10">
<m:mi>log</m:mi>
</xsl:when>
<xsl:otherwise>
<m:msub>
<m:mi>log</m:mi>
<m:mrow><xsl:apply-templates mode="c2p" select="m:logbase/node()"/></m:mrow>
</m:msub>
</xsl:otherwise>
</xsl:choose>
<xsl:apply-templates mode="c2p" select="*[last()]">
  <xsl:with-param name="p" select="7"/>
</xsl:apply-templates>
</m:mrow>
</xsl:template>


<!-- 4.4.9.1 mean -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:mean]]">
<m:mrow>
 <m:mo>&#9001;<!--langle--></m:mo>
    <xsl:for-each select="*[position()&gt;1]">
      <xsl:apply-templates mode="c2p" select="."/>
      <xsl:if test="position() !=last()"><m:mo>,</m:mo></xsl:if>
    </xsl:for-each>
<m:mo>&#9002;<!--rangle--></m:mo>
</m:mrow>
</xsl:template>


<!-- 4.4.9.2 sdef -->
<xsl:template mode="c2p" match="m:sdev">
<m:mo>&#963;<!--sigma--></m:mo>
</xsl:template>

<!-- 4.4.9.3 variance -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:variance]]">
<m:msup>
<m:mrow>
<m:mo>&#963;<!--sigma--></m:mo>
<m:mo>(</m:mo>
<xsl:apply-templates mode="c2p" select="*[2]"/>
<m:mo>)</m:mo>
</m:mrow>
<m:mn>2</m:mn>
</m:msup>
</xsl:template>


<!-- 4.4.9.4 median -->
<xsl:template mode="c2p" match="m:median">
<m:mo>median</m:mo>
</xsl:template>


<!-- 4.4.9.5 mode -->
<xsl:template mode="c2p" match="m:mode">
<m:mo>mode</m:mo>
</xsl:template>

<!-- 4.4.9.5 moment -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:moment]]">
<m:mrow>
 <m:mo>&#9001;<!--langle--></m:mo>
       <m:msup>
      <xsl:apply-templates mode="c2p" select="*[last()]"/>
      <m:mrow><xsl:apply-templates mode="c2p" select="m:degree/node()"/></m:mrow>
       </m:msup>
<m:mo>&#9002;<!--rangle--></m:mo>
</m:mrow>
</xsl:template>

<!-- 4.4.9.5 momentabout -->
<xsl:template mode="c2p" match="m:momentabout"/>

<!-- 4.4.10.1 vector  -->
<xsl:template mode="c2p" match="m:vector">
<m:mrow>
<m:mo>(</m:mo>
<m:mtable>
<xsl:for-each select="*">
<m:mtr><m:mtd><xsl:apply-templates mode="c2p" select="."/></m:mtd></m:mtr>
</xsl:for-each>
</m:mtable>
<m:mo>)</m:mo>
</m:mrow>
</xsl:template>

<!-- 4.4.10.2 matrix  -->
<xsl:template mode="c2p" match="m:matrix">
<m:mrow>
<m:mo>(</m:mo>
<m:mtable>
<xsl:apply-templates mode="c2p"/>
</m:mtable>
<m:mo>)</m:mo>
</m:mrow>
</xsl:template>

<!-- 4.4.10.3 matrixrow  -->
<xsl:template mode="c2p" match="m:matrixrow">
<m:mtr>
<xsl:for-each select="*">
<m:mtd><xsl:apply-templates mode="c2p" select="."/></m:mtd>
</xsl:for-each>
</m:mtr>
</xsl:template>

<!-- 4.4.10.4 determinant  -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:determinant]]">
<m:mrow>
<m:mi>det</m:mi>
<xsl:apply-templates mode="c2p" select="*[2]">
  <xsl:with-param name="p" select="7"/>
</xsl:apply-templates>
</m:mrow>
</xsl:template>

<xsl:template
match="m:apply[*[1][self::m:determinant]][*[2][self::m:matrix]]" priority="2">
<m:mrow>
<m:mo>|</m:mo>
<m:mtable>
<xsl:apply-templates mode="c2p" select="m:matrix/*"/>
</m:mtable>
<m:mo>|</m:mo>
</m:mrow>
</xsl:template>

<!-- 4.4.10.5 transpose -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:transpose]]">
<m:msup>
<xsl:apply-templates mode="c2p" select="*[2]">
  <xsl:with-param name="p" select="7"/>
</xsl:apply-templates>
<m:mi>T</m:mi>
</m:msup>
</xsl:template>

<!-- 4.4.10.5 selector -->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:selector]]">
<m:msub>
<xsl:apply-templates mode="c2p" select="*[2]">
  <xsl:with-param name="p" select="7"/>
</xsl:apply-templates>
<m:mrow>
    <xsl:for-each select="*[position()&gt;2]">
      <xsl:apply-templates mode="c2p" select="."/>
      <xsl:if test="position() !=last()"><m:mo>,</m:mo></xsl:if>
    </xsl:for-each>
</m:mrow>
</m:msub>
</xsl:template>

<!-- *** -->
<!-- 4.4.10.6 vectorproduct see cartesianproduct -->


<!-- 4.4.10.7 scalarproduct-->
<xsl:template mode="c2p" match="m:apply[*[1][self::m:scalarproduct or self::m:outerproduct]]">
<xsl:param name="p" select="0"/>
<xsl:call-template name="infix">
 <xsl:with-param name="this-p" select="2"/>
 <xsl:with-param name="p" select="$p"/>
 <xsl:with-param name="mo"><m:mo>.</m:mo></xsl:with-param>
</xsl:call-template>
</xsl:template>

<!-- 4.4.10.8 outerproduct-->

<!-- 4.4.11.2 semantics -->
<xsl:template mode="c2p" match="m:semantics">
 <xsl:apply-templates mode="c2p" select="*[1]"/>
</xsl:template>
<xsl:template mode="c2p" match="m:semantics[m:annotation-xml/@encoding='MathML-Presentation']">
 <xsl:apply-templates mode="c2p" select="m:annotation-xml[@encoding='MathML-Presentation']/node()"/>
</xsl:template>

<!-- 4.4.12.1 integers -->
<xsl:template mode="c2p" match="m:integers">
<m:mi mathvariant="double-struck">Z</m:mi>
</xsl:template>

<!-- 4.4.12.2 reals -->
<xsl:template mode="c2p" match="m:reals">
<m:mi mathvariant="double-struck">R</m:mi>
</xsl:template>

<!-- 4.4.12.3 rationals -->
<xsl:template mode="c2p" match="m:rationals">
<m:mi mathvariant="double-struck">Q</m:mi>
</xsl:template>

<!-- 4.4.12.4 naturalnumbers -->
<xsl:template mode="c2p" match="m:naturalnumbers">
<m:mi mathvariant="double-struck">N</m:mi>
</xsl:template>

<!-- 4.4.12.5 complexes -->
<xsl:template mode="c2p" match="m:complexes">
<m:mi mathvariant="double-struck">C</m:mi>
</xsl:template>

<!-- 4.4.12.6 primes -->
<xsl:template mode="c2p" match="m:primes">
<m:mi mathvariant="double-struck">P</m:mi>
</xsl:template>

<!-- 4.4.12.7 exponentiale -->
<xsl:template mode="c2p" match="m:exponentiale">
  <m:mi>e<!-- exponential e--></m:mi>
</xsl:template>

<!-- 4.4.12.8 imaginaryi -->
<xsl:template mode="c2p" match="m:imaginaryi">
  <m:mi>i<!-- imaginary i--></m:mi>
</xsl:template>

<!-- 4.4.12.9 notanumber -->
<xsl:template mode="c2p" match="m:notanumber">
  <m:mi>NaN</m:mi>
</xsl:template>

<!-- 4.4.12.10 true -->
<xsl:template mode="c2p" match="m:true">
  <m:mi>true</m:mi>
</xsl:template>

<!-- 4.4.12.11 false -->
<xsl:template mode="c2p" match="m:false">
  <m:mi>false</m:mi>
</xsl:template>

<!-- 4.4.12.12 emptyset -->
<xsl:template mode="c2p" match="m:emptyset">
  <m:mi>&#8709;<!-- emptyset --></m:mi>
</xsl:template>


<!-- 4.4.12.13 pi -->
<xsl:template mode="c2p" match="m:pi">
  <m:mi>&#960;<!-- pi --></m:mi>
</xsl:template>

<!-- 4.4.12.14 eulergamma -->
<xsl:template mode="c2p" match="m:eulergamma">
  <m:mi>&#947;<!-- gamma --></m:mi>
</xsl:template>

<!-- 4.4.12.15 infinity -->
<xsl:template mode="c2p" match="m:infinity">
  <m:mi>&#8734;<!-- infinity --></m:mi>
</xsl:template>


<!-- ****************************** -->
<xsl:template name="infix" >
  <xsl:param name="mo"/>
  <xsl:param name="p" select="0"/>
  <xsl:param name="this-p" select="0"/>
  <m:mrow>
  <xsl:if test="$this-p &lt; $p"><m:mo>(</m:mo></xsl:if>
  <xsl:for-each select="*[position()&gt;1]">
   <xsl:if test="position() &gt; 1">
    <xsl:copy-of select="$mo"/>
   </xsl:if>   
   <xsl:apply-templates mode="c2p" select=".">
     <xsl:with-param name="p" select="$this-p"/>
   </xsl:apply-templates>
  </xsl:for-each>
  <xsl:if test="$this-p &lt; $p"><m:mo>)</m:mo></xsl:if>
  </m:mrow>
</xsl:template>

<xsl:template name="binary" >
  <xsl:param name="mo"/>
  <xsl:param name="p" select="0"/>
  <xsl:param name="this-p" select="0"/>
  <m:mrow>
  <xsl:if test="$this-p &lt; $p"><m:mo>(</m:mo></xsl:if>
   <xsl:apply-templates mode="c2p" select="*[2]">
     <xsl:with-param name="p" select="$this-p"/>
   </xsl:apply-templates>
   <xsl:copy-of select="$mo"/>
   <xsl:apply-templates mode="c2p" select="*[3]">
     <xsl:with-param name="p" select="$this-p"/>
   </xsl:apply-templates>
  <xsl:if test="$this-p &lt; $p"><m:mo>)</m:mo></xsl:if>
  </m:mrow>
</xsl:template>

<xsl:template name="set" >
  <xsl:param name="a" select="false()"/>
  <xsl:param name="o" select="'{'"/>
  <xsl:param name="c" select="'}'"/>
  <xsl:variable name="s">
    <xsl:choose>
      <xsl:when test="m:condition or m:domainofapplication">|</xsl:when>
      <xsl:otherwise>,</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <m:mfenced open="{$o}" close="{$c}" separators="{$s}">
   <xsl:choose>
   <xsl:when test="m:condition or m:domainofapplication">
     <xsl:if test="(not($a) and m:bvar) or m:*[not(self::m:bvar or self::m:condition or self::m:domainofapplication or (position() = 1 and $a))]">
       <m:mfenced open="" close="">
         <xsl:if test="not($a)">
           <xsl:apply-templates mode="c2p" select="m:bvar/node()"/>
         </xsl:if>
         <xsl:apply-templates mode="c2p" select="m:*[not(self::m:bvar or self::m:condition or self::m:domainofapplication or (position() = 1 and $a))]"/>
       </m:mfenced>
     </xsl:if>
     <xsl:if test="(not($a) and m:domainofapplication) or m:condition">
       <m:mfenced open="" close="">
         <xsl:if test="not($a)">
           <xsl:apply-templates mode="c2p" select="m:domainofapplication/node()"/>
         </xsl:if>
         <xsl:apply-templates mode="c2p" select="m:condition/node()"/>
       </m:mfenced>
     </xsl:if>
   </xsl:when>
   <xsl:otherwise>
    <xsl:for-each select="*">
      <xsl:if test="not(position() = 1 and $a)">
        <xsl:apply-templates mode="c2p" select="."/>
      </xsl:if>
    </xsl:for-each>
   </xsl:otherwise>
   </xsl:choose>
  </m:mfenced>
</xsl:template>

</xsl:stylesheet>
