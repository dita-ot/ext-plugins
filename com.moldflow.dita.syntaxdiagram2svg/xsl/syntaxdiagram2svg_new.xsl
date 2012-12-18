<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:syntaxdiagram2svg="http://www.moldflow.com/namespace/2008/syntaxdiagram2svg">
    
    <!-- Class attribute on the SVG elements most likely to control CSS display.
            I think that coding can be eliminated. The dispatch routine probably
            determines the sort of object to draw. Need to determine relationship between
            dispatch and role. Does the onload attribute have a meaning for PDF? -->

    <xsl:variable name="syntaxdiagram2svg:css-filename" select="'syntaxdiagram.css'"/>
    <xsl:template name="syntaxdiagram2svg:create-svg-document">
        <svg class="syntaxdiagram" onload="syntaxdiagram_onloadSvgRoot(evt)" xmlns="http://www.w3.org/2000/svg">
            <xsl:call-template name="syntaxdiagram2svg:root"/>
        </svg>
    </xsl:template>

    <xsl:template name="syntaxdiagram2svg:create-svg-element">
       <svg class="syntaxdiagram" onload="syntaxdiagram_onloadSvgRoot(evt)">
          <xsl:call-template name="syntaxdiagram2svg:root"></xsl:call-template>
       </svg>
    </xsl:template>

    <xsl:template name="syntaxdiagram2svg:root">
        <g class="diagram" syntaxdiagram2svg:dispatch="diagram">
            <xsl:apply-templates select="." mode="syntaxdiagram2svg:top-level-walk"/>
        </g>
    </xsl:template>


    <!-- Walk along top-level elements in this part of the syntax diagram. -->
    <xsl:template match="*" mode="syntaxdiagram2svg:top-level-walk">
        <xsl:apply-templates select="." mode="syntaxdiagram2svg:top-level"/>
        <xsl:apply-templates select="following-sibling::*[1]"
            mode="syntaxdiagram2svg:top-level-walk"/>
    </xsl:template>

    <!-- Stop walking along elements at a syntaxdiagram, synblk or fragment. -->
    <xsl:template
        match="*[contains(@class, ' pr-d/syntaxdiagram ')
        or contains(@class, ' pr-d/synblk ')
        or contains(@class, ' pr-d/fragment ')]"
        mode="syntaxdiagram2svg:top-level-walk"/>

    <!-- Top-level items. -->
    <xsl:template match="*" mode="syntaxdiagram2svg:top-level">
        <xsl:choose>
            <xsl:when
                test="contains(@class, ' pr-d/synnote ')
                or contains(@class, ' pr-d/synnoteref ')
                or contains(@class, ' pr-d/groupchoice ') 
                or contains(@class, ' pr-d/groupcomp ') 
                or *[contains(@class, ' pr-d/repsep ')] 
                or @importance = 'optional' 
                or @importance = 'default'">
                <xsl:apply-templates select="." mode="syntaxdiagram2svg:default"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- Naked groupseq should be stripped so that parent diagram JavaScript can line-wrap it if needed. -->
                <xsl:apply-templates mode="syntaxdiagram2svg:default"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Standard group (sequence, composite, choice).
         Detect repsep (if any), then delegate to "real" body of group. -->
    <xsl:template
        match="*[contains(@class, ' pr-d/groupseq ')
              or contains(@class, ' pr-d/groupcomp ')
              or contains(@class, ' pr-d/groupchoice ')]"
        mode="syntaxdiagram2svg:default">
        <!-- not used <xsl:param name="compact"/> -->
        <xsl:param name="role" select="'forward'"/>
        <xsl:choose>
            <xsl:when test="*[contains(@class, ' pr-d/repsep ')]">
                <!-- repsep must be handled first. -->
                <g class="groupseq" syntaxdiagram2svg:dispatch="loop">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <xsl:if test="*[contains(@class, ' pr-d/repsep ')]/node()">
                        <xsl:apply-templates select="*[contains(@class, ' pr-d/repsep ')]"
                            mode="syntaxdiagram2svg:default">
                            <xsl:with-param name="role" select="'repsep'"/>
                        </xsl:apply-templates>
                    </xsl:if>
                    <xsl:apply-templates select="." mode="syntaxdiagram2svg:ignore-repsep"/>
                </g>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="syntaxdiagram2svg:ignore-repsep">
                    <!-- not used <xsl:with-param name="compact" select="$compact"/> -->
                    <xsl:with-param name="role" select="$role"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Group as child of groupchoice. -->
    <xsl:template
        match="*[contains(@class, ' pr-d/groupseq ')
        or contains(@class, ' pr-d/groupcomp ')]"
        mode="syntaxdiagram2svg:groupchoice-child">
        <!-- not used <xsl:param name="compact"/> -->
        <xsl:param name="role" select="'forward'"/>
        <xsl:choose>
            <!-- Default importance has already been handled by parent groupchoice. -->
            <xsl:when test="@importance='default'">
                <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                    <!-- not used <xsl:with-param name="compact" select="$compact"/> -->
                    <xsl:with-param name="role" select="$role"/>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="syntaxdiagram2svg:default">
                    <xsl:with-param name="role" select="$role"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Group (sequence, composite) body, ignoring repsep. -->
    <xsl:template
        match="*[contains(@class, ' pr-d/groupseq ')
              or contains(@class, ' pr-d/groupcomp ')]"
        mode="syntaxdiagram2svg:ignore-repsep">
        <!-- not used <xsl:param name="compact"/> -->
        <xsl:param name="role" select="'forward'"/>
        <xsl:choose>
            <xsl:when test="@importance = 'optional'">
                <!-- Optional items must be wrapped in a decision. -->
                <g class="groupseq" syntaxdiagram2svg:dispatch="decision">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <g syntaxdiagram2svg:dispatch="void" syntaxdiagram2svg:role="straight"/>
                    <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                        <xsl:with-param name="role" select="'downward'"/>
                    </xsl:apply-templates>
                </g>
            </xsl:when>
            <xsl:when test="@importance = 'default'">
                <!-- Default items must be wrapped in a decision. -->
                <g class="groupseq" syntaxdiagram2svg:dispatch="decision">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <g syntaxdiagram2svg:dispatch="void" syntaxdiagram2svg:role="straight"/>
                    <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                        <xsl:with-param name="role" select="'upward'"/>
                    </xsl:apply-templates>
                </g>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                    <!-- not used <xsl:with-param name="compact" select="$compact"/> -->
                    <xsl:with-param name="role" select="$role"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Group (choice) body, ignoring repsep. -->
    <xsl:template match="*[contains(@class, ' pr-d/groupchoice ')]"
        mode="syntaxdiagram2svg:ignore-repsep">
        <xsl:param name="role" select="'forward'"/>
        <xsl:choose>
            <!-- If only one choice, this isn't a choice at all. -->
            <xsl:when
                test="(not(@importance) or @importance = 'required') and count(*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))]) = 1">
                <xsl:call-template name="syntaxdiagram2svg:append-notes">
                    <xsl:with-param name="contents">
                        <xsl:apply-templates
                            select="*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))]"
                            mode="syntaxdiagram2svg:default">
                            <xsl:with-param name="role" select="$role"/>
                        </xsl:apply-templates>
                    </xsl:with-param>
                    <xsl:with-param name="role" select="$role"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="syntaxdiagram2svg:append-notes">
                    <xsl:with-param name="contents">
                        <g class="groupchoice" syntaxdiagram2svg:dispatch="decision">
                            <xsl:attribute name="syntaxdiagram2svg:role">
                                <xsl:value-of select="$role"/>
                            </xsl:attribute>
                            <xsl:choose>
                                <!-- Group is optional. -->
                                <xsl:when test="@importance = 'optional'">
                                    <g syntaxdiagram2svg:dispatch="void"
                                        syntaxdiagram2svg:role="straight"/>
                                    <xsl:apply-templates
                                        select="*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))][@importance = 'default']"
                                        mode="syntaxdiagram2svg:groupchoice-child">
                                        <xsl:with-param name="role" select="'upward'"/>
                                    </xsl:apply-templates>
                                    <xsl:apply-templates
                                        select="*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))][not(@importance = 'default')]"
                                        mode="syntaxdiagram2svg:groupchoice-child">
                                        <xsl:with-param name="role" select="'downward'"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <!-- groupchoice itself has importance = default.  (Odd, but has been seen in the wild.) -->
                                <xsl:when test="@importance = 'default'">
                                    <!-- Assume first item is the default. -->
                                    <xsl:apply-templates
                                        select="*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))][1]"
                                        mode="syntaxdiagram2svg:groupchoice-child">
                                        <xsl:with-param name="role" select="'upward'"/>
                                    </xsl:apply-templates>
                                    <xsl:apply-templates
                                        select="*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))][position() != 1]"
                                        mode="syntaxdiagram2svg:groupchoice-child">
                                        <xsl:with-param name="role" select="'downward'"/>
                                    </xsl:apply-templates>
                                </xsl:when>
                                <!-- Standard layout (first non-default is straight). -->
                                <xsl:otherwise>
                                    <xsl:apply-templates
                                        select="*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))][@importance = 'default']"
                                        mode="syntaxdiagram2svg:groupchoice-child">
                                        <xsl:with-param name="role" select="'upward'"/>
                                    </xsl:apply-templates>
                                    <!-- First child is the straight-through one. -->
                                    <xsl:apply-templates
                                        select="*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))][not(@importance = 'default')][1]"
                                        mode="syntaxdiagram2svg:groupchoice-child">
                                        <xsl:with-param name="role" select="'straight'"/>
                                    </xsl:apply-templates>
                                    <xsl:apply-templates
                                        select="*[not(contains(@class, ' pr-d/repsep ')) and not(contains(@class, ' topic/title '))][not(@importance = 'default')][position() &gt; 1]"
                                        mode="syntaxdiagram2svg:groupchoice-child">
                                        <xsl:with-param name="role" select="'downward'"/>
                                    </xsl:apply-templates>
                                </xsl:otherwise>
                            </xsl:choose>
                        </g>
                    </xsl:with-param>
                    <xsl:with-param name="role" select="$role"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- True body of groupseq, after dealing with repsep and importance. -->
    <xsl:template match="*[contains(@class, ' pr-d/groupseq ')]" mode="syntaxdiagram2svg:body-only">
        <xsl:param name="role" select="'forward'"/>

        <xsl:call-template name="syntaxdiagram2svg:groupseq-body">
            <xsl:with-param name="role" select="$role"/>
        </xsl:call-template>
    </xsl:template>

    <!-- True body of groupcomp, after dealing with repsep and importance. -->
    <xsl:template match="*[contains(@class, ' pr-d/groupcomp ')]" mode="syntaxdiagram2svg:body-only">
        <xsl:param name="role" select="'forward'"/>

        <xsl:choose>
            <xsl:when
                test="descendant::*[*[contains(@class, ' pr-d/repsep ')]
                or contains(@class, ' pr-d/groupchoice ')
                or @importance = 'optional'
                or @importance = 'default']">
                <!-- These preclude any compact (groupcomp) display. -->
                <xsl:call-template name="syntaxdiagram2svg:groupseq-body">
                    <xsl:with-param name="role" select="$role"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="syntaxdiagram2svg:groupcomp-body">
                    <xsl:with-param name="role" select="$role"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="syntaxdiagram2svg:groupseq-body">
        <xsl:param name="role" select="'forward'"/>
        <!-- Construct a sequence. -->
        <xsl:call-template name="syntaxdiagram2svg:append-notes">
            <xsl:with-param name="contents">
                <g class="groupseq" syntaxdiagram2svg:dispatch="sequence">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <xsl:apply-templates
                        select="*[not(contains(@class, ' topic/title ') or contains(@class, ' pr-d/repsep '))]"
                        mode="syntaxdiagram2svg:default"/>
                </g>
            </xsl:with-param>
            <xsl:with-param name="role" select="$role"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="syntaxdiagram2svg:groupcomp-body">
        <xsl:param name="role" select="'forward'"/>
        <!-- Construct a boxed (composite) item. -->
        <xsl:call-template name="syntaxdiagram2svg:append-notes">
            <xsl:with-param name="contents">
                <g class="boxed groupcomp" syntaxdiagram2svg:dispatch="boxed">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <xsl:attribute name="syntaxdiagram2svg:element">
                        <xsl:value-of select="local-name()"/>
                    </xsl:attribute>
                    <xsl:apply-templates
                        select="*[not(contains(@class, ' topic/title ') or contains(@class, ' pr-d/repsep '))]"
                        mode="syntaxdiagram2svg:groupcomp-child">
                        <!-- not used <xsl:with-param name="compact" select="1"/> -->
                    </xsl:apply-templates>
                </g>
            </xsl:with-param>
            <xsl:with-param name="role" select="$role"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Normally children of groupchoice behave as normal. -->
    <xsl:template match="*" mode="syntaxdiagram2svg:groupchoice-child">
        <xsl:param name="role"/>
        <xsl:apply-templates select="." mode="syntaxdiagram2svg:default">
            <xsl:with-param name="role" select="$role"/>
        </xsl:apply-templates>
    </xsl:template>

    <!-- groupseq/groupcomp inside compact remain compact. -->
    <xsl:template
        match="*[contains(@class, ' pr-d/groupseq ')
        or contains(@class, ' pr-d/groupcomp ')]"
        mode="syntaxdiagram2svg:groupcomp-child">
        <!-- not used <xsl:param name="compact"></xsl:param> -->
        <xsl:apply-templates mode="syntaxdiagram2svg:groupcomp-child"/>
    </xsl:template>

    <!-- Terminals and nonterminals. -->
    <xsl:template
        match="*[contains(@class, ' pr-d/kwd ')
        or contains(@class, ' pr-d/var ')
        or contains(@class, ' pr-d/delim ')
        or contains(@class, ' pr-d/oper ')
        or contains(@class, ' pr-d/sep ')
        or contains(@class, ' pr-d/fragref ')]"
        mode="syntaxdiagram2svg:default">
        <xsl:param name="role" select="'forward'"/>
        <xsl:choose>
            <!-- Optional goes below line. -->
            <xsl:when test="@importance = 'optional'">
                <g syntaxdiagram2svg:dispatch="decision">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <g syntaxdiagram2svg:dispatch="void" syntaxdiagram2svg:role="straight"/>
                    <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                        <xsl:with-param name="role" select="'downward'"/>
                    </xsl:apply-templates>
                </g>
            </xsl:when>
            <!-- Default goes above line. -->
            <xsl:when test="@importance = 'default'">
                <g syntaxdiagram2svg:dispatch="decision">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <g syntaxdiagram2svg:dispatch="void" syntaxdiagram2svg:role="straight"/>
                    <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                        <xsl:with-param name="role" select="'upward'"/>
                    </xsl:apply-templates>
                </g>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                    <xsl:with-param name="role" select="$role"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Terminal and nonterminals inside groupchoice. -->
    <xsl:template
        match="*[contains(@class, ' pr-d/kwd ')
        or contains(@class, ' pr-d/var ')
        or contains(@class, ' pr-d/delim ')
        or contains(@class, ' pr-d/oper ')
        or contains(@class, ' pr-d/sep ')
        or contains(@class, ' pr-d/fragref ')]"
        mode="syntaxdiagram2svg:groupchoice-child">
        <xsl:param name="role" select="'forward'"/>
        <xsl:choose>
            <!-- default case has already been dealt with by parent groupchoice. -->
            <xsl:when test="@importance = 'optional'">
                <g syntaxdiagram2svg:dispatch="decision">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <g syntaxdiagram2svg:dispatch="void" syntaxdiagram2svg:role="straight"/>
                    <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                        <xsl:with-param name="role" select="'downward'"/>
                    </xsl:apply-templates>
                </g>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                    <xsl:with-param name="role" select="$role"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Body of terminal (the bit in the box). -->
    <xsl:template
        match="*[contains(@class, ' pr-d/kwd ')
        or contains(@class, ' pr-d/var ')
        or contains(@class, ' pr-d/delim ')
        or contains(@class, ' pr-d/oper ')
        or contains(@class, ' pr-d/sep ')
        or contains(@class, ' pr-d/repsep ')]"
        mode="syntaxdiagram2svg:body-only">
        <xsl:param name="role" select="'forward'"/>
        <xsl:call-template name="syntaxdiagram2svg:append-notes">
            <xsl:with-param name="contents">
                <g syntaxdiagram2svg:dispatch="boxed">
                    <xsl:attribute name="class">
                        <xsl:text>boxed </xsl:text>
                        <xsl:value-of select="local-name()"/>
                    </xsl:attribute>
                    <xsl:attribute name="syntaxdiagram2svg:element">
                        <xsl:value-of select="local-name()"/>
                    </xsl:attribute>
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <xsl:call-template name="syntaxdiagram2svg:box-contents"/>
                </g>
            </xsl:with-param>
            <xsl:with-param name="role" select="$role"/>
        </xsl:call-template>
    </xsl:template>

    <!-- Terminal in a groupcomp: No box. -->
    <xsl:template
        match="*[contains(@class, ' pr-d/kwd ')
        or contains(@class, ' pr-d/var ')
        or contains(@class, ' pr-d/delim ')
        or contains(@class, ' pr-d/oper ')
        or contains(@class, ' pr-d/sep ')]"
        mode="syntaxdiagram2svg:groupcomp-child">
        <!-- not used <xsl:param name="role" select="'forward'"/> -->
        <g syntaxdiagram2svg:dispatch="unboxed" syntaxdiagram2svg:role="forward">
            <xsl:attribute name="class">
                <xsl:text>unboxed </xsl:text>
                <xsl:value-of select="local-name()"/>
            </xsl:attribute>
            <xsl:attribute name="syntaxdiagram2svg:element">
                <xsl:value-of select="local-name()"/>
            </xsl:attribute>
            <!-- <xsl:attribute name="syntaxdiagram2svg:role">
                <xsl:value-of select="$role"/>
            </xsl:attribute> -->
            <xsl:call-template name="syntaxdiagram2svg:box-contents"/>
        </g>
    </xsl:template>

    <!-- Generate text for contents of terminals. -->
    <xsl:template name="syntaxdiagram2svg:box-contents">
        <xsl:choose>
            <xsl:when test="node()">
                <xsl:apply-templates select="node()" mode="syntaxdiagram2svg:box-contents"/>
            </xsl:when>
            <xsl:when
                test="@scope = 'external'
                or @score = 'peer'
                or not(@href)
                or @href=''">
                <!-- Can't know the contents. -->
                <text class="text" syntaxdiagram2svg:dispatch="text">
                    ?
                </text>
            </xsl:when>
            <xsl:otherwise>
                <!-- fragref may be empty; fetch the contents from the href target. -->
                <xsl:call-template name="syntaxdiagram2svg:get-href"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- Text inside a box. -->
    <xsl:template match="text()" mode="syntaxdiagram2svg:box-contents">
        <xsl:choose>
            <xsl:when test="normalize-space(.)">
                <text class="text" syntaxdiagram2svg:dispatch="text">
                        <xsl:value-of select="."/>
                </text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[contains(@class, ' topic/desc ')]" mode="syntaxdiagram2svg:box-contents">
        <!-- Do nothing.  This shouldn't be there but topicpull wants to put a desc on all xrefs. -->
    </xsl:template>

    <!-- Need this if topicpull hasn't been run. -->
    <xsl:template name="syntaxdiagram2svg:get-href">
        <xsl:choose>
            <xsl:when test="contains(@href, '#')">
                <xsl:variable name="document" select="substring-before(@href, '#')"/>
                <xsl:choose>
                    <xsl:when test="contains(substring-after(@href, '#'), '/')">
                        <xsl:variable name="topicid"
                            select="substring-before(substring-after(@href, '#'), '/')"/>
                        <xsl:variable name="targetid"
                            select="substring-after(substring-after(@href, '#'), '/')"/>
                        <xsl:apply-templates
                            select="document($document, /)//*[contains(@class, ' topic/topic ')][@id = $topicid]//*[not(contains(@class, ' topic/topic '))][@id = $targetid]/*[contains(@class, ' topic/title ')]/node()"
                            mode="syntaxdiagram2svg:box-contents"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="topicid" select="substring-after(@href, '#')"/>
                        <xsl:apply-templates
                            select="document($document, /)//*[contains(@class, ' topic/topic ')][@id = $topicid]/*[contains(@class, ' topic/title ')]/node()"
                            mode="syntaxdiagram2svg:box-contents"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates
                    select="document(@href, /)//*[contains(@class, ' topic/topic ')][1]/*[contains(@class, ' topic/title ')]/node()"
                    mode="syntaxdiagram2svg:box-contents"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[contains(@class, ' pr-d/repsep ')]" mode="syntaxdiagram2svg:default">
        <xsl:choose>
            <xsl:when test="@importance = 'optional'">
                <g syntaxdiagram2svg:dispatch="revdecision" syntaxdiagram2svg:role="repsep">
                    <g syntaxdiagram2svg:dispatch="void" syntaxdiagram2svg:role="straight"> </g>
                    <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                        <xsl:with-param name="role" select="'downward'"/>
                    </xsl:apply-templates>
                </g>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="syntaxdiagram2svg:body-only">
                    <xsl:with-param name="role" select="'repsep'"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="syntaxdiagram2svg:append-notes">
        <xsl:param name="role"/>
        <xsl:param name="contents"/>
        <xsl:choose>
            <xsl:when
                test="following-sibling::*[1][contains(@class, ' pr-d/synnote ')][not(@id)]
                | following-sibling::*[1][contains(@class, ' pr-d/synnoteref ')][@href and @href != '']">
                <g syntaxdiagram2svg:dispatch="notecontainer">
                    <xsl:attribute name="syntaxdiagram2svg:role">
                        <xsl:value-of select="$role"/>
                    </xsl:attribute>
                    <xsl:copy-of select="$contents"/>
                    <xsl:apply-templates select="following-sibling::*[1]"
                        mode="syntaxdiagram2svg:note-walk"/>
                </g>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$contents"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[contains(@class, ' pr-d/synnote ')][not(@id)]"
        mode="syntaxdiagram2svg:note-walk">
        <xsl:apply-templates select="." mode="syntaxdiagram2svg:note"/>
        <xsl:apply-templates select="following-sibling::*[1]" mode="syntaxdiagram2svg:note-walk"/>
    </xsl:template>

    <xsl:template match="*[contains(@class, ' pr-d/synnoteref ')][@href and @href != '']"
        mode="syntaxdiagram2svg:note-walk">
        <xsl:apply-templates select="." mode="syntaxdiagram2svg:note"/>
        <xsl:apply-templates select="following-sibling::*[1]" mode="syntaxdiagram2svg:note-walk"/>
    </xsl:template>

    <xsl:template match="*" mode="syntaxdiagram2svg:note-walk"/>

    <xsl:template match="*[contains(@class, ' pr-d/synnote ')][not(@id)]"
        mode="syntaxdiagram2svg:default"/>

    <xsl:template match="*[contains(@class, ' pr-d/synnote ')][not(@id)]"
        mode="syntaxdiagram2svg:groupcomp-child">
        <g syntaxdiagram2svg:dispatch="note" class="unboxed note">
            <text>
                <xsl:call-template name="syntaxdiagram2svg:get-callout"/>
            </text>
        </g>
    </xsl:template>

    <xsl:template match="*[contains(@class, ' pr-d/synnote ')][not(@id)]"
        mode="syntaxdiagram2svg:note">
        <g syntaxdiagram2svg:dispatch="note" class="note">
            <text>
                <xsl:call-template name="syntaxdiagram2svg:get-callout"/>
            </text>
        </g>
    </xsl:template>

    <xsl:template match="*[contains(@class, ' pr-d/synnote ')][@id]"
        mode="syntaxdiagram2svg:default"> </xsl:template>

    <xsl:template match="*[contains(@class, ' pr-d/synnote ')][@id]"
        mode="syntaxdiagram2svg:groupcomp-child"> </xsl:template>

    <xsl:template name="syntaxdiagram2svg:get-callout">
        <xsl:choose>
            <xsl:when test="@callout">
                <xsl:value-of select="@callout"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:number format="1" count="*[contains(@class, ' topic/fn ')]" from="/*" level="any"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*[contains(@class, ' pr-d/synnoteref ')][@href and @href != '']"
        mode="syntaxdiagram2svg:default"/>

    <xsl:template match="*[contains(@class, ' pr-d/synnoteref ')][@href and @href != '']"
        mode="syntaxdiagram2svg:note">
        <g syntaxdiagram2svg:dispatch="note" class="note">
            <text>
                <xsl:call-template name="syntaxdiagram2svg:get-callout-reference"/>
            </text>
        </g>
    </xsl:template>

    <xsl:template match="*[contains(@class, ' pr-d/synnoteref ')][@href and @href != '']"
        mode="syntaxdiagram2svg:groupcomp-child">
        <g syntaxdiagram2svg:dispatch="note" class="note">
            <text>
                <xsl:call-template name="syntaxdiagram2svg:get-callout-reference"/>
            </text>
        </g>
    </xsl:template>

    <xsl:template name="syntaxdiagram2svg:get-callout-reference">
        <xsl:choose>
            <xsl:when test="contains(@href, '#')">
                <xsl:variable name="document" select="substring-before(@href, '#')"/>
                <xsl:choose>
                    <xsl:when test="contains(substring-after(@href, '#'), '/')">
                        <xsl:variable name="topicid"
                            select="substring-before(substring-after(@href, '#'), '/')"/>
                        <xsl:variable name="targetid"
                            select="substring-after(substring-after(@href, '#'), '/')"/>
                        <xsl:for-each
                            select="document($document, /)//*[contains(@class, ' topic/topic ')][@id = $topicid]//*[contains(@class, ' topic/fn ')][@id = $targetid]">
                            <xsl:call-template name="syntaxdiagram2svg:get-callout"/>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>synnoteref points at entire topic; should point at
                        footnote.</xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>synnoteref href points at entire file; should point at
                footnote.</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
