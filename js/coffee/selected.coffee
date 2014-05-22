# SELECTED module
#
# Stores state of selected paper.

define ['app/Vec2D','app/world'], (Vec2D,WORLD) ->

    exports = {}

    selectedId = null
    selectedPos = null
    selectedRad = null

    #referenceLinks = []
    #referencesLoading = false # a lock to prevent multiple requests
    #referencesReady  = false

    #citationLinks = []
    #citationsLoading = false # a lock to prevent multiple requests
    #citationsReady  = false

    #showReferences = false
    #showCitations  = false

    class Link
        constructor: (id,freq,order,numCites) ->
            @id    = id
            @freq  = freq
            @order = order
            @nc    = numCites
            @pos   = null
            @rad   = null

    ###########################################################################
    # Public (exports)
    ###########################################################################

    exports.getSelectedId = ->
        return selectedId

    exports.getSelectedPos = ->
        return selectedPos

    exports.getSelectedRad = ->
        return selectedRad

    exports.setSelection = (data) ->
        if data.id? and data.id > 0 and data.id != selectedId
            exports.clearSelection()
            selectedId = data.id
            if data.x? and data.y? and data.r?
                selectedPos = new Vec2D(data.x,data.y)
                selectedRad = data.r

    exports.clearSelection = () ->
        selectedId = null
        selectedPos = null
        selectedRad = null
        #showReferences = false
        #showCitations  = false
        #referencesLoading = false
        #referencesReady   = false
        #citationsLoading = false
        #citationsReady   = false

    exports.isSelected = ->
        return selectedId?
    
    ###
    exports.loadReferences = (callback) ->
        if selectedId? 
            showReferences    = true
            showCitations     = false
            if !referencesLoading and !referencesReady
                referencesLoading = true
                referencesReady  = false
                referenceLinks    = []

                callbackFail = () ->
                    referencesLoading = false
                    referenceLinks = []

                # this callback is called after the next one
                # TODO make single call in Wombat for all this info!
                callbackFetchLocations = (data) ->
                    for location in data
                        for link in referenceLinks when link.id == location.id
                            link.pos = new Vec2D(location.x,location.y)
                            link.rad = location.r
                    
                    referencesLoading = false
                    referencesReady  = true
                    callback()

                callbackFetchRefs = (data) ->
                    refIds = []
                    for ref in data.references
                        refIds.push(ref.id)
                        referenceLinks.push(new Link(ref.id,ref.freq,ref.order,ref.numCites))
                    WORLD.fetchLocationsForPaperIds(refIds,callbackFetchLocations,callbackFail)
                WORLD.fetchReferencesForPaperId(selectedId,callbackFetchRefs,callbackFail)
            else
                callback()
    ###
    
    
    ###
    exports.loadCitations = (callback) ->
        if selectedId? 
            showReferences    = false
            showCitations     = true
            if !citationsLoading and !citationsReady
                citationsLoading = true
                citationsReady  = false
                citationLinks    = []

                callbackFail = () ->
                    citationsLoading = false
                    citationLinks = []

                callbackFetchLocations = (data) ->
                    for location in data
                        for link in citationLinks when link.id == location.id
                            link.pos = new Vec2D(location.x,location.y)
                            link.rad = location.r
                    
                    citationsLoading = false
                    citationsReady  = true
                    callback()

                callbackFetchRefs = (data) ->
                    citeIds = []
                    for cite in data.citations
                        citeIds.push(cite.id)
                        citationLinks.push(new Link(cite.id,cite.freq,0,cite.numCites))
                    WORLD.fetchLocationsForPaperIds(citeIds,callbackFetchLocations,callbackFail)
                WORLD.fetchCitationsForPaperId(selectedId,callbackFetchRefs,callbackFail)
            else
                callback()
    ###
    
    ###
    exports.drawLinks = ->
        return showReferences or showCitations
    ###
    
    ###
    exports.getLinks = ->
        if showReferences and referencesReady
            return referenceLinks
        else if showCitations and citationsReady
            return citationLinks
        else
            return []
    ###

    return exports
