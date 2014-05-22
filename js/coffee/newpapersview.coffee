# NEWPAPERSVIEW module
#
# Popup that lets users search for new papers.

define ['app/world','app/mapview','app/search','jquery','jquery.mousewheel'], (WORLD,MAPVIEW,SEARCH,$) ->

    exports = {}

    performSearch = -> 
        checkboxes = $("#newpapersPopup .catCheckbox")

        numCategories = 0
        categoriesString = ""
        for checkbox in checkboxes
            if checkbox.children[0].checked
                if categoriesString.length > 0
                    categoriesString += ","
                categoriesString += checkbox.children[0].value
                if checkbox.children[0].value != "crosslists"
                    numCategories += 1

                #if checkbox.textContent == "Include crosslists"
                #    categoriesString += "crosslists"
                #else
                #    categoriesString += checkbox.textContent

        if numCategories == 0
            # don't search
            return

        lowerBound = 31 - $("#newpapersPopup .slider-range").slider("values",0)
        upperBound = 32 - $("#newpapersPopup .slider-range").slider("values",1)

        callbackPass = ->
            MAPVIEW.draw()
        SEARCH.setSearch("?n #{lowerBound}-#{upperBound}:#{categoriesString}")
        SEARCH.doSearch(callbackPass)
        exports.close()

    ###########################################################################
    # Public (exports)
    ###########################################################################

    exports.doSearch = (event) ->
        event.preventDefault()
        performSearch()

    exports.close = ->
        $("#newpapersPopup").hide()

    exports.popup = ->
        $("#newpapersPopup").show()
        exports.update()

    exports.update = ->
        lowerBound = 31 - $("#newpapersPopup .slider-range").slider("values",0)
        upperBound = 32 - $("#newpapersPopup .slider-range").slider("values",1)
        val = "New papers"
        latestDate = WORLD.getLastDownloadDate()
        if upperBound == 0
            if lowerBound == 1
                val += " for last submission day (#{latestDate})"
            else 
                val += " for last #{lowerBound} submission days"
        else 
            val += " from #{upperBound} to #{lowerBound} submission days ago"
        $("#newpapersPopup .searchButton").val(val)

    return exports
