# SEARCH module
#
# Handles user search requests.

define ['app/world','jquery'], (WORLD,$) ->
    exports = {}

    SEARCH_TYPE_UNKNOWN     = 0
    SEARCH_TYPE_AUTO        = 1
    SEARCH_TYPE_ARXIV       = 2
    SEARCH_TYPE_MPG         = 3
    SEARCH_TYPE_AUTHOR      = 4
    SEARCH_TYPE_GROUPMPG    = 5
    SEARCH_TYPE_TITLE       = 6
    SEARCH_TYPE_KEYWORD     = 7
    SEARCH_TYPE_REFS        = 8
    SEARCH_TYPE_CITES       = 9

    # Returns the type of search, and the rest of the input
    regexArxivOld = /^\s*[A-Za-z\-]{2,8}\/\d{7}\s*$/
    regexArxivNew = /^\s*\d{4}\.\d{4,5}\s*$/ # 2015 update
    regexCategory = /^\s*[A-Za-z\-]{2,8}\s*$/
    regexAuthor   = /^\s*[A-Za-z][a-z]?\.-?[A-Za-z]/

    searchResults = []

    # flag for link parent node and its unique SearchResult
    searchParentResult = null

    zoomOnSearch = false

    class SearchResult
        constructor: (id,x,y,r) ->
            @id = id
            @x  = x
            @y  = y
            @r  = r
            @freq = 1  # used by link search results

    detectSearchType = (input) ->
        # TODO this needs some work
        # A search term should end with ' ', ':', '='
        # and anything up to that should qualify
        # e.g "?a ", "?auth ", "?author:" etc.
        if input.length >= 1 and input[0] == '?'
            # find end of command
            endIndex = input.indexOf(" ",1)
            searchTerm = ""
            if endIndex == -1
                endIndex = input.length
            else
                searchTerm = input.slice(endIndex)
            command = input.slice(1,endIndex)
            
            if command == ""
                return [SEARCH_TYPE_UNKNOWN, ""]
            else if command == "smart".slice(0,endIndex-1)
                # proceed below
                input = searchTerm
            else if command == "author".slice(0,endIndex-1)
                return [SEARCH_TYPE_AUTHOR, searchTerm]
            else if command.length >= 2 and command == "title".slice(0,endIndex-1)
                return [SEARCH_TYPE_TITLE, searchTerm]
            else if command == "mpg".slice(0,endIndex-1)
                return [SEARCH_TYPE_MPG, searchTerm]
            else if command == "groupmpg".slice(0,endIndex-1)
                return [SEARCH_TYPE_GROUPMPG, searchTerm]
            else if command == "keyword".slice(0,endIndex-1)
                return [SEARCH_TYPE_KEYWORD, searchTerm]
            else if command == "refs".slice(0,endIndex-1)
                return [SEARCH_TYPE_REFS, searchTerm]
            else if command == "cites".slice(0,endIndex-1)
                return [SEARCH_TYPE_CITES, searchTerm]
            else
                return [SEARCH_TYPE_UNKNOWN, searchTerm]
        
        #if regexArxivNew.test(input) or regexArxivOld.test(input)
        #    return [SEARCH_TYPE_ARXIV, input]
        else if regexAuthor.test(input)
            return [SEARCH_TYPE_AUTHOR, input]
        else
            return [SEARCH_TYPE_AUTO, input]

    printInfoMessageCheckZoom = ->
        if searchResults.length > 0
            # Search success, so zoom in on it when we have the chance
            $("#searchMessage .results").html("Showing #{searchResults.length} results.")
            $("#searchMessage .clear").show()
            $("#searchMessage").show()
            zoomOnSearch = true
        else 
            $("#searchMessage .results").html("Found no results.")
            $("#searchMessage .clear").hide()
            $("#searchMessage").show()
            zoomOnSearch = false


    handleSearchWrapper = (callbackPass) ->
        return (ajaxData) ->
            if ajaxData?
                ids = []
                for paper in ajaxData
                    ids.push(paper.id)
                firstCallbackPass = (data) ->
                    searchParentResult = null
                    searchResults = []
                    if data?
                        for paper in data
                            searchResults.push(new SearchResult(paper.id,paper.x,paper.y,paper.r))
                    printInfoMessageCheckZoom()
                    if callbackPass?
                        callbackPass()
                WORLD.fetchLocationsForPaperIds(ids,firstCallbackPass)
   
    handleLinkSearchWrapper = (callbackPass) ->
        return (ajaxData) ->
            if ajaxData?
                searchParentResult = new SearchResult(ajaxData.id,ajaxData.x,ajaxData.y,ajaxData.r)
                searchResults = []
                # only include links with valid positions
                for link in ajaxData.links when link.x? and link.y? and link.r?
                    sRes = new SearchResult(link.id,link.x,link.y,link.r)
                    sRes.freq = link.freq
                    searchResults.push(sRes)
                printInfoMessageCheckZoom()
                if callbackPass?
                    callbackPass()

    handleSearchError = ->
        $("#searchMessage .results").html("Search failed.")
        $("#searchMessage .clear").show()
        $("#searchMessage").show()

    ###########################################################################
    # Public (exports)
    ###########################################################################

    exports.getSearchResults = ->
        return searchResults

    exports.getParentLinkResult = ->
        return searchParentResult

    exports.clearSearchResults = ->
        searchResults = []
        searchParentResult = null
        $("#searchMessage").hide()
        $("#formSearch input:text")[0].value = ""
        
    exports.areSearchResults = ->
        return searchResults.length != 0

    exports.isParentLinkResult = ->
        return searchParentResult != null

    exports.zoomOnceOnSearch = ->
        if zoomOnSearch 
            zoomOnSearch = false
            return true
        else
            return false

    exports.closestResultWithinRadius = (pos,radius) ->
        searchData = null
        shortestDist2 = -1
        radius2 = radius*radius
        for res in searchResults
            dist2 = Math.pow(pos.x - res.x,2) + Math.pow(pos.y - res.y,2)
            if dist2 < radius2 and (shortestDist2 < 0 or dist2 < shortestDist2)
                shortestDist2 = dist2
                searchData = 
                    id: res.id
                    x: res.x
                    y: res.y
                    r: res.r
        return searchData

    exports.setSearch = (searchString) ->
        $("#formSearch input:text")[0].value = searchString

    exports.doSearch = (callbackPass) ->
        # TODO should lock search while searching!
        # detect search type
        keyword = $("#formSearch input:text")[0].value
        searchTypeAndValue = detectSearchType(keyword)

        # remove white space from head and tail of search value
        searchValue = searchTypeAndValue[1].replace(/^\s*|\s*$/g,'')

        $("#searchMessage .results").html("Searching...")
        $("#searchMessage .clear").hide()
        $("#searchMessage").show()

        success = handleSearchWrapper(callbackPass)
        successLink = handleLinkSearchWrapper(callbackPass)
        error   = handleSearchError
        switch searchTypeAndValue[0]
            when SEARCH_TYPE_AUTO
                WORLD.fetchSearchResults({sge: searchValue}, success, error) 
            when SEARCH_TYPE_KEYWORD
                WORLD.fetchSearchResults({skw: searchValue}, success, error) 
            when SEARCH_TYPE_ARXIV
                WORLD.fetchSearchResults({saxm: searchValue}, success, error) 
            when SEARCH_TYPE_AUTHOR
                WORLD.fetchSearchResults({sau: searchValue}, success, error) 
            when SEARCH_TYPE_TITLE
                WORLD.fetchSearchResults({sti: searchValue}, success, error) 
            when SEARCH_TYPE_MPG
                crosslists = "false"
                min = 1
                max = 100
                
                parts = searchValue.replace(/^\s*|\s*$/g,'').split(':')
                if parts.length >= 2
                    affil = parts[0].split('-')
                    cats  = parts[1].split(',')
                else
                    cats = parts[0].split(',')
                
                if affil? 
                    if affil[0]? and affil[0] > 0
                        min = affil[0]
                    if affil[1]? and affil[1] > 0
                        max = affil[1]

                mpgCats = []
                for cat in cats
                    # remove white space
                    #cat = cat.replace(/^\s*|\s*$/g,'')
                    if cat == "crosslists"
                        crosslists = "true"
                    else 
                        mpgCats.push(cat)
                request = 
                    scax: mpgCats.join(",")
                    ind: 2
                    min: min
                    max: max
                    x:crosslists
                WORLD.fetchSearchResults(request, success, error) 
            when SEARCH_TYPE_GROUPMPG
                min = 1
                max = 100
                
                parts = searchValue.replace(/^\s*|\s*$/g,'').split(':')
                if parts.length >= 2
                    affil = parts[0].split('-')
                    author = parts[1]
                else
                    author = parts[0]
                
                if affil? 
                    if affil[0]? and affil[0] > 0
                        min = affil[0]
                    if affil[1]? and affil[1] > 0
                        max = affil[1]
                request = 
                    saux: author
                    ind: 2
                    min: min
                    max: max
                WORLD.fetchSearchResults(request, success, error) 
            when SEARCH_TYPE_REFS
                WORLD.fetchReferencesForId(searchValue,successLink,error)
            when SEARCH_TYPE_CITES
                WORLD.fetchCitationsForId(searchValue,successLink,error)
            else
                $("#searchMessage .results").html("Invalid search type")
                $("#searchMessage .clear").show()
                $("#searchMessage").show()
                searchResults = []
                callbackPass()

    return exports
