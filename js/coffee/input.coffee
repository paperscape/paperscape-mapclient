# INPUT module
# 
# Contains functions relating to user input e.g. mouse clicks, interface buttons etc.

define ['app/Vec2D','app/selected','app/world','app/search','app/mapview','app/infoview','jquery','jquery.mousewheel'], (Vec2D,SELECTED,WORLD,SEARCH,MAPVIEW,INFOVIEW,$) ->

    exports = {}

    prevMouseEvent = null
    mouseDragged = false
    touchPrevNumTouches = 0
    touchPrevPos = null
    touchPrevDoubleDistance = null
    touchMoveCallback = null

    #############################################################
    # public methods involving top form and related buttons 
    #############################################################

    # Called when the user submits a search query
    exports.formSearchSubmit = (event) ->
        event.preventDefault()
        callbackPass = ->
            MAPVIEW.draw()
        SEARCH.doSearch(callbackPass)

    exports.doExampleSearch = (searchTerm) ->
        callbackPass = ->
            MAPVIEW.draw()
        $("#formSearch input:text")[0].value = searchTerm
        SEARCH.doSearch(callbackPass)

    #############################################################
    # public methods involving canvas buttons 
    #############################################################

    exports.canvasZoomInButton = (event) ->
        MAPVIEW.doZoomBy(null, 1 + 0.1 )
        MAPVIEW.draw()
        
    exports.canvasZoomOutButton = (event) ->
        MAPVIEW.doZoomBy(null, 1 - 0.1 )
        MAPVIEW.draw()

    exports.canvasColourSchemeSelect = (event) ->
        value = $("#colourSchemeSelect .select").val()
        if value == "paper_age"
            MAPVIEW.setHeatmap(true)
            $("#keyPopup .category").hide()
            $("#keyPopup .age").show()
        else
            MAPVIEW.setHeatmap(false)
            $("#keyPopup .age").hide()
            $("#keyPopup .category").show()
        MAPVIEW.draw()

    #############################################################
    # public methods to involving mouse
    #############################################################

    exports.iDevice = false

    exports.touchStart = (event) ->
        event.preventDefault()
        if event.touches.length == 1
            t0 = event.touches[0]
            touchPrevPos = {pageX:t0.pageX, pageY:t0.pageY, shiftKey:false, preventDefault:(->)}
            exports.mouseDown(touchPrevPos)

    exports.touchEnd = (event) ->
        event.preventDefault()
        if event.touches.length != 0 or touchPrevPos == null
            # only process a touchEnd request when all touches have finished
            return
        exports.mouseUp(touchPrevPos)
        touchPrevDoubleDistance = null
        touchPrevPos = null

    exports.touchMove = (event) ->
        event.preventDefault()

        # turn the touch into a centre pos and an optional distance
        centre
        dist
        if event.touches.length == 1
            t0 = event.touches[0]
            centre = {pageX:t0.pageX, pageY:t0.pageY, shiftKey:false}
            dist = null
        else if event.touches.length == 2
            t0 = event.touches[0]
            t1 = event.touches[1]
            centre = {pageX:(t0.pageX + t1.pageX) / 2, pageY:(t0.pageY + t1.pageY) / 2, shiftKey:false, preventDefault:(->)}
            dist = Math.sqrt(Math.pow(t0.pageX - t1.pageX, 2) + Math.pow(t0.pageY - t1.pageY, 2))
        else
            centre = null
            dist = null

        if event.touches.length != touchPrevNumTouches
            # if the user change the number of fingers in the touch, we reset the motion variables
            touchPrevNumTouches = event.touches.length
            touchPrevDoubleDistance = null
        else
            if touchMoveCallback != null
                touchMoveCallback(centre)
            if dist != null and touchPrevDoubleDistance != null
                distDiff = dist - touchPrevDoubleDistance
                # TODO this code should be same as mouseWheel!! (and it's not)
                MAPVIEW.doZoomBy(centre, 1 + distDiff / 100)
                MAPVIEW.draw()
        touchPrevPos = centre
        touchPrevDoubleDistance = dist
        prevMouseEvent = centre

    exports.bindMouseMove = (callback) ->
        if exports.iDevice
            touchMoveCallback = callback
        else
            MAPVIEW.jQueryAttach().mousemove(callback)

    exports.cancelMouseMove = () ->
        if exports.iDevice
            touchMoveCallback = null
        else
            MAPVIEW.jQueryAttach().off("mousemove")
        if MAPVIEW.highVerbosity()
            MAPVIEW.draw()

    exports.mouseDown = (event) ->
        event.preventDefault()
        mouseDragged = false
        # Uncomment to get position of clicks: 
        #console.log(MAPVIEW.getEventWorldPosition(event).round())
        if MAPVIEW.highVerbosity()
            MAPVIEW.draw()
        # call the pan function when the mouse moves
        exports.bindMouseMove(exports.mouseMovePan)
        prevMouseEvent = {pageX:event.pageX, pageY:event.pageY}

    exports.mouseUp = (event) ->
        if not exports.iDevice
            event.preventDefault()

        exports.cancelMouseMove() # disable the mouse move callback
    
        if not mouseDragged
            
            pos = MAPVIEW.getEventWorldPosition(event)
            
            # If user clicks within white search halo, find closest search
            # result, which will be used if available
            searchData = null
            if SEARCH.areSearchResults() and !SEARCH.isParentLinkResult()
                searchData = SEARCH.closestResultWithinRadius(pos,MAPVIEW.getSearchHaloRad())

            if searchData?
                SELECTED.setSelection(searchData)
                MAPVIEW.draw()
                INFOVIEW.update()
            else 
                isPaperCallback = (data) ->
                    if data.id != 0
                        SELECTED.setSelection(data)
                    #else if searchData?.id != 0
                    #   elseSELECTED.setSelection(searchData)
                    else 
                        SELECTED.clearSelection()
                    MAPVIEW.draw()
                    INFOVIEW.update()

                WORLD.fetchPaperIdAtLocation(pos.x,pos.y,isPaperCallback)

    exports.mouseLeave = (event) ->
        # disable the mouse move callback
        exports.cancelMouseMove()

    exports.mouseMovePan = (event) ->
        threshold = 1
        if Math.abs(event.pageX - prevMouseEvent.pageX) > threshold or Math.abs(event.pageY - prevMouseEvent.pageY) > threshold
            mouseDragged = true
            MAPVIEW.lowVerbosity()

            MAPVIEW.doMousePan(event, prevMouseEvent)
            MAPVIEW.draw()

            prevMouseEvent = {pageX:event.pageX, pageY:event.pageY}

    # Called when canvas is double clicked
    exports.mouseDoubleClick = (event) ->
        event.preventDefault()
        # zoom in using animation
        MAPVIEW.animateZoomIn(event, 1.10, 10, 25)

    # Called when mouse is scrolled over canvas
    exports.mouseWheel = (event, delta, deltaX, deltaY) ->
        event.preventDefault()
        if delta
            # hack to fix fast Mac scrolling; TODO fix it properly!
            if Math.abs(delta) > 100
                delta /= 40
            if delta < -3
                delta = -3
            if delta > 3
                delta = 3

            MAPVIEW.doZoomBy(event, 1 + delta / 10)
            MAPVIEW.draw()

    #############################################################
    # public methods for key presses
    #############################################################

    exports.keypressArrow = (key) ->
        dx = 0
        dy = 0
        if key == "left"
            dx = -1
        else if key == "right"
            dx = 1
        else if key == "up"
            dy = -1
        else if key == "down"
            dy = 1
        # pan the graph
        MAPVIEW.doKeyPan(new Vec2D(dx, dy))
        MAPVIEW.draw()

    exports.keypressZoom = (key) ->
        dz = 0
        if key == "=" or key == "+"
            dz = 1
        else if key == "-"
            dz = -1

        # zoom normally
        MAPVIEW.doZoomBy(null, 1 + 0.1 * dz)
        MAPVIEW.draw()

    #exports.keypressHeatmap = (key) ->
    #    if MAPVIEW.isHeatmap() 
    #        MAPVIEW.setHeatmap(false)
    #    else
    #        MAPVIEW.setHeatmap(true)

    #    MAPVIEW.draw()

    return exports
