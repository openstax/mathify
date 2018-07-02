<!-- DTD for the Questions Markup Language (QML)                  -->
<!-- Version 1.0                                                  -->
<!--                                                              -->   
<!-- This entity may be identified by the following PUBLIC        -->
<!-- and SYSTEM identifiers                                       -->
<!--                                                              -->
<!-- PUBLIC:  -//CNX//ELEMENTS QML 1.0 Elements//EN               -->
<!-- SYSTEM:  http://cnx.rice.edu/technology/qml/schema/dtd/1.0/qml1.mod            -->
<!--  xmlns:  http://cnx.rice.edu/qml/1.0                         -->
<!--                                                              -->
<!-- CVS Version: $Revision: 8254 $                                -->
<!-- Modified: $Date: 2005-06-30 14:21:34 -0500 (Thu, 30 Jun 2005) $                       -->
<!-- Maintained by the Learning Assessment Team                   -->
<!-- email: asses@cnx.rice.edu                                    -->
<!--                                                              -->

<!-- Define the global namespace attributes -->
<![%QML.prefixed;[
<!ENTITY % QML.xmlns.attrib
    "%NS.decl.attrib;"
>
]]>
<!ENTITY % QML.xmlns.attrib
    "xmlns CDATA #FIXED '%QML.xmlns;' %NS.decl.attrib;"
>

<!-- Define a common set of attributes for all document elements -->
<!ENTITY % QML.Common.attrib
         "%QML.xmlns.attrib;"
>

<!-- Define the marked up "text" content model -->
<!ENTITY % QML.text "(#PCDATA)">


<!-- Define the elements and attributes of the document -->
<!ENTITY % QML.problemset.content "(%QML.item.qname;)+">
<!ELEMENT %QML.problemset.qname; %QML.problemset.content; >
          <!ATTLIST %QML.problemset.qname; %QML.xmlns.attrib;>
          <!ATTLIST %QML.problemset.qname; id ID #IMPLIED>

<!ENTITY % QML.item.content "(%QML.question.qname;, %QML.resource.qname;*, %QML.answer.qname;*, %QML.hint.qname;*, %QML.feedback.qname;?, %QML.key.qname;?)">
<!ELEMENT %QML.item.qname; %QML.item.content; >
          <!ATTLIST %QML.item.qname; %QML.xmlns.attrib;>
          <!ATTLIST %QML.item.qname; id ID #REQUIRED>
          <!ATTLIST %QML.item.qname; type (single-response|multiple-response|text-response|ordered-response) #REQUIRED>

<!ENTITY % QML.question.content "%QML.text;">
<!ELEMENT %QML.question.qname; %QML.question.content; >
          <!ATTLIST %QML.question.qname; %QML.xmlns.attrib;>

<!ENTITY % QML.resource.content "EMPTY">
<!ELEMENT %QML.resource.qname; %QML.resource.content; >
          <!ATTLIST %QML.resource.qname; %QML.xmlns.attrib;>
          <!ATTLIST %QML.resource.qname; uri CDATA #REQUIRED>
          <!ATTLIST %QML.resource.qname; id ID #IMPLIED>

<!ENTITY % QML.answer.content "(%QML.response.qname;?, (%QML.feedback.qname;, %QML.feedback.qname;?)?)">
<!ELEMENT %QML.answer.qname; %QML.answer.content; >
          <!ATTLIST %QML.answer.qname; id ID #IMPLIED>
          <!ATTLIST %QML.answer.qname; %QML.xmlns.attrib;>

<!ENTITY % QML.response.content "%QML.text;">
<!ELEMENT %QML.response.qname; %QML.response.content; >
          <!ATTLIST %QML.response.qname; %QML.xmlns.attrib;>

<!ENTITY % QML.feedback.content "%QML.text;">
<!ELEMENT %QML.feedback.qname; %QML.feedback.content; >
          <!ATTLIST %QML.feedback.qname; %QML.xmlns.attrib;>
          <!ATTLIST %QML.feedback.qname; correct (yes|no) #IMPLIED>

<!ENTITY % QML.hint.content "%QML.text;">
<!ELEMENT %QML.hint.qname; %QML.hint.content; >
          <!ATTLIST %QML.hint.qname; %QML.xmlns.attrib;>

<!ENTITY % QML.key.content "%QML.text;">
<!ELEMENT %QML.key.qname; %QML.key.content; >
          <!ATTLIST %QML.key.qname; %QML.xmlns.attrib;>
          <!ATTLIST %QML.key.qname; answer CDATA #IMPLIED>

