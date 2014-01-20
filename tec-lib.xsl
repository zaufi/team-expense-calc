<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version = "1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tec="http://code.google.com/p/team-expense-calc/#tec"
    xmlns:csslist="http://code.google.com/p/team-expense-calc/#csslist"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="csslist exsl"
  >

<!-- Validate input XML -->
<xsl:template name="is-input-data-ok">
    <!-- TODO: Check XML validity: currecies list, members list, events list -->
    <xsl:choose>
        <xsl:when test="count(/tec:arrangement/tec:members) = 0">
            <xsl:value-of select="false()" />
        </xsl:when>
        <xsl:when test="count(/tec:arrangement/tec:events) = 0">
            <xsl:value-of select="false()" />
        </xsl:when>
        <xsl:when test="count(/tec:arrangement/tec:currencies) = 0">
            <xsl:value-of select="false()" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="true()" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- Convert money from one currency to another using excnahge rates -->
<xsl:template name="convert-currency">
    <xsl:param name="amount" />
    <xsl:param name="from" />
    <xsl:param name="to" />
    <xsl:param name="rates" />
    <!-- TODO: It is better to return 0 if 'to' and 'from' the same IDs -->
    <xsl:variable name="value" select="$rates/tec:currency[@id=$from]/tec:xchg[@to=$to]/@value" />
    <xsl:variable name="rate" select="$rates/tec:currency[@id=$from]/tec:xchg[@to=$to]" />
    <xsl:value-of select="$amount div $value * $rate" />
</xsl:template>


<xsl:template name="is-event-participant-valid">
    <xsl:param name="event" />

    <xsl:for-each select="$event/tec:participant">
        <xsl:choose>
            <!-- If payment is present it must be convertible to number -->
            <xsl:when test="string-length(current()/@payment) &gt; 0 and string(number(current()/@payment)) = 'NaN'">
                <xsl:value-of select="false()" />
            </xsl:when>
            <!-- If spent is present it must be convertible to number -->
            <xsl:when test="string-length(current()/@spent) &gt; 0 and string(number(current()/@spent)) = 'NaN'">
                <xsl:value-of select="false()" />
            </xsl:when>
            <!-- If some of them less than 0  -->
            <xsl:when test="current()/@payment &lt;= 0 or current()/@spent &lt; 0">
                <xsl:value-of select="false()" />
            </xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>

</xsl:template>

<!-- TODO: Need to check that all members and used currency is present!! -->
<xsl:template name="is-event-valid">
    <xsl:param name="event" />

    <xsl:choose>
        <xsl:when test="count($event/tec:participant) != 0">
            <xsl:variable name="r">
                <xsl:call-template name="is-event-participant-valid">
                    <xsl:with-param name="event" select="$event" />
                </xsl:call-template>
            </xsl:variable>

            <!-- Going to check totals only if previous test passed -->
            <xsl:variable name="total-payments">
                <xsl:value-of select="sum($event/tec:participant[@payment]/@payment)" />
            </xsl:variable>
            <xsl:variable name="total-spent">
                <xsl:value-of select="sum($event/tec:participant[@spent]/@spent)" />
            </xsl:variable>

            <xsl:choose>
                <!-- r could contain smth like "falsefalsefalse"; If it's empty — no errors were occured -->
                <xsl:when test="$r != ''">
                    <!-- Smth wrong with one of participant -->
                    <xsl:value-of select="false()" />
                </xsl:when>
                <!-- Make sure that all participants have IDs -->
                <xsl:when test="count($event/tec:participant) != count($event/tec:participant[@id])">
                    <xsl:value-of select="false()" />
                </xsl:when>
                <!-- Event have to has some cost -->
                <xsl:when test="$total-payments = 0">
                    <xsl:value-of select="false()" />
                </xsl:when>
                <!-- Sum of payments in this event must be greather or equal than sum of explicitly spent money -->
                <xsl:when test="($total-payments - $total-spent) &lt; 0">
                    <xsl:value-of select="false()" />
                </xsl:when>
                <!-- Balance must be exactly zero if everybody payed and spent smth -->
                <xsl:when test="($total-payments - $total-spent) != 0
                    and count($event/tec:participant) = count($event/tec:participant[@spent])
                    and count($event/tec:participant) = count($event/tec:participant[@payment])
                  ">
                    <xsl:value-of select="false()" />
                </xsl:when>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <!-- Event w/o participants is invalid! -->
            <xsl:value-of select="false()" />
        </xsl:otherwise>
    </xsl:choose>

</xsl:template>


<xsl:template name="get-event-total-cost">
    <xsl:param name="event" />

    <xsl:variable name="r">
        <xsl:call-template name="is-event-valid">
            <xsl:with-param name="event" select="$event" />
        </xsl:call-template>
    </xsl:variable>

    <xsl:choose>
        <xsl:when test="$r = 'false'">
            <xsl:value-of select="false()" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="sum($event/tec:participant[@payment]/@payment)" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template name="get-event-avg-cost">
    <xsl:param name="event" />

    <xsl:variable name="total">
        <xsl:call-template name="get-event-total-cost">
            <xsl:with-param name="event" select="$event" />
        </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="fixed-payments" select="sum($event/tec:participant[@spent]/@spent)" />

    <xsl:variable name="general-participants-count" select="count($event/tec:participant[not(@spent)])" />

    <xsl:value-of select="($total - $fixed-payments) div $general-participants-count" />
</xsl:template>


<xsl:template name="get-member-payment-for-event">
    <xsl:param name="member-id" />
    <xsl:param name="event" />

    <xsl:variable name="p" select="$event/tec:participant[@id=$member-id]" />
    <xsl:choose>
        <xsl:when test="count($p) != 0 and count($p/@payment) != 0">
            <xsl:value-of select="$event/tec:participant[@id=$member-id]/@payment" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="0" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template name="get-member-spent-for-event">
    <xsl:param name="member-id" />
    <xsl:param name="event" />

    <xsl:choose>
        <xsl:when test="count($event/tec:participant[@id=$member-id]) != 0">
            <xsl:choose>
                <xsl:when test="count($event/tec:participant[@id=$member-id]/@spent) != 0">
                    <xsl:value-of select="$event/tec:participant[@id=$member-id]/@spent" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="get-event-avg-cost">
                        <xsl:with-param name="event" select="$event" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="0" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<xsl:template name="calc-table-data">
    <xsl:for-each select="/tec:arrangement/tec:events/tec:event">
        <xsl:copy-of select="/tec:arrangement/tec:members" />
        <tec:event>
            <xsl:variable name="event" select="." />

            <tec:pos>
                <xsl:value-of select="position()" />
            </tec:pos>
            <tec:text>
                <xsl:value-of select="tec:text" />
            </tec:text>
            <tec:used-currency>
                <xsl:attribute name="id">
                    <xsl:value-of select="$event/tec:used-currency/@id" />
                </xsl:attribute>
                <xsl:value-of select="key('used-currency', $event/tec:used-currency/@id)/tec:name" />
            </tec:used-currency>

            <xsl:variable name="event-total-cost">
                <xsl:call-template name="get-event-total-cost">
                    <xsl:with-param name="event" select="." />
                </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
                <!-- TODO: DAMN! How $event-total-cost could be equal NaN here??? WTF is going on? -->
                <xsl:when test="$event-total-cost = 'false' or $event-total-cost = 'NaN'">
                    <tec:error>
                        <xsl:text>Invalid balance for this event. Check XML file!</xsl:text>
                    </tec:error>
                </xsl:when>
                <xsl:otherwise>
                    <tec:total>
                        <xsl:value-of select="$event-total-cost" />
                    </tec:total>
                    <tec:native-total>
                        <xsl:call-template name="convert-currency">
                            <xsl:with-param name="amount" select="$event-total-cost" />
                            <xsl:with-param name="from" select="$event/tec:used-currency/@id" />
                            <xsl:with-param name="to" select="/tec:arrangement/tec:currencies/tec:currency[@native = 'true']/@id"/>
                            <xsl:with-param name="rates" select="/tec:arrangement/tec:currencies"/>
                        </xsl:call-template>
                    </tec:native-total>
                    <xsl:call-template name="calc-per-member-event-data">
                        <xsl:with-param name="event" select="$event" />
                        <xsl:with-param name="event-total-cost" select="$event-total-cost" />
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>
        </tec:event>
    </xsl:for-each>
</xsl:template>


<xsl:template name="calc-per-member-event-data">
    <xsl:param name="event" />
    <xsl:param name="event-total-cost" />

    <xsl:for-each select="/tec:arrangement/tec:members/tec:member">
        <xsl:variable name="member-id" select="@id" />

        <xsl:if test="count($event/tec:participant[@id = $member-id]) != 0">
            <xsl:variable name="spent">
                <xsl:call-template name="get-member-spent-for-event">
                    <xsl:with-param name="member-id" select="$member-id" />
                    <xsl:with-param name="event" select="$event" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="payment">
                <xsl:call-template name="get-member-payment-for-event">
                    <xsl:with-param name="member-id" select="$member-id" />
                    <xsl:with-param name="event" select="$event" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="balance" select="$payment - $spent" />
            <tec:participant>
                <xsl:attribute name="id">
                    <xsl:value-of select="$member-id" />
                </xsl:attribute>
                <tec:spent>
                    <xsl:value-of select="$spent" />
                </tec:spent>
                <tec:payment>
                    <xsl:value-of select="$payment" />
                </tec:payment>
                <tec:balance>
                    <xsl:value-of select="$balance" />
                </tec:balance>
                <tec:native-balance>
                    <xsl:call-template name="convert-currency">
                        <xsl:with-param name="amount" select="$balance" />
                        <xsl:with-param name="from" select="$event/tec:used-currency/@id" />
                        <xsl:with-param name="to" select="/tec:arrangement/tec:currencies/tec:currency[@native = 'true']/@id"/>
                        <xsl:with-param name="rates" select="/tec:arrangement/tec:currencies"/>
                    </xsl:call-template>
                </tec:native-balance>
            </tec:participant>
        </xsl:if>
    </xsl:for-each>
</xsl:template>


<xsl:template name="classname-from-number">
    <xsl:param name="number" />

    <xsl:choose>
        <xsl:when test="$number = 0">
            <xsl:text>zero</xsl:text>
        </xsl:when>
        <xsl:when test="$number &gt; 0">
            <xsl:text>plus</xsl:text>
        </xsl:when>
        <xsl:when test="$number &lt; 0">
            <xsl:text>minus</xsl:text>
        </xsl:when>
    </xsl:choose>
</xsl:template>


<xsl:template name="classname-from-position">
    <xsl:param name="position"/>
    <xsl:param name="count" />

    <xsl:choose>
        <xsl:when test="$position &lt; (2 + $count) div 2">
            <xsl:text>left</xsl:text>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>right</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="render-stylesheet-links">
    <xsl:param name="stylesheets"/>
    <xsl:param name="type"/>

    <xsl:for-each select="$stylesheets">
        <link type="text/css">
            <xsl:attribute name="href">
                <xsl:value-of select="csslist:file" />
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="csslist:title" />
            </xsl:attribute>
            <xsl:attribute name="rel">
                <xsl:value-of select="$type" />
            </xsl:attribute>
        </link>
    </xsl:for-each>
</xsl:template>


<xsl:template name="set-tooltip-width">
    <xsl:param name="text"/>
    <xsl:attribute name="style">
        <xsl:text>width:</xsl:text>
        <xsl:choose>
            <xsl:when test="string-length($text) &gt; 30">
                <xsl:value-of select="'30'" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="2 + string-length($text)" />
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>em</xsl:text>
    </xsl:attribute>
</xsl:template>

</xsl:stylesheet>
