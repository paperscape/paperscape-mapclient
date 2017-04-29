# MAIN 
# 
# Handles non-canvas events, page refresh/resize etc.

define ['app/ajax','app/search','app/mapview','app/infoview','app/fadeview','app/detailview','app/newpapersview','app/input','lib/mousetrap','jquery','jquery.autocomplete','jquery.autocomplete.html'], (AJAX,SEARCH,MAPVIEW,INFOVIEW,FADEVIEW,DETAILVIEW,NEWPAPERSVIEW,INPUT,MOUSETRAP,$) ->

    # Version should match version stored in wombat
    # If not, hard reload of page is performed
    VERSION = "0.3"

    SEARCH_OFFSET_LEFT = 210
    SEARCH_BOX_WIDTH_MIN = 200
    SEARCH_BOX_WIDTH_MAX = 400
    #TOP_RIGHT_MENU_WIDTH = 120
    TOP_RIGHT_MENU_WIDTH = 200

    # for keeping track of day change
    currentPaperId = null
    
    # callback to call when MAPVIEW reloaded
    mapviewReloadCallback = ->
        DETAILVIEW.reload()
        if MAPVIEW.showOverlay()
            FADEVIEW.show()

    resizeDOM = ->
        newWidth = window.innerWidth
        newHeight = window.innerHeight

        # set xiwiArea dimensions
        xiwiArea = $("#xiwiArea")
        xiwiArea.width(newWidth)
        xiwiArea.height(newHeight)

        # set dimensions search and top right menu
        topRightMenuWidth = parseInt($("#topRightMenu").width()) + parseInt($("#topRightLogo").width())
        if topRightMenuWidth < TOP_RIGHT_MENU_WIDTH
            # when the page is first loaded, sometimes the font is not loaded before we compute this
            # so hack it to be the right size
            topRightMenuWidth = TOP_RIGHT_MENU_WIDTH
            #searchBoxWidth = Math.round(newWidth-70-parseInt(searchButton.width())-SEARCH_OFFSET_LEFT-topRightMenuWidth)
        searchBoxWidth = Math.round(newWidth-70-parseInt($("#searchButton").width()) - parseInt($("#searchNewPapers").width())-SEARCH_OFFSET_LEFT-TOP_RIGHT_MENU_WIDTH)
        if searchBoxWidth < SEARCH_BOX_WIDTH_MIN
            searchBoxWidth = SEARCH_BOX_WIDTH_MIN
        else if searchBoxWidth > SEARCH_BOX_WIDTH_MAX
            searchBoxWidth = SEARCH_BOX_WIDTH_MAX

        # set default dimensions for total header bar, based on logo image
        totalHeaderHeight = 67
        searchHeaderTop = 16
        # adjust defaults if necessary e.g. if an oversized input form:
        diff = $("#searchHeader").height() + 35 - totalHeaderHeight
        if diff > 0
            searchHeaderTop -= Math.round(diff/2)
            totalHeaderHeight += Math.round(diff/2)

        $("#searchBox").width(searchBoxWidth)
        $("#searchHeader").css("top", searchHeaderTop + "px")
        $("#searchHeader").css("left", SEARCH_OFFSET_LEFT + 'px')

        $("#topRightLogo").css("top", "13px")
        $("#topRightLogo").css("right", "10px")
        $("#topRightMenu").css("top", "13px")
        $("#topRightMenu").css("right", parseInt($("#topRightLogo").width()) + 20 + "px")

        newpapersPopup = $("#newpapersPopup")
        # TODO smart width/height
        newpapersPopupWidth = 600
        #newpapersPopupHeight = 400
        newpapersPopup.width(newpapersPopupWidth)
        #newpapersPopup.height(newpapersPopupHeight)
        newpapersPopup.css("top",Math.round((newHeight - newpapersPopup.height())/2) + 'px')
        newpapersPopup.css("left",Math.round((newWidth - newpapersPopup.width())/2) + 'px')
        $("#newpapersPopup .slider-range").width(500) # TODO

        # colour scheme select
        schemeSelect = $("#colourSchemeSelect")
        schemeSelect.css("top", totalHeaderHeight + 10 + 'px')

        # colour scheme select
        mapSelect = $("#mapSelect")
        mapSelect.css("top", totalHeaderHeight + 10 + 'px')
        moveRight = 0
        if schemeSelect.width()?
            moveRight += schemeSelect.width() + 20
        mapSelect.css("left", 10 + moveRight + 'px')

        # welcome message
        welcomePopup = $("#welcomePopup")
        #welcomePopup.css("top", totalHeaderHeight + 20 + parseInt(schemeSelect.height()) + 'px')
        welcomePopup.css("top", totalHeaderHeight + 10 + 'px')
        if mapSelect.width()?
            moveRight += mapSelect.width() + 20
        welcomePopup.css("left", 10 + moveRight + 'px')

        # colour code
        keyPopup = $("#keyPopup")
        keyPopup.css("left", 90 + 'px')
        $("#keyPopup .age").hide()
        $("#keyPopup .category").show()

        # zoom buttons
        zoomButtons = $("#canvasZoomButtons")
        zoomButtons.css("top", newHeight - 32 + 'px') 

        # detail view information
        detailView = $("#detailView")
        detailView.css("top", newHeight - 32 - 60 + 'px') 
        if detailView.height()?
            detailView.css("top", newHeight - 32 - detailView.height() - 20 + 'px') 


        # set canvas dimensions
        mapviewWidth = Math.round(newWidth)
        mapviewHeight = Math.round(newHeight-totalHeaderHeight-1); # -1 is for the 1px border
        
        MAPVIEW.resize(mapviewWidth,mapviewHeight,0,totalHeaderHeight)
        MAPVIEW.draw()

        #PANEL.resizePanel()
        #$("#infoPanel").hide()

        infoPopup = $("#infoPopup")
        infoPopupWidth = 400
        infoPopup.width(infoPopupWidth)
        infoPopup.css("top", totalHeaderHeight + 10 + "px")
        #infoPopup.css("left", Math.floor(0.5 * (canvasWidth - infoPopupWidth)) + "px")
        infoPopup.css("right", "10px")
        $("#infoPopup").css("max-height", newHeight - totalHeaderHeight - 20)

        aboutPopup = $("#aboutPopup")
        aboutPopupWidth = infoPopupWidth
        aboutPopup.width(aboutPopupWidth)
        aboutPopup.css("top", totalHeaderHeight + 10 + "px")
        aboutPopup.css("right", "10px")
        $("#aboutPopup").css("max-height", newHeight - totalHeaderHeight - 20)

    checkDateAndVersion = ->
        request = 
            gdmv: 1
        handleSuccess = (ajaxData) ->
            if ajaxData?.v? and ajaxData?.v != VERSION 
                # hard reload of page
                location.reload(true)
            if ajaxData?.d0?
                if currentPaperId? and currentPaperId != ajaxData.d0
                    MAPVIEW.reload(mapviewReloadCallback)
                    # for now do hard reload here too
                    # else some tiles will still be cached
                    # in future could consider stamping tiles with date
                    #location.reload(true)
                currentPaperId = ajaxData.d0
        AJAX.doRequest(request, handleSuccess) 

    checkForUrlVariables = ->
        vars = {}
        hash = null
        hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&')
        for i in [0...hashes.length]
            hash = hashes[i].split('=')
            vars[hash[0]] = decodeURIComponent((hash[1]+'').replace(/\+/g, '%20'))
        if vars.s? and vars.s.length < 64
            SEARCH.setSearch(vars.s)
            callbackPass = ->
                MAPVIEW.draw()
            SEARCH.doSearch(callbackPass)

    main = ->
        # bind first, so that init can safely set it after callback
        MAPVIEW.bindZoomFunction ->
            # TODO check if detailView showing
            DETAILVIEW.reload()
            if MAPVIEW.showOverlay()
                FADEVIEW.show()
            else
                FADEVIEW.hide()

        if $("#detailView").css('display') is "none" 
            DETAILVIEW.hide()
        else 
            DETAILVIEW.show()

        MAPVIEW.initialise()
        MAPVIEW.reload(mapviewReloadCallback)

        # work out if we are running on a portable device
        agent = navigator.userAgent.toLowerCase()
        INPUT.iDevice = agent.indexOf("iphone") >= 0 or agent.indexOf("ipad") >= 0 or agent.indexOf("android") >= 0

        # resize and orientation change events
        window.addEventListener('resize', resizeDOM, false)
        window.addEventListener('orientationchange', resizeDOM, false) # for smart phones etc.

        # bind events for the mouse/touch
        if INPUT.iDevice
            # an iDevice; bind the events for touch
            MAPVIEW.getTopCanvas().addEventListener("touchstart", INPUT.touchStart)
            MAPVIEW.getTopCanvas().addEventListener("touchend", INPUT.touchEnd)
            # since touchmove event only fires when the user is actually touching, we can afford to always have it bound
            MAPVIEW.getTopCanvas().addEventListener("touchmove", INPUT.touchMove)
        else
        # we have a real mouse; use jQuery to bind these events
            MAPVIEW.jQueryAttach().mousedown(INPUT.mouseDown)
            MAPVIEW.jQueryAttach().mouseup(INPUT.mouseUp)
            MAPVIEW.jQueryAttach().mouseleave(INPUT.mouseLeave)
            MAPVIEW.jQueryAttach().dblclick(INPUT.mouseDoubleClick)
            MAPVIEW.jQueryAttach().mousewheel(INPUT.mouseWheel)

        # mousetrap library, used to capture keys
        # see: http://craig.is/killing/mice
        if !INPUT.iDevice
            #MOUSETRAP.bind("esc", (e, key) -> INPUT.keypressEscape())
            #MOUSETRAP.bind("enter", (e, key) -> INPUT.keypressEnter())
            MOUSETRAP.bind(["left", "right", "up", "down"], (e, key) -> INPUT.keypressArrow(key))
            MOUSETRAP.bind(["=", "+", "-"], (e, key) -> INPUT.keypressZoom(key))
            MOUSETRAP.bind(["d"], (e, key) -> DETAILVIEW.toggle())

        $("#formSearch").submit(INPUT.formSearchSubmit)
        $("#formSearch input:button").submit(INPUT.formSearchSubmit)
        $("#searchMessage .clear").click ->
            SEARCH.clearSearchResults()
            MAPVIEW.draw()

        # search box autocomplete
        searchTerms = [
            {label: "<b>?<u>s</u>mart</b> <small><small>(examples:  <i>r.doll, nanotubes</i>)</small></small>", value: "?smart "}
            {label: "<b>?<u>a</u>uthor</b> <small><small>(example: <i>?a davenas; ?a r.doll</i>)</small></small>", value: "?author "}
            {label: "<b>?<u>k</u>eyword</b> <small><small>(example: <i>?k nanotubes</i>)</small></small>", value: "?keyword "}
            {label: "<b>?<u>ti</u>tle</b> <small><small>(example: <i>?ti gold electrodes</i>)</small></small>", value: "?title "}
            {label: "<b>?<u>g</u>roupmpg</b> <small><small>(example: <i>?g e.donath</i>)</small></small>", value: "?mpg "}
            #{label: "<b>?<u>m</u>pg</b> <small><small>(example: <i>?mpg 1-9:ei</i>)</small></small>", value: "?mpg "}
        ]

        $("#searchBox").autocomplete(
            source: ( request, response ) ->
                matcher = new RegExp( "^" + $.ui.autocomplete.escapeRegex( request.term ), "i" )
                response( $.grep( searchTerms, ( item ) ->
                    return matcher.test( item.value )
                )
                )
            html: true
            delay : 0
            autoFocus : true
            minLength: 0
        ).focus ->
            $("#searchBox").autocomplete("search",$("#searchBox").value)

        $("#searchMessage").hide()
        
        # New papers view -> Max Planck view
        $("#searchNewPapers").click ->
            NEWPAPERSVIEW.popup()
        NEWPAPERSVIEW.close()
        $("#newpapersPopup .close").click -> 
            NEWPAPERSVIEW.close()
        $("#newpapersPopup .form").submit(NEWPAPERSVIEW.doSearch)

        $("#newpapersPopup .slider-range").slider(
            range: true
            min: 1
            max: 10
            step: 1
            values: [ 2, 10 ]
            slide: (event, ui) ->
                #if ui.values[0] == ui.values[1] or ui.values[0] == ui.values[1]-1
                if ui.values[0] == ui.values[1]
                    event.preventDefault()
                else 
                    $("#newpapersPopup .slider-range").slider("values",0,ui.values[0])    
                    $("#newpapersPopup .slider-range").slider("values",1,ui.values[1])    
                NEWPAPERSVIEW.update()
            change: (event, ui) ->
                NEWPAPERSVIEW.update()
        )
        NEWPAPERSVIEW.update()

        # show everything
        $("#xiwiArea").show()

        # refresh world - should be done automatically now
        #$("#welcomePopup .refresh").click ->
        #    MAPVIEW.reload()

        # keypopup
        $("#keyPopup .close").click ->
            $("#keyPopup").hide()
        $("#colourSchemeSelect .legend").click ->
            $("#keyPopup").toggle()
        $("#keyPopup").hide()

        # colour scheme select
        $("#colourSchemeSelect .select").val('categories').bind('change', (event) ->
            INPUT.canvasColourSchemeSelect(event)
        )

        # map select
        $("#mapSelect .select").bind('change', (event) ->
            FADEVIEW.hide()
            INFOVIEW.close()
            MAPVIEW.reload(mapviewReloadCallback)
        )

        # info popup
        $("#infoPopup .close").click -> 
            INFOVIEW.close()
            MAPVIEW.draw()
        $("#infoPopup .showAbstract").click ->
            INFOVIEW.showAbstract()
        $("#infoPopup .showReferences").click ->
            INFOVIEW.showReferences(MAPVIEW.draw)
        $("#infoPopup .showCitations").click ->
            INFOVIEW.showCitations(MAPVIEW.draw)
        for index in [1..13]
            $("#infoPopup .auth" + index).click -> 
                callbackPass = ->
                    MAPVIEW.draw()
                INFOVIEW.searchAuthor($(this).data("id"),callbackPass)
        INFOVIEW.close()
        
        # about popup
        $("#topRightMenu .info").click ->
            INFOVIEW.close()
            $("#aboutPopup").toggle()
            MAPVIEW.draw()
        $("#aboutPopup .close").click -> 
            $("#aboutPopup").hide()
        $("#aboutPopup").hide()

        # zoom buttons
        $("#canvasZoomIn").click ->
            INPUT.canvasZoomInButton()

        $("#canvasZoomOut").click ->
            INPUT.canvasZoomOutButton()

        # now that the correct items are shown, resize everything to fit correctly
        resizeDOM()

        MAPVIEW.draw()
        
        checkDateAndVersion()
        
        checkForUrlVariables()

        # Check for version and date when window gets focus
        $(window).focus ->
            checkDateAndVersion()

    # request animation frame
    window.requestAnimationFrame = do ->
        workaround = (callback) ->
            window.setTimeout(callback, 1000 / 60 )
        window.requestAnimationFrame or window.mozRequestAnimationFrame or window.webkitRequestAnimationFrame or window.msRequestAnimationFrame or workaround
                

    # use jQuery to run the app
    $(document).ready(-> main())

    return {} 

