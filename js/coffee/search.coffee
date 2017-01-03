# SEARCH module
#
# Handles user search requests.

define ['app/world','jquery'], (WORLD,$) ->
    exports = {}

    SEARCH_TYPE_UNKNOWN     = 0
    SEARCH_TYPE_AUTO        = 1
    SEARCH_TYPE_ARXIV       = 2
    SEARCH_TYPE_NEW         = 3
    SEARCH_TYPE_AUTHOR      = 4
    SEARCH_TYPE_TITLE       = 5
    SEARCH_TYPE_KEYWORD     = 6
    SEARCH_TYPE_REFS        = 7
    SEARCH_TYPE_CITES       = 8

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
            else if command == "keyword".slice(0,endIndex-1)
                return [SEARCH_TYPE_KEYWORD, searchTerm]
            else if command == "new-papers".slice(0,endIndex-1)
                return [SEARCH_TYPE_NEW, searchTerm]
            else if command == "refs".slice(0,endIndex-1)
                return [SEARCH_TYPE_REFS, searchTerm]
            else if command == "cites".slice(0,endIndex-1)
                return [SEARCH_TYPE_CITES, searchTerm]
            else
                return [SEARCH_TYPE_UNKNOWN, searchTerm]
        
        if regexArxivNew.test(input) or regexArxivOld.test(input)
            return [SEARCH_TYPE_ARXIV, input]
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
            when SEARCH_TYPE_NEW
                #if (newPaperBoundaryId = WORLD.getNewPaperBoundaryId()) != 0
                crosslists = "false"
                daysAgoFrom = 1 
                daysAgoTo = 0 

                parts = searchValue.replace(/^\s*|\s*$/g,'').split(':')
                if parts.length >= 2
                    days = parts[0].split('-')
                    cats = parts[1].split(',')
                else
                    cats = parts[0].split(',')
                
                if days? 
                    if days[0]? and days[0] > 0
                        daysAgoFrom = days[0]
                    if days[1]? and days[1] > 0
                        daysAgoTo = days[1]

                newCats = []
                for cat in cats
                    # remove white space
                    cat = cat.replace(/\s/g,'')
                    if cat == "crosslists"
                        crosslists = "true"
                    else 
                        newCats.push(cat)
                request = 
                    sca: newCats.join(",")
                    #f:newPaperBoundaryId
                    #t:0
                    fd : daysAgoFrom
                    td : daysAgoTo 
                    x:crosslists
                WORLD.fetchSearchResults(request, success, error) 
            when SEARCH_TYPE_REFS
                WORLD.fetchReferencesForArXivId(searchValue,successLink,error)
            when SEARCH_TYPE_CITES
                WORLD.fetchCitationsForArXivId(searchValue,successLink,error)
            else
                $("#searchMessage .results").html("Invalid search type")
                $("#searchMessage .clear").show()
                $("#searchMessage").show()
                searchResults = []
                callbackPass()

    return exports
