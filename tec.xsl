<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = "1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:tec="http://code.google.com/p/team-expense-calc/#tec"
    xmlns:csslist="http://code.google.com/p/team-expense-calc/#csslist"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    exclude-result-prefixes="tec exsl"
  >

<xsl:import href="tec-lib.xsl" />

<xsl:output method="html"
    version="4.01"
    encoding="UTF-8"
    indent="yes"
    omit-xml-declaration="no"
    standalone="no"
    doctype-public="-//W3C//DTD XHTML 1.1//EN"
    doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
  />

<!--
    $Id: tec.xsl 24 2008-12-16 01:41:51Z I.zaufi $

    Team Expense Calculator
    Copyright (c) 2008 by zaufi

  -->

<xsl:key name="used-currency" match="tec:currency" use="@id" />
<xsl:key name="events-by-currency" match="tec:event" use="tec:used-currency/@id" />

<!-- Predefined list of CSS files provided with package -->
<xsl:variable name="stylesheets">
    <csslist:stylesheets>
        <csslist:stylesheet default="true">
            <csslist:file>tec.css</csslist:file>
            <csslist:title>Default theme</csslist:title>
        </csslist:stylesheet>

        <csslist:stylesheet>
            <csslist:file>tec-green.css</csslist:file>
            <csslist:title>Green scheme by Lilia (just a test)</csslist:title>
        </csslist:stylesheet>
    </csslist:stylesheets>
</xsl:variable>

<xsl:template match="/">
    <html>
        <head>
            <link rel="stylesheet" href="tec-layout.css" type="text/css" />
            <link rel="stylesheet" href="tec-table.css" type="text/css" />
            <xsl:call-template name="render-stylesheet-links">
                <xsl:with-param name="stylesheets" select="exsl:node-set($stylesheets)//csslist:stylesheet[@default = 'true']" />
                <xsl:with-param name="type" select="'stylesheet'" />
            </xsl:call-template>
            <xsl:call-template name="render-stylesheet-links">
                <xsl:with-param name="stylesheets" select="exsl:node-set($stylesheets)//csslist:stylesheet[not(@default)]" />
                <xsl:with-param name="type" select="'alternative stylesheet'" />
            </xsl:call-template>

            <meta name="Description" content="Team Expenses Calculator" />
            <title><xsl:value-of select="/tec:arrangement/tec:title" /></title>
            <style type="text/css">
                <xsl:text>th.member-data { width: </xsl:text>
                <xsl:value-of
                    select="floor(90 div (count(/tec:arrangement/tec:members//tec:member)))"
                  />
                <xsl:text>%; }</xsl:text>
            </style>
            <script src="http://code.jquery.com/jquery-1.8.3.js"></script>
            <script type="text/javascript" language="javascript" src="http://www.datatables.net/release-datatables/media/js/jquery.dataTables.js"></script>
            <script type="text/javascript" charset="utf-8" src="http://www.datatables.net/release-datatables/extras/FixedHeader/js/FixedHeader.js"></script>
            <script type="text/javascript" charset="utf-8" src="tec.js">
            </script>
            <xsl:variable name="members-cnt" select="count(/tec:arrangement/tec:members/tec:member)"/>
            <xsl:variable name="native-cur" select="//tec:arrangement/tec:currencies/tec:currency[@native = 'true']/@id" />
            <script type="text/javascript">
              var arr = [0];
              for (var i = 1; i &lt; <xsl:value-of select="$members-cnt" /> + 1; ++i)
                  arr[i] = i;
              $(document).ready(function() {
                    oTable = $('#main').dataTable({
                        "bJQueryUI": true,
                        "asSorting": [],
                         "aoColumnDefs": [{ "sType": "num-html", "aTargets": [0] },
                            { "sType": "xch-html", "aTargets": arr },
                            { "sType": "xch", "aTargets": [<xsl:value-of select="$members-cnt" /> + 1] }],
                         "sPaginationType": "full_numbers"
                    });
                    new FixedHeader(oTable);
                } );
                var exch_table = [];
                <xsl:for-each select="//tec:arrangement/tec:currencies/tec:currency">
                    <xsl:variable name="cur-name" select="./tec:name" />
                    <xsl:for-each select="./tec:xchg[@to = $native-cur]">
                    <xsl:text>exch_table["</xsl:text>
                      <xsl:value-of select="$cur-name" />
                      <xsl:text>"] = </xsl:text>
                      <xsl:value-of select="text()" />
                      <xsl:text>;</xsl:text>
                    </xsl:for-each>
                </xsl:for-each>
            </script>
        </head>
        <body>
            <h1><xsl:value-of select="/tec:arrangement/tec:title" /></h1>
            <!-- Is there any team members present and events -->
            <xsl:variable name="is-valid-input">
                <xsl:call-template name="is-input-data-ok" />
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$is-valid-input = 'true'">
                    <xsl:variable name="tabled-events">
                        <xsl:call-template name="calc-table-data" />
                    </xsl:variable>
                    <table id="main" class="events">
                        <!--<caption style="caption-side: bottom;">Detailed Events List</caption>-->
                        <thead>
                            <xsl:call-template name="render-table-headers">
                                <xsl:with-param name="row-class" select="'header'" />
                            </xsl:call-template>
                        </thead>
                        <tfoot>
                            <xsl:call-template name="render-table-headers">
                                <xsl:with-param name="row-class" select="'footer'" />
                            </xsl:call-template>
                        </tfoot>
                        <tbody>
                            <xsl:call-template name="render-table-data">
                                <xsl:with-param name="data" select="exsl:node-set($tabled-events)" />
                                <xsl:with-param name="root" select="/" />
                            </xsl:call-template>
                        </tbody>
                    </table>
                    <table id="total" class="summory">
                        <caption>Summory</caption>
                        <tfoot>
                        <xsl:call-template name="render-table-headers">
                            <xsl:with-param name="row-class" select="'header'" />
                        </xsl:call-template>
                        </tfoot>
                        <xsl:call-template name="render-currency-totals">
                            <xsl:with-param name="data" select="exsl:node-set($tabled-events)" />
                        </xsl:call-template>
                        <xsl:call-template name="render-final-balance">
                            <xsl:with-param name="data" select="exsl:node-set($tabled-events)" />
                            <xsl:with-param name="root" select="/" />
                        </xsl:call-template>
                    </table>
                </xsl:when>
                <xsl:otherwise>
                    <span class="error">
                        <xsl:text>Source XML file is not formed well! Check participants and/or events list!</xsl:text>
                    </span>
                </xsl:otherwise>
            </xsl:choose>
        </body>
    </html>
</xsl:template>


<xsl:template name="render-table-headers">
    <xsl:param name="row-class" />
    <tr>
        <xsl:attribute name="class">
            <xsl:value-of select="$row-class" />
        </xsl:attribute>

        <!-- Event headers -->
        <th class="event-num" title="Event Number">#</th>
        <!-- Make a header per user -->
        <xsl:for-each select="/tec:arrangement/tec:members/tec:member">
            <th class="member-data">
                <xsl:attribute name="title">
                    <xsl:value-of select="@comment" />
                </xsl:attribute>
                <xsl:value-of select="text()" />
            </th>
        </xsl:for-each>
        <th class="event-total-cost" title="Total Cost of Event">Total</th>
    </tr>
</xsl:template>


<xsl:template name="render-table-data">
    <xsl:param name="data" />
    <xsl:param name="root" />
    <xsl:for-each select="$data/tec:event">
        <tr>
            <xsl:variable name="event" select="." />
            <!-- Render event number with and tooltip with details -->
            <th>
                <xsl:value-of select="tec:pos" />
                <div class="tooltip">
                    <span class="event-details">
                        <xsl:call-template name="set-tooltip-width">
                            <xsl:with-param name="text" select="tec:text" />
                        </xsl:call-template>
                        <table>
                            <tr>
                                <td>Event:</td>
                                <td><xsl:value-of select="tec:text" /></td>
                            </tr>
                            <tr>
                                <td>Currency:</td>
                                <td><xsl:value-of select="tec:used-currency"/></td>
                            </tr>
                        </table>
                    </span>
                </div>
            </th>

            <xsl:choose>
                <xsl:when test="count(tec:error) &gt; 0">
                    <td class="alert">
                        <xsl:attribute name="colspan">
                            <xsl:value-of select="1 + count($root/tec:arrangement/tec:members/tec:member)" />
                        </xsl:attribute>
                        <xsl:value-of select="tec:error" />
                    </td>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Show details for all members -->
                    <xsl:for-each select="$root/tec:arrangement/tec:members/tec:member">
                        <xsl:variable name="member-id" select="@id" />
                        <xsl:variable name="member" select="$event/tec:participant[@id = $member-id]" />
                        <xsl:choose>
                            <xsl:when test="boolean($member)">
                                <td>
                                    <xsl:attribute name="class">
                                        <xsl:call-template name="classname-from-number">
                                            <xsl:with-param name="number" select="$member/tec:balance" />
                                        </xsl:call-template>
                                    </xsl:attribute>
                                    <xsl:value-of select="format-number($member/tec:balance, '###,###.##')" />
                                    <div class="tooltip">
                                        <span>
                                            <xsl:attribute name="class">
                                                <xsl:call-template name="classname-from-position">
                                                    <xsl:with-param name="position" select="position()" />
                                                    <xsl:with-param name="count" select="count($root/tec:arrangement/tec:members/tec:member)" />
                                                </xsl:call-template>
                                            </xsl:attribute>
                                            <table>
                                                <tr>
                                                    <td>Spent:</td>
                                                    <td>
                                                        <span class="minus">
                                                            <xsl:value-of select="format-number($member/tec:spent, '###,###.##')" />
                                                            <xsl:text> </xsl:text>
                                                            <xsl:value-of select="$event/tec:used-currency" />
                                                        </span>
                                                    </td>
                                                </tr>
                                                <tr>
                                                    <td>Payed:</td>
                                                    <td>
                                                        <span>
                                                            <xsl:attribute name="class">
                                                                <xsl:call-template name="classname-from-number">
                                                                    <xsl:with-param name="number" select="$member/tec:payment" />
                                                                </xsl:call-template>
                                                            </xsl:attribute>
                                                            <xsl:value-of select="format-number($member/tec:payment, '###,###.##')"/>
                                                            <xsl:text> </xsl:text>
                                                            <xsl:value-of select="$event/tec:used-currency" />
                                                        </span>
                                                    </td>
                                                </tr>
                                            </table>
                                        </span>
                                    </div>
                                </td>
                            </xsl:when>
                            <xsl:otherwise>
                                <td class="empty" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>
                    <!-- Show total cost -->
                    <td class="total">
                        <xsl:value-of select="tec:total" />
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="tec:used-currency"/>
                    </td>
                </xsl:otherwise>
            </xsl:choose>
        </tr>
    </xsl:for-each>
</xsl:template>


<xsl:template name="render-currency-totals">
    <xsl:param name="data" />
    <tr>
        <th>
            <xsl:attribute name="colspan">
                <xsl:value-of select="2 + count(/tec:arrangement/tec:members/tec:member)" />
            </xsl:attribute>
            <xsl:text>Balance by currency</xsl:text>
        </th>
    </tr>
    <xsl:for-each select="/tec:arrangement/tec:currencies/tec:currency">
        <xsl:variable name="currency" select="." />
        <tr>
            <!-- Show header with currency name -->
            <th>
                <xsl:value-of select="$currency/tec:name" />
                <div class="tooltip">
                    <span class="xchg-rates"><table>
                        <xsl:for-each select="/tec:arrangement/tec:currencies/tec:currency[@id = $currency/@id]/tec:xchg">
                            <tr>
                                <td>
                                    <xsl:value-of select="@value" />
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="$currency/tec:name" />
                                </td>
                                <td>=</td>
                                <td>
                                    <xsl:value-of select="text()" />
                                    <xsl:text> </xsl:text>
                                    <xsl:value-of select="key('used-currency', @to)/tec:name" />
                                </td>
                            </tr>
                        </xsl:for-each>
                    </table></span>
                </div>
            </th>
            <!-- Show total by currency -->
            <xsl:choose>
                <xsl:when test="count($data/tec:event/tec:used-currency[@id = $currency/@id]/../tec:error) != 0">
                    <td class="alert">
                        <xsl:attribute name="colspan">
                            <xsl:value-of select="1 + count(/tec:arrangement/tec:members/tec:member)" />
                        </xsl:attribute>
                        <xsl:value-of select="tec:error" />
                        <xsl:text>Unable to calculate totals due an errors above</xsl:text>
                    </td>
                </xsl:when>
                <xsl:otherwise>
                    <!-- Show per member totals by currency -->
                    <xsl:for-each select="/tec:arrangement/tec:members/tec:member">
                        <xsl:variable name="member-id" select="@id" />
                        <xsl:variable name="balance"
                            select="sum($data/tec:event/tec:used-currency[@id = $currency/@id]/../tec:participant[@id = $member-id]/tec:balance)"
                          />
                        <td>
                            <xsl:attribute name="class">
                                <xsl:call-template name="classname-from-number">
                                    <xsl:with-param name="number" select="$balance" />
                                </xsl:call-template>
                            </xsl:attribute>
                            <xsl:value-of select="format-number($balance, '###,###.##')"/>
                        </td>
                    </xsl:for-each>
                    <td class="total">
                        <xsl:variable name="tcc">
                            <xsl:value-of select="sum($data/tec:event/tec:used-currency[@id = $currency/@id]/../tec:participant/tec:payment)" />
                        </xsl:variable>
                        <xsl:value-of select="format-number($tcc, '###,###.##')"/>
                    </td>
                </xsl:otherwise>
            </xsl:choose>
        </tr>
    </xsl:for-each>
</xsl:template>


<xsl:template name="render-final-balance">
    <xsl:param name="data" />
    <tr>
        <th>
            <xsl:attribute name="colspan">
                <xsl:value-of select="2 + count(/tec:arrangement/tec:members/tec:member)" />
            </xsl:attribute>
            <xsl:text>Final balance in a native currency</xsl:text>
        </th>
    </tr>
    <tr>
        <th>
            <xsl:value-of select="/tec:arrangement/tec:currencies/tec:currency[@native = 'true']/tec:name" />
        </th>
        <xsl:choose>
            <xsl:when test="count($data/tec:event/tec:error) != 0">
                <td class="alert">
                    <xsl:attribute name="colspan">
                        <xsl:value-of select="1 + count(/tec:arrangement/tec:members/tec:member)" />
                    </xsl:attribute>
                    <xsl:value-of select="tec:error" />
                    <xsl:text>Unable to calculate totals due an errors above</xsl:text>
                </td>
            </xsl:when>
            <xsl:otherwise>
                <!-- Calculate per member total cost of vacation in natve currency -->
                <xsl:for-each select="/tec:arrangement/tec:members/tec:member">
                    <xsl:variable name="member-id" select="@id" />
                    <xsl:variable name="final-balance" select="sum($data/tec:event/tec:participant[@id = $member-id]/tec:native-balance)" />
                <td>
                    <xsl:attribute name="class">
                        <xsl:call-template name="classname-from-number">
                            <xsl:with-param name="number" select="$final-balance" />
                        </xsl:call-template>
                    </xsl:attribute>
                    <xsl:value-of select="format-number($final-balance, '###,###.##')" />
                </td>
                </xsl:for-each>
                <!-- Calculate total cost of vacation in natve currency -->
                <td class="total">
                    <xsl:value-of select="format-number(sum($data/tec:event/tec:native-total), '###,###.##')" />
                </td>
            </xsl:otherwise>
        </xsl:choose>
    </tr>
</xsl:template>

</xsl:stylesheet>
