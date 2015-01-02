# INFOVIEW module
#
# Popup that displays information about a selected paper.

define ['app/selected','app/world','app/search','jquery','jquery.mousewheel'], (SELECTED,WORLD,SEARCH,$) ->

    exports = {}

    metas = []

    class Meta
        constructor: (id) ->
            @id =         id
            @numCites =   0
            @title =      "Loading..."
            @authors =    "Loading..."
            @journal =    ""
            @arxivId =    ""
            @categories = ""
            @inspire =    ""
            @abstract =   null
            @loaded = false

        load: =>
            if @loaded 
                infoPopup(this)
            else 
                callback = (data) =>
                    @id =         data.id
                    @numCites =   data.numCites
                    @title =      data.title
                    @authors =    data.authors
                    @journal =    data.journal
                    @arxivId =    data.arxivId
                    @categories = data.categories
                    @inspire =    data.inspire
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

        inspireURL: =>
            if @inspire != ""
                return "http://inspirehep.net/record/" + @inspire
            else if @arxivId != ""
                if @arxivId[4] == "."
                    return "http://inspirehep.net/search?p=find+eprint+arxiv%3A" + @arxivId
                else
                    return "http://inspirehep.net/search?p=find+eprint+" + @arxivId
            else
                return null

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
            $("#infoPopup .authors").html(makePrettyAuthors(meta.authors))
            publInfo = makePrettyJournal(meta.journal)
            if publInfo[0].length > 0
                $("#infoPopup .journal").show()
                $("#infoPopup .journalName").html(publInfo[0])
                if publInfo[1].length == 0
                    $("#infoPopup .icoDoi").hide()
                else
                    $("#infoPopup .icoDoi").show().attr("href","http://dx.doi.org/" + publInfo[1])
            else
                $("#infoPopup .journal").hide()
            if meta.arxivId?
                $("#infoPopup .arxiv").show()
                html = meta.arxivId
                if meta.categories != ""
                    html += " [" + meta.categories + "]"
                $("#infoPopup .arxivId").html(html)
                $("#infoPopup .icoPDF").show().attr("href", "http://arxiv.org/pdf/" + meta.arxivId)
                $("#infoPopup .icoArxiv").show().attr("href", "http://arxiv.org/abs/" + meta.arxivId)
            else
                $("#infoPopup .arxiv").show()
            mypscpURL = "http://my.paperscape.org/?s=#{meta.arxivId}"
            $("#infoPopup .icoMypscp").attr("href", mypscpURL)

            inspireURL = meta.inspireURL()
            if inspireURL?
                $("#infoPopup .inspire").show()
                $("#infoPopup .icoInspire").attr("href", inspireURL)
            else
                $("#infoPopup .inspire").hide()
            $("#infoPopup .showAbstract").show()
            $("#infoPopup .abstract").hide()
            $("#infoPopup").show()

    abstractPopup = (meta) ->
        if meta?.abstract?
            $("#infoPopup .abstract").html(meta.abstract).show()
            $("#infoPopup .showAbstract").hide()

    # used to parse latex in titles
    islower = (c) -> 'a' <= c and c <= 'z'

    makePrettyAuthors = (authors) ->
        if authors == undefined or authors == null or authors == "(unknown authors)"
            return "(unknown authors)"

        authorListLastname = [authors]
        authorListInitialsLastname = [authors]
        htmlAuth = authors
        shortAuth = authors

        authList = authors.split(',')
        if authList.length != 0
            # truncate author list at a maximum of 12 authors
            # TODO option to show full author list in zoombox
            extraAuth = 0
            if authList.length > 12
                extraAuth = authList.length - 10
                authList = authList.slice(0, 10)

            # create:
            #    authList: a list of initials + last name (to become authorListInitialsLastname)
            #    authorListLastname: a list of authors last names
            #    htmlAuth: author string for HTML display with clickable names

            htmlAuth = ""
            authorListLastname = []
            for au, i in authList
                # add comma separator between authors
                htmlAuth += ", " if i > 0
                # make click link
                # TODO this onclick circular, need to rethink it
                #htmlAuth += "<span class=\"author\" onclick=\"INPUT.doExampleSearch('?author " + au + "')\" title=\"Search author\">"
                htmlAuth += "<span>"
                # and add author name to the lists
                dot = au.lastIndexOf('.')
                if dot >= 0
                    # put a (non-breaking) space between initials and last name
                    auPre = au.slice(0, dot + 1)
                    auPost = au.slice(dot + 1)
                    authList[i] = auPre + " " + auPost
                    authorListLastname.push(auPost)
                    htmlAuth += auPre + "&nbsp;" + auPost + "</span>"
                else
                    authorListLastname.push(au)
                    htmlAuth += au + "</span>"

            authorListInitialsLastname = authList

            # if extra authors, say so
            if extraAuth > 0
                authorListLastname.push("and " + extraAuth + " more authors")
                authorListInitialsLastname.push("and " + extraAuth + " more authors")
                htmlAuth += " and " + extraAuth + " more authors"

            # create shortAuth: short author list, with maximum of 2 authors, no initials
            if authorListLastname.length == 1
                shortAuth = authorListLastname[0]
            else if authorListLastname.length == 2
                shortAuth = authorListLastname[0] + ", " + authorListLastname[1]
            else
                shortAuth = authorListLastname[0] + " et al."

        return htmlAuth

    makePrettyTitle = (title) ->
        if title == undefined or title == null
            return "(unknown title)"

        # split the title into words, so we can draw it on multiple lines in the canvas
        title = title
        titleWords = title.split(' ')

        # remove $'s from title words (we don't interpret them when rendering the title on the canvas)
        for ti, i in titleWords
            titleWords[i] = titleWords[i].replace(/\$/g, "")

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
            journal = publInfo[0].split(',')
            if journal[0].length > 0 and journal[1].length > 1
                jname = journal[0][0]
                lastUpper = false
                for i in [1 ... journal[0].length]
                    c = journal[0].charCodeAt(i)
                    if 65 <= c and c <= 90
                        # upper case
                        jname += "."
                        lastUpper = true
                    else
                        lastUpper = false
                    jname += journal[0][i]
                if not lastUpper or jname[jname.length - 1] == 'J'
                    jname += ".&nbsp;"
                else
                    jname += " "
                if journal.length == 3
                    # no jpage
                    journal = jname + journal[2] + " (" + journal[1] + ")"
                else
                    # has jpage
                    journal = jname + journal[2] + " (" + journal[1] + ") " + journal[3]
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
            arXivStr = findMetaById(SELECTED.getSelectedId())?.arxivId
            if arXivStr?
                SEARCH.setSearch("?refs #{arXivStr}")
                SEARCH.doSearch(callback)

    exports.showCitations = (callback) ->
        if SELECTED.isSelected()
            arXivStr = findMetaById(SELECTED.getSelectedId())?.arxivId
            if arXivStr?
                SEARCH.setSearch("?cites #{arXivStr}")
                SEARCH.doSearch(callback)

    return exports
