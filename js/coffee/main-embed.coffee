# MAIN 
# 
# Module concept:
# Handles non-canvas events, page refresh/resize etc.

define ['app/ajax','app/mapview','app/infoview','app/input','lib/mousetrap','jquery','jquery.autocomplete','jquery.autocomplete.html'], (AJAX,MAPVIEW,INFOVIEW,INPUT,MOUSETRAP,$) ->

    # Version should match version stored in wombat
    # If not, hard reload of page is performed
    
    # NOTE this is dangerous is javascript not loaded from our server!!
    VERSION = "0.1"

    # for keeping track of day change
    currentPaperId = null

    resizeDOM = ->
        #newWidth = window.innerWidth
        #newHeight = window.innerHeight
    
        # Let xiwiArea be set manually
        # set xiwiArea dimensions
        xiwiArea = $("#xiwiArea")
        newWidth = xiwiArea.width()
        newHeight = xiwiArea.height()
        #xiwiArea.width(newWidth)
        #xiwiArea.height(newHeight)

        # welcome message
        #welcomePopup = $("#welcomePopup")
        #welcomePopup.css("top", 5 + 'px')

        # colour code
        #keyPopup = $("#keyPopup")
        #keyPopup.css("left", 30 + 'px')

        # colour scheme select
        schemeSelect = $("#colourSchemeSelect")
        schemeSelect.css("top", 10 + 'px')

        # zoom buttons
        zoomButtons = $("#canvasZoomButtons")
        zoomButtons.css("top", newHeight - 32 + 'px') 

        # set canvas dimensions
        mapviewWidth = Math.round(newWidth)
        mapviewHeight = Math.round(newHeight)
        
        MAPVIEW.resize(mapviewWidth,mapviewHeight,0,0)
        MAPVIEW.draw()

        infoPopup = $("#infoPopup")
        infoPopupWidth = 400
        infoPopup.width(Math.min(infoPopupWidth,mapviewWidth-20))
        infoPopup.css("top", 10 + "px")
        #infoPopup.css("left", Math.floor(0.5 * (canvasWidth - infoPopupWidth)) + "px")
        infoPopup.css("right", "10px")
        $("#infoPopup").css("max-height", newHeight - 20)


    checkDateAndVersion = ->
        request = 
            gdmv: 1
        handleSuccess = (ajaxData) ->
            # TODO may no be loaded from our server, so do not do hard reset...
            #if ajaxData?.v? and ajaxData?.v != VERSION 
            #    # hard reload of page
            #    location.reload(true)
            if ajaxData?.d0?
                if currentPaperId? and currentPaperId != ajaxData.d0
                    MAPVIEW.reload()
                    # for now do hard reload here too
                    # else some tiles will still be cached
                    # in future could consider stamping tiles with date
                    #location.reload(true)
                else
                    currentPaperId = ajaxData.d0
        AJAX.doRequest(request, handleSuccess) 

    main = ->
        MAPVIEW.initialise()
        MAPVIEW.reload()

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

        # show everything
        $("#xiwiArea").show()

        # refresh world
        #$("#welcomePopup .refresh").click ->
        #    MAPVIEW.reload()

        ## keypopup
        #$("#keyPopup .close").click ->
        #    $("#keyPopup").hide()
        #$("#topRightMenu .info").click ->
        #    $("#keyPopup").show()
        #$("#keyPopup").hide()

        # colour scheme select
        $("#colourSchemeSelect .select").val('categories').bind('change', (event) ->
            INPUT.canvasColourSchemeSelect(event)
        )

        # info popup
        $("#infoPopup .close").click -> 
            INFOVIEW.close()
            MAPVIEW.draw()
        $("#infoPopup .showAbstract").click ->
            INFOVIEW.showAbstract()
        INFOVIEW.close()

        # zoom buttons
        $("#canvasZoomIn").click ->
            INPUT.canvasZoomInButton()

        $("#canvasZoomOut").click ->
            INPUT.canvasZoomOutButton()

        # now that the correct items are shown, resize everything to fit correctly
        resizeDOM()

        MAPVIEW.draw()
        
        checkDateAndVersion()
        
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

