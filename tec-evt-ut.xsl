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
    $Id: tec-evt-ut.xsl 24 2008-12-16 01:41:51Z I.zaufi $

    Team Expense Calculator
    Copyright (c) 2008 by zaufi

    Event total sum unit test

  -->

<xsl:template match="/">
    <xsl:value-of select="name()" />
    <unit-test-result xmlns="http://code.google.com/p/team-expense-calc/#tec">
        <xsl:for-each select="//tec:event">
            <test>
                <xsl:copy-of select="." />
                <xsl:variable name="result">
                    <xsl:call-template name="get-event-total-cost">
                        <xsl:with-param name="event" select="." />
                    </xsl:call-template>
                </xsl:variable>
                <result>
                    <xsl:value-of select="$result" />
                </result>
                <xsl:choose>
                    <xsl:when test="$result = @expect">
                        <passed />
                    </xsl:when>
                    <xsl:otherwise>
                        <failed />
                    </xsl:otherwise>
                </xsl:choose>
            </test>
        </xsl:for-each>
    </unit-test-result>
</xsl:template>

</xsl:stylesheet>
