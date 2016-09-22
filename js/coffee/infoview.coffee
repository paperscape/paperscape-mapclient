# INFOVIEW module
#
# Popup that displays information about a selected paper.

define ['app/selected','app/world','app/search','jquery','jquery.mousewheel'], (SELECTED,WORLD,SEARCH,$) ->

    MAX_AUTHORS = 12

    exports = {}

    metas = []

    class Meta
        constructor: (id) ->
            @id =         id
            @numRefs  =   0
            @numCites =   0
            @title =      "Loading..."
            @authors =    "Loading..."
            @journal =    ""
            #@arxivId =    ""
            @categories = ""
            #@inspire =    ""
            @abstract =   null
            @year = 0
            @mpg = 0
            @cocodes = ""
            @loaded = false

        load: =>
            if @loaded 
                infoPopup(this)
            else 
                callback = (data) =>
                    @id =         data.id
                    @numRefs  =   data.numRefs
                    @numCites =   data.numCites
                    @title =      data.title
                    @authors =    data.authors
                    @journal =    data.journal
                    #@arxivId =    data.arxivId
                    @categories = data.categories
                    #@inspire =    data.inspire
                    @year =       data.year
                    @mpg =        data.mpg
                    @cocodes =    data.cocodes
                    @loaded = true
                    infoPopup(this)
                WORLD.fetchMetaForPaperId(@id, callback)

        loadAbstract: =>
            if @abstract?
                abstractPopup(this)
            else
                callback = (data) =>
                    @abstract = data.abstract
                    abstractPopup(this)
                WORLD.fetchAbstractForPaperId(@id, callback)
        ###
        inspireURL: =>
            if @inspire != ""
                return "http://inspirehep.net/record/" + @inspire
            else if @arxivId != ""
                if @arxivId.length in [9,10] and @arxivId[4] == "."
                    return "http://inspirehep.net/search?p=find+eprint+arxiv%3A" + @arxivId
                else
                    return "http://inspirehep.net/search?p=find+eprint+" + @arxivId
            else
                return null
        ###
        
    findMetaById = (id) => 
        # TODO binary search
        for meta in metas when meta.id == id
            return meta
        null

    getMeta = (id) =>
        meta = findMetaById(id)
        if not meta?
            meta = new Meta(id)
            metas.push(meta)
        meta

    infoPopup = (meta) -> 
        if meta?
            #console.log meta
            $("#infoPopup .title").html(makePrettyTitle(meta.title))
            makePrettyAuthors(meta.authors)
            publInfo = makePrettyJournal(meta.journal)
            if publInfo[0].length > 0
                $("#infoPopup .journal").show()
                journalStr = "#{publInfo[0]} (#{meta.year}) [#{meta.cocodes.toUpperCase()}]"
                if meta.mpg > 0
                    journalStr += " <b>Max Planck (#{meta.mpg})</b>"
                $("#infoPopup .journalName").html(journalStr)
                if publInfo[1].length == 0
                    $("#infoPopup .icoDoi").hide()
                else
                    $("#infoPopup .icoDoi").show().attr("href","http://dx.doi.org/" + publInfo[1])
            else
                $("#infoPopup .journal").hide()
            $("#infoPopup .arxiv").hide()
            $("#infoPopup .inspire").hide()
            $("#infoPopup .mypscp").hide()
            ###
            if meta.arxivId?
                $("#infoPopup .arxiv").show()
                html = meta.arxivId
                if meta.categories != ""
                    html += " [" + meta.categories + "]"
                $("#infoPopup .arxivId").html(html)
                $("#infoPopup .icoPDF").show().attr("href", "http://arxiv.org/pdf/" + meta.arxivId)
                $("#infoPopup .icoArxiv").show().attr("href", "http://arxiv.org/abs/" + meta.arxivId)
            else
                $("#infoPopup .arxiv").hide()
            mypscpURL = "http://my.paperscape.org/?s=#{meta.arxivId}"
            $("#infoPopup .icoMypscp").attr("href", mypscpURL)
            inspireURL = meta.inspireURL()
            if inspireURL?
                $("#infoPopup .inspire").show()
                $("#infoPopup .icoInspire").attr("href", inspireURL)
            else
                $("#infoPopup .inspire").hide()
            ###
            $("#infoPopup .showAbstract").show()
            $("#infoPopup .abstract").hide()
            $("#infoPopup").show()

            $("#infoPopup .showReferences").html("references (" + meta.numRefs + ")")
            $("#infoPopup .showCitations").html("citations (" + meta.numCites + ")")

    abstractPopup = (meta) ->
        if meta?.abstract?
            $("#infoPopup .abstract").html(meta.abstract).show()
            $("#infoPopup .showAbstract").hide()

    # used to parse latex in titles
    islower = (c) -> 'a' <= c and c <= 'z'

    makePrettyAuthors = (authors) ->
        # initially hide all author links
        for i in [1..13]
            $("#infoPopup .auth" + i).css('cursor','default').hide()

        if authors == undefined or authors == null or authors == "(unknown authors)"
            $("#infoPopup .auth1").html("(unknown authors)").show()
            return 

        authList = authors.split(',')
        if authList.length != 0
            # truncate author list at a maximum of MAX_AUTHORS authors
            extraAuth = 0
            if authList.length > MAX_AUTHORS
                extraAuth = authList.length - (MAX_AUTHORS - 2)
                authList = authList.slice(0, (MAX_AUTHORS - 2))

            for au, i in authList
                htmlAuth = ""
                # and add author name to the lists
                dot = au.lastIndexOf('.')
                if dot >= 0
                    # put a (non-breaking) space between initials and last name
                    auPre = au.slice(0, dot + 1)
                    auPost = au.slice(dot + 1)
                    authList[i] = auPre + " " + auPost
                    htmlAuth += auPre + "&nbsp;" + auPost
                else
                    #authorListLastname.push(au)
                    htmlAuth += au
                # add comma separator between authors
                htmlAuth += ", " if i < (authList.length - 1)
                $("#infoPopup .auth" + (i+1)).html(htmlAuth).css('cursor','pointer').show()

            # if extra authors, say so
            if extraAuth > 0
                htmlAuth = " and " + extraAuth + " more authors"
                $("#infoPopup .auth" + (authList.length+1)).html(htmlAuth).show()

    makePrettyTitle = (title) ->
        if title == undefined or title == null
            return "(unknown title)"

        # split the title into words, so we can draw it on multiple lines in the canvas
        title = title

        # WoS titles we have are all lower case
        # Capitalise first letter of first word
        if title.length > 1
            title = title.charAt(0).toUpperCase() + title.slice(1)
        else
            title = title.toUpperCase()

        #titleWords = title.split(' ')
        ## remove $'s from title words (we don't interpret them when rendering the title on the canvas)
        #for ti, i in titleWords
        #    titleWords[i] = titleWords[i].replace(/\$/g, "")

        # parse some latex math elements in the title for nicer printing
        mathMode = false
        parsedTitle = ""
        i = 0
        while i < title.length
            if title[i] == '{' or title[i] == '}'
                # ignore open/close braces
                i += 1
            else if title[i] == '$'
                if mathMode
                    parsedTitle += "</span>"
                    mathMode = false
                else
                    parsedTitle += "<span class=\"Lmm\">"
                    mathMode = true
                i += 1
            else if mathMode and i + 1 < title.length
                needArg = false
                if title[i] == '_'
                    parsedTitle += "<span class=\"Lsub\">"
                    needArg = true
                else if title[i] == '^'
                    parsedTitle += "<span class=\"Lsup\">"
                    needArg = true
                else if title[i] == '\\' and (title[i + 1] == '{' or title[i + 1] == '}')
                    parsedTitle += title[i + 1]
                    i += 1
                else if title[i] == '\\' and islower(title[i + 1])
                    i2 = i + 2
                    while i2 < title.length and islower(title[i2])
                        i2 += 1
                    if i2 >= title.length
                        # need at least one char for the argument... bit of a hack
                        i2 = title.length - 1
                    ctrl = title.slice(i + 1, i2)
                    needArg = true
                    if ctrl == "bar"
                        parsedTitle += "<span class=\"Lbar\">"
                        i = i2 - 1
                    else
                        # unknown control command, just add the slash and keep going
                        parsedTitle += title[i]
                        needArg = false
                    # skip space after control word
                    if needArg and i + 2 < title.length and title[i + 1] == ' '
                        i += 1
                else
                    parsedTitle += title[i]
                i += 1
                if needArg
                    if title[i] == '{'
                        j = i + 1
                        while j < title.length and title[j] != '}'
                            j++
                        if j < title.length
                            # found an argument in braces
                            parsedTitle += title.slice(i + 1, j)
                            i = j + 1
                        else
                            # unmatched open brace; just emit the open brace as the argument
                            parsedTitle += '{'
                            i += 1
                    else
                        # single character argument
                        parsedTitle += title[i]
                        i += 1
                    parsedTitle += "</span>"
            else if title[i] == '\\'
                parsedTitle += title.slice(i, i + 2)
                i += 2
            else
                parsedTitle += title[i]
                i += 1
        if mathMode
            parsedTitle += "</span>"
        title = parsedTitle

        return title

    makePrettyJournal = (publInfo) ->
        if publInfo == undefined or publInfo == null or publInfo.length == 0
            return ["", ""]

        journal = ""
        doi = ""

        publInfo = publInfo.split('#')
        if publInfo.length >= 2
            journal = publInfo[0]
            #journal = publInfo[0].split(',')
            #if journal.length > 1 and journal[0].length > 0 and journal[1].length > 1
            #    jname = journal[0][0]
            #    lastUpper = false
            #    for i in [1 ... journal[0].length]
            #        c = journal[0].charCodeAt(i)
            #        if 65 <= c and c <= 90
            #            # upper case
            #            jname += "."
            #            lastUpper = true
            #        else
            #            lastUpper = false
            #        jname += journal[0][i]
            #    if not lastUpper or jname[jname.length - 1] == 'J'
            #        jname += ".&nbsp;"
            #    else
            #        jname += " "
            #    if journal.length == 3
            #        # no jpage
            #        journal = jname + journal[2] + " (" + journal[1] + ")"
            #    else
            #        # has jpage
            #        journal = jname + journal[2] + " (" + journal[1] + ") " + journal[3]
            if publInfo[1].length > 0
                doi = publInfo[1]

        return [journal, doi]

    ###########################################################################
    # Public (exports)
    ###########################################################################

    exports.close = ->
        SELECTED.clearSelection()
        exports.update()

    exports.update = ->
        if SELECTED.isSelected()
            # hide the about popup as they share screen realestate
            $("#aboutPopup").hide()
            meta = getMeta(SELECTED.getSelectedId())
            meta.load()
        else 
            $("#infoPopup").hide()

    exports.showAbstract = ->
        if SELECTED.isSelected()
            meta = getMeta(SELECTED.getSelectedId())
            meta.loadAbstract()

    exports.showReferences = (callback) ->
        if SELECTED.isSelected()
            #arXivStr = findMetaById(SELECTED.getSelectedId())?.arxivId
            #if arXivStr?
            #    SEARCH.setSearch("?refs #{arXivStr}")
            #    SEARCH.doSearch(callback)
            SEARCH.setSearch("?refs #{SELECTED.getSelectedId()}")
            SEARCH.doSearch(callback)

    exports.showCitations = (callback) ->
        if SELECTED.isSelected()
            #arXivStr = findMetaById(SELECTED.getSelectedId())?.arxivId
            #if arXivStr?
            #    SEARCH.setSearch("?cites #{arXivStr}")
            #    SEARCH.doSearch(callback)
            SEARCH.setSearch("?cites #{SELECTED.getSelectedId()}")
            SEARCH.doSearch(callback)

    exports.searchAuthor = (index,callbackPass) ->
        if SELECTED.isSelected()
            meta = getMeta(SELECTED.getSelectedId())
            authList = meta.authors.split(',')
            if authList.length <= MAX_AUTHORS or (index <= (MAX_AUTHORS - 2))
                authStr = authList[index-1]
                if authStr?
                    SEARCH.setSearch("?author #{authStr}")
                    SEARCH.doSearch(callbackPass)


    return exports
