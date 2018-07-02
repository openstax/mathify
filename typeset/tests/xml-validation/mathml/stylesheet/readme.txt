This conversion uses a modified ctop.xsl and the original can be found at http://www.w3.org/Math/XSL/

Changes made:
- use a m: prefix instead of mml: for MathJax
- &InvisibleTimes now shows up and doesn't cause an empty m:mo element
 (since MathJax runs in quirks-mode and garbles self-closed elements by trying to add a close tag at a random point later in the XML)
- Fixes m:min and m:max elements from leaking into Presentation MathML
- Supports using the trig functions as the non-1st argument to a m:apply
- Added support for the deprecated m:reln element
- Made integrals stretchy, added m:bvar support for m:sum, and added catch-all since cnxmathmlc2p.xsl uses xsl:apply-imports
- Fixed the m:root template pattern matching. There was a and/or precedence problem.