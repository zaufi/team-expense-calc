<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = "1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tec="http://code.google.com/p/team-expense-calc/#tec"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    exclude-result-prefixes="exsl"
  >

<xsl:import href="tec-lib.xsl" />

<xsl:output method="xml"
    version="1.0"
    encoding="UTF-8"
    indent="yes"
    omit-xml-declaration="no"
  />

<!--
    $Id: tec-eck-ut.xsl 24 2008-12-16 01:41:51Z I.zaufi $

    Event validation tests
    Copyright (c) 2008 by zaufi

  -->

<xsl:key name="currency-name" match="tec:currency" use="@id" />
<xsl:key name="events-by-currency" match="tec:event" use="tec:used-currency/@id" />


<xsl:template match="/">
    <unit-test-result>
        <!-- Is there any team members present and events -->
        <xsl:variable name="is-valid-input">
            <xsl:call-template name="is-input-data-ok" />
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$is-valid-input = 'true'">
                <xsl:call-template name="validate-events" />
            </xsl:when>
            <xsl:otherwise>
                <tec:error>
                    <xsl:text>Source XML file is not formed well! Check participants and/or events list!</xsl:text>
                </tec:error>
            </xsl:otherwise>
        </xsl:choose>
    </unit-test-result>
</xsl:template>

<xsl:template name="validate-events">
    <xsl:param name="data" />
    <xsl:param name="ut-root" />

    <xsl:for-each select="/tec:arrangement/tec:events/tec:event">
        <result>
            <xsl:copy-of select="." />
            <xsl:variable name="r">
                <xsl:call-template name="is-event-valid">
                    <xsl:with-param name="event" select="." />
                </xsl:call-template>
            </xsl:variable>
<!--             <xsl:value-of select="$r" /> -->
            <xsl:choose>
                <xsl:when test="$r = 'false' and count(./tec:expected-results/tec:error) != 0">
                    <passed>Error was expected</passed>
                </xsl:when>
                <xsl:when test="$r != 'false' and count(./tec:expected-results/tec:error) = 0">
                    <passed>No errors</passed>
                </xsl:when>
                <xsl:when test="$r != 'false' and count(./tec:expected-results/tec:error) != 0">
                    <fail>Error was expected but not happened</fail>
                </xsl:when>
                <xsl:when test="$r = 'false' and count(./tec:expected-results/tec:error) = 0">
                    <fail>Unexpected error</fail>
                </xsl:when>
<!--                <xsl:otherwise>
                    <xsl:value-of select="$r" />
                </xsl:otherwise>-->
            </xsl:choose>
        </result>
    </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
