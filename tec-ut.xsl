<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = "1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tec="http://code.google.com/p/team-expense-calc/#tec"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
  >

<xsl:import href="tec-lib.xsl" />

<xsl:output method="xml"
    version="1.0"
    encoding="UTF-8"
    indent="yes"
    omit-xml-declaration="no"
  />

<!--
    $Id: tec-ut.xsl 24 2008-12-16 01:41:51Z I.zaufi $

    Team Expense Calculator
    Copyright (c) 2008 by zaufi

  -->

<xsl:key name="currency-name" match="tec:currency" use="@id" />
<xsl:key name="events-by-currency" match="tec:event" use="tec:used-currency/@id" />

<xsl:template match="/">
    <unit-test-result xmlns="http://code.google.com/p/team-expense-calc/#tec">
        <xsl:variable name="is-valid-input">
            <xsl:call-template name="is-input-data-ok" />
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$is-valid-input = 'true'">
            </xsl:when>
            <xsl:otherwise>
                <error>Input data verification failed</error>
            </xsl:otherwise>
        </xsl:choose>
    </unit-test-result>
</xsl:template>

</xsl:stylesheet>
