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

        lowerBound = $("#newpapersPopup .slider-range").slider("values",0)
        upperBound = $("#newpapersPopup .slider-range").slider("values",1)-1

        callbackPass = ->
            MAPVIEW.draw()
        SEARCH.setSearch("?mpg #{lowerBound}-#{upperBound}:#{categoriesString}")
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
        lowerBound = $("#newpapersPopup .slider-range").slider("values",0)
        upperBound = $("#newpapersPopup .slider-range").slider("values",1)-1
        val = "Papers with #{lowerBound}"
        #latestDate = WORLD.getLastDownloadDate()
        if upperBound == 9
            val += " or more MPG affiliations"
        else if upperBound == lowerBound
            val += " MPG affiliation"
        else 
            val += " to #{upperBound} MPG affiliations"
        $("#newpapersPopup .searchButton").val(val)

    return exports
