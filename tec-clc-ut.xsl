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
    $Id: tec-clc-ut.xsl 24 2008-12-16 01:41:51Z I.zaufi $

    Event calculation tests
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
                <xsl:variable name="tabled-events">
                    <xsl:call-template name="calc-table-data" />
                </xsl:variable>
                <xsl:call-template name="render-table-data">
                    <xsl:with-param name="data" select="exsl:node-set($tabled-events)" />
                    <xsl:with-param name="ut-root" select="/" />
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <tec:error>
                    <xsl:text>Source XML file is not formed well! Check participants and/or events list!</xsl:text>
                </tec:error>
            </xsl:otherwise>
        </xsl:choose>
    </unit-test-result>
</xsl:template>

<xsl:template name="render-table-data">
    <xsl:param name="data" />
    <xsl:param name="ut-root" />

    <xsl:for-each select="$data/tec:event">
        <result>
            <xsl:copy-of select="." />
            <xsl:variable name="event-results" select="." />
            <xsl:variable name="pos" select="number(./tec:pos)" />
            <xsl:variable name="expected-results" select="$ut-root//tec:event[$pos]/tec:expected-results" />
            <xsl:variable name="re" select="count($expected-results/tec:error)" />
            <xsl:choose>
                <xsl:when test="count($event-results/tec:error) = $re and count($event-results/tec:error) != 0">
                    <passed>Error was expected</passed>
                </xsl:when>
                <xsl:when test="count($event-results/tec:error) = $re and count($event-results/tec:error) = 0">
                    <xsl:choose>
                        <!-- Check event position -->
                        <xsl:when test="$expected-results/tec:pos != tec:pos">
                            <fail>
                                <xsl:text>Event positions r differ: got </xsl:text>
                                <xsl:value-of select="tec:pos" />
                                <xsl:text> but expected </xsl:text>
                                <xsl:value-of select="$expected-results/tec:pos" />
                            </fail>
                        </xsl:when>
                        <!-- Check event total cost -->
                        <xsl:when test="$expected-results/tec:total != tec:total">
                            <fail>
                                <xsl:text>Totals r differ: got </xsl:text>
                                <xsl:value-of select="tec:total" />
                                <xsl:text> but expected </xsl:text>
                                <xsl:value-of select="$expected-results/tec:total" />
                            </fail>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Check expected values for all participants (who also expected) -->
                            <xsl:for-each select="$expected-results/tec:participant">
                                <xsl:variable name="pid" select="@id" />
                                <xsl:variable name="pr" select="$event-results/tec:participant[@id = $pid]" />
                                <xsl:choose>
                                    <!-- Check that we've got results for expected participant -->
                                    <xsl:when test="count($pr) = 0">
                                        <fail>
                                            <xsl:text>Participant with id '</xsl:text>
                                            <xsl:value-of select="$pid" />
                                            <xsl:text>' have no results as expected </xsl:text>
                                        </fail>
                                    </xsl:when>
                                    <!-- Check spent value -->
                                    <xsl:when test="$pr/tec:spent != tec:spent">
                                        <fail>
                                            <xsl:text>Participant with id '</xsl:text>
                                            <xsl:value-of select="$pid" />
                                            <xsl:text>': check 'spent' value: got </xsl:text>
                                            <xsl:value-of select="$pr/tec:spent" />
                                            <xsl:text> but expected </xsl:text>
                                            <xsl:value-of select="tec:spent" />
                                        </fail>
                                    </xsl:when>
                                    <!-- Check payment value -->
                                    <xsl:when test="$pr/tec:payment != tec:payment">
                                        <fail>
                                            <xsl:text>Participant with id '</xsl:text>
                                            <xsl:value-of select="$pid" />
                                            <xsl:text>': check 'payment' value: got </xsl:text>
                                            <xsl:value-of select="$pr/tec:payment" />
                                            <xsl:text> but expected </xsl:text>
                                            <xsl:value-of select="tec:payment" />
                                        </fail>
                                    </xsl:when>
                                    <!-- Check balance value -->
                                    <xsl:when test="$pr/tec:balance != tec:balance">
                                        <fail>
                                            <xsl:text>Participant with id '</xsl:text>
                                            <xsl:value-of select="$pid" />
                                            <xsl:text>': check 'balance' value: got </xsl:text>
                                            <xsl:value-of select="$pr/tec:balance" />
                                            <xsl:text> but expected </xsl:text>
                                            <xsl:value-of select="tec:balance" />
                                        </fail>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:if test="position() = last()">
                                            <passed>No errors</passed>
                                        </xsl:if>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="count($event-results/tec:error) != $re and count($event-results/tec:error) = 0">
                    <fail>Error expected</fail>
                </xsl:when>
                <xsl:when test="count($event-results/tec:error) = $re and count($event-results/tec:error) != 0">
                    <fail>Error was not expected</fail>
                </xsl:when>
                <xsl:otherwise>
                </xsl:otherwise>
            </xsl:choose>
        </result>
    </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
