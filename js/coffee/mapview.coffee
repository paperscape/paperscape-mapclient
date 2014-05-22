# MAPVIEW module
#
#

define ['app/Vec2D','app/world','app/search','app/selected','jquery'], (Vec2D,WORLD,SEARCH,SELECTED,$) ->

    exports = {}

    # world boundaries for zooming
    ZOOM_MIN = 0.75
    ZOOM_MAX = 1000

    SEARCH_HALO_RAD = 160

    x_min = 0
    y_min = 0
    x_max = 0
    y_max = 0

    # world boundaries for panning of tiles
    tile_px_w   = 0
    tile_px_h   = 0
    tile_depth  = 0
    tile_numx   = 0
    tile_numy   = 0
    tile_view_w  = 0
    tile_view_h  = 0
    tile_world_w = 0
    tile_world_h = 0

    # world boundaries for label zones
    label_depth  = 0
    label_scale  = 0
    label_numx   = 0
    label_numy   = 0
    label_world_w = 0
    label_world_h = 0

    # For tiles
    ctxTiles    = null
    canvasTiles = null
   
    # For overlay on tiles
    ctxOverlay = null
    canvasOverlay = null

    # For underlay on tiles
    ctxUnderlay = null
    canvasUnderlay = null

    # transform coords
    zoom        = 1
    pan         = new Vec2D(0, 0)

    # previous transform coords used to draw tiles; so we can re-use canvas when panning/zooming
    prevZoom    = 1
    prevPan     = new Vec2D(0, 0)

    highVerbosity = true
   
    MAX_TILES  = 500
    MAX_LABELS = 500

    allTiles = []
    allLabelZones = []

    # whether special tiles should be drawn
    specialTilesId = null

    # unique scene id so tiles know whether to still draw
    currentSceneId = 0

    zoomChangeCanvasCopy = false

    zoomExternalFunction = null

    # A Tile object represents a specific image from the server, in 1-1 correspondence
    # with its path.  This path remains constant throughout the Tile object's life.
    # A Tile can draw itself on the canvas at the right location.
    #
    # It is in one of 2 states:
    #   - Unloaded: image is loading; when loaded it will draw to the canvas at pos, if scene id is unchanged
    #   - Loaded: image is loaded; it will draw itself straight away if asked to
    class Tile
        constructor: (path) ->
            @path = path
            @img  = new Image()
            @loaded = false
            @pos = new Vec2D(0, 0)
            @sceneId = 0

            # set callbacks for image loading
            $(@img).load (event) =>
                @loaded = true
                if @sceneId == currentSceneId
                    drawTileImage(@img, @pos.x, @pos.y, tile_view_w, tile_view_h)
            $(@img).error (event) =>
                # invalidate the path so no one uses this tile
                @path = 'failed'
                @loaded = false

            # load the image straight away
            @img.src = "#{WORLD.getTileServer()}/#{@path}"

        draw: (sceneId, pos) =>
            # move to start of tiles list
            for i in [0...allTiles.length]
                if allTiles[i].path == @path
                    allTiles.splice(i,1)
                    allTiles.unshift(this)
                    break
            if @loaded 
                # loaded; draw straight away
                drawTileImage(@img, pos.x, pos.y, tile_view_w, tile_view_h)
            else
                # still loading; set position and scene-id for when loading finishes
                @pos.x = pos.x
                @pos.y = pos.y
                @sceneId = sceneId
                if !zoomChangeCanvasCopy
                    ctxTiles.clearRect(pos.x, pos.y, tile_view_w, tile_view_h)

    class LabelZone
        constructor: (depth,x,y) ->
            @depth = depth
            @x = x
            @y = y
            @keywords = []
            @loaded = false

        load : =>
            # move to start of label zones list
            for i in [0...allLabelZones.length]
                if allLabelZones[i].depth == @depth and allLabelZones[i].x == @x and allLabelZones[i].y == @y
                    allLabelZones.splice(i,1)
                    allLabelZones.unshift(this)
                    break
            if !@loaded
                passCallback = (data) =>
                    for kw in data.lbls
                        lbls = kw.lbl.split(',')
                        if lbls[3].length == 0
                            au = lbls[2]
                        else if lbls[3] == 'et al.'
                            au = lbls[2] + ' ' + lbls[3]
                        else
                            au = lbls[2] + ' and ' + lbls[3]
                        @keywords.push({pos: new Vec2D(kw.x, kw.y), r:kw.r, lbl1:lbls[0], lbl2:lbls[1], au:au})
                    @loaded = true
                    drawOverlay()        
                WORLD.fetchLabelZone(@depth,@x,@y,passCallback)

    drawTileImage = (image, x, y, w, h) ->
        ctxTiles.clearRect(x, y, w, h)
        ctxTiles.drawImage(image, x, y, w, h)

    findTileByName = (path) -> 
        for tile in allTiles when tile.path == path
            return tile
        null

    getTile = (path) ->
        if not path?
            return null
        tile = findTileByName(path)
        if not tile?
            tile = new Tile(path)
            allTiles.unshift(tile)
            if allTiles.length > MAX_TILES
                allTiles = allTiles.slice(0,MAX_TILES)
        return tile

    getLabelZone = (depth,xi,yi) ->
        for lz in allLabelZones when (lz.depth == depth and lz.x == xi and lz.y == yi)
            return lz
        lz = new LabelZone(depth,xi,yi)
        allLabelZones.unshift(lz)
        if allLabelZones.length > MAX_LABELS
            allLabelZones = allLabelZones.slice(0,MAX_LABELS)
        lz.load()
        return lz

    # Clip the pan to the world boundaries
    panClip = ->
        canvasWorldW = canvasOverlay.width*viewToWorldScale()
        canvasWorldH = canvasOverlay.height*viewToWorldScale()
        if canvasWorldW <= x_max - x_min
            if pan.x < x_min
                pan.x = x_min
            else if pan.x > x_max - canvasWorldW
                pan.x = x_max - canvasWorldW
        else 
            pan.x = x_min - (canvasWorldW - (x_max-x_min))/2
        if canvasWorldH <= y_max - y_min
            if pan.y < y_min
                pan.y = y_min
            else if pan.y > y_max - canvasWorldH
                pan.y = y_max - canvasWorldH
        else 
            pan.y = y_min - (canvasWorldH - (y_max-y_min))/2

    eventToView = (event) ->
        totalOffsetX = 0
        totalOffsetY = 0
        canvasX = 0
        canvasY = 0
        currentElement = canvasOverlay

        # iterate through all parents elements (such as divs etc)
        while currentElement
            totalOffsetX += currentElement.offsetLeft
            totalOffsetY += currentElement.offsetTop
            currentElement = currentElement.offsetParent

        try
            canvasX = event.pageX
            canvasY = event.pageY
        catch err
            canvasX = event.clientX + document.body.scrollLeft + document.documentElement.scrollLeft
            canvasY = event.clientY + document.body.scrollTop + document.documentElement.scrollTop
        finally
            canvasX -= totalOffsetX
            canvasY -= totalOffsetY

        return new Vec2D(canvasX, canvasY)

    worldToViewScale = ->
        return canvasTiles.width*zoom/(x_max-x_min)

    viewToWorldScale = ->
        return 1/worldToViewScale()

    worldToView = (worldVec) ->
        return worldVec.sub(pan).mul(worldToViewScale())

    viewToWorld = (viewVec) ->
        return viewVec.mul(viewToWorldScale()).add(pan)

    setNewZoom = (newZoom) ->
        # clip the zoom level
        if newZoom < ZOOM_MIN
            zoom = ZOOM_MIN
        else if newZoom > ZOOM_MAX
            zoom = ZOOM_MAX
        else
            zoom = newZoom
        # Zoom level should leave tile_view dimension integer
        if tile_world_w > 0
            zoom *= Math.round(tile_world_w*worldToViewScale())/(tile_world_w*worldToViewScale())

    setNewPan = (newPan) ->
        pan = newPan
        panClip()
        # Pan should keep tiling origin integer
        view_o = worldToView(new Vec2D(x_min,y_min))
        diff = view_o.round().sub(view_o).mul(viewToWorldScale())
        pan = pan.sub(diff)

    updateTileDepth = ->

        #desiredNumXTiles = Math.ceil((canvasTiles.width / tile_px_w) * zoom)
        #tiling = WORLD.getClosestTiling(desiredNumXTiles)

        # use maximum width calculation to make sure images are always sharp
        maximumTileWidth = tile_px_w * viewToWorldScale()
        tiling = WORLD.getClosestTiling(maximumTileWidth)

        tile_depth   = tiling.depth
        tile_numx    = tiling.numx
        tile_numy    = tiling.numy
        tile_world_w = tiling.width
        tile_world_h = tiling.height

        # make sure tile_view dimension is an integer
        # need to readjust zoom here because tile_world_w may have changed
        zoom *= Math.round(tile_world_w*worldToViewScale())/(tile_world_w*worldToViewScale())
        tile_view_w  = Math.round(tile_world_w*worldToViewScale())
        tile_view_h  = Math.round(tile_world_h*worldToViewScale())

    updateLabelDepth = ->
        scale = (x_max-x_min)/zoom
        labeling = WORLD.getClosestLabelZone(scale)
        label_depth   = labeling.depth
        label_scale   = labeling.scale
        label_numx    = labeling.numx
        label_numy    = labeling.numy
        label_world_w = labeling.width
        label_world_h = labeling.height

    focusOnPositionList = (positions) ->
        sxmax = positions[0].x
        sxmin = positions[0].x
        symin = positions[0].y
        symax = positions[0].y
        for result in positions
            if result.x > sxmax 
                sxmax = result.x
            else if result.x < sxmin
                sxmin = result.x
            if result.y > symax 
                symax = result.y
            else if result.y < symin
                symin = result.y
        canvasWorldW = canvasOverlay.width*viewToWorldScale()
        canvasWorldH = canvasOverlay.height*viewToWorldScale()
        setNewPan(new Vec2D((sxmax+sxmin)/2-canvasWorldW/2,(symax+symin)/2- canvasWorldH/2).round())
        scale = Math.max(2000.0, 1.1*Math.max((sxmax-sxmin),(symax-symin)*canvasOverlay.width/canvasOverlay.height))
        if scale > 0
            exports.doZoomBy(null,(x_max-x_min)/scale/zoom)

    requestedAnimation = false
  
    # Returns list of labels relevant for current view
    getLabels = ->

        # work out label zones relevant for current view
        lzs = []
        
        sp = viewToWorld(new Vec2D(0,0))
        w = canvasOverlay.width*viewToWorldScale()
        h = canvasOverlay.height*viewToWorldScale()
        
        for xi in [1..label_numx]
            for yi in [1..label_numy]
                left   = x_min + (xi-1)*label_world_w
                right  = x_min + xi*label_world_w
                top    = y_min + (yi-1)*label_world_h
                bottom = y_min + yi*label_world_h
                if (left < sp.x < right or left < sp.x+w < right) and (top < sp.y < bottom or top < sp.y+h < bottom)
                    lzs.push(getLabelZone(label_depth,xi,yi))
        
        results = []
        
        for lz in lzs
            if lz.loaded
                for kw in lz.keywords
                    if pan.x < kw.pos.x < pan.x + w and pan.y < kw.pos.y < pan.y + h
                        if kw.r*worldToViewScale() > 18
                            results.push(kw)

        # draw only top n results
        if highVerbosity
            max_res = 35
        else
            max_res = 5

        if results.length > max_res
            results.sort((a,b) -> b.r - a.r)
            results = results.slice(0,max_res)

        return results

    drawTiles = ->
        if not WORLD.isWorldReady()
            return
        
        ctxTiles.setTransform(1, 0, 0, 1, 0, 0)

        #if zoom == prevZoom
        #    # just panning, clear entire canvas
        #    ctxTiles.clearRect(0, 0, canvasUnderlay.width, canvasUnderlay.height)
        #else

        if zoom != prevZoom
            zoomChangeCanvasCopy = true

        if zoomChangeCanvasCopy
            # re-use as much of the previous canvas as possible

            # work out what the top-left and bottom-right corners used to map to in world coordinates
            oldWorldTopLeftX = prevPan.x
            oldWorldTopLeftY = prevPan.y
            oldWorldBottomRightX = (x_max - x_min) / prevZoom + prevPan.x
            oldWorldBottomRightY = canvasTiles.height / canvasTiles.width / prevZoom * (x_max - x_min) + prevPan.y

            # work out their new view coordinates
            newViewTopLeftX = (oldWorldTopLeftX - pan.x) * worldToViewScale()
            newViewTopLeftY = (oldWorldTopLeftY - pan.y) * worldToViewScale()
            newViewBottomRightX = (oldWorldBottomRightX - pan.x) * worldToViewScale()
            newViewBottomRightY = (oldWorldBottomRightY - pan.y) * worldToViewScale()

            # copy the canvas region over itself with correct scaling and offset
            ctxTiles.globalCompositeOperation = "copy"
            ctxTiles.drawImage(canvasTiles, 0, 0, canvasTiles.width, canvasTiles.height, newViewTopLeftX, newViewTopLeftY, newViewBottomRightX - newViewTopLeftX, newViewBottomRightY - newViewTopLeftY)
            ctxTiles.globalCompositeOperation = "source-over"
        #else
        #    ctxTiles.clearRect(0, 0, canvasTiles.width, canvasTiles.height)

        # save previous zoom and pan
        prevZoom = zoom
        prevPan.x = pan.x
        prevPan.y = pan.y

        # Get tile offset
        worldStartPos = viewToWorld(new Vec2D(0,0))
        if worldStartPos.x < x_min 
            worldStartPos.x = x_min
        else 
            worldStartPos.x = x_min + tile_world_w*Math.floor((worldStartPos.x - x_min)/tile_world_w)
        if worldStartPos.y < y_min 
            worldStartPos.y = y_min
        else 
            worldStartPos.y = y_min + tile_world_h*Math.floor((worldStartPos.y - y_min)/tile_world_h)
        viewStartPos = worldToView(worldStartPos).round()

        # create a new scene-id; truncate so it doesn't run off to infinity
        currentSceneId = (currentSceneId + 1) & 0xffffff

        # clear side/top bands if needed
        if viewStartPos.x > 0
            ctxTiles.clearRect(0, 0, viewStartPos.x, canvasTiles.height)
        if viewStartPos.y > 0
            ctxTiles.clearRect(0, 0, canvasTiles.width, viewStartPos.y)


        # draw the tiles
        allTilesLoaded = true
        sceneId = currentSceneId
        for vx in [viewStartPos.x...canvasTiles.width+tile_view_w] by tile_view_w
            for vy in [viewStartPos.y...canvasTiles.height+tile_view_h] by tile_view_h
                viewPos  = new Vec2D(vx,vy)
                worldPos = viewToWorld(viewPos)
                tileData = WORLD.getTileInfoAtPosition(tile_depth,worldPos.x+tile_world_w/2 - x_min,worldPos.y+tile_world_h/2 - y_min,specialTilesId)
                if (tile = getTile(tileData?.path))?
                    if !tile.loaded
                        allTilesLoaded = false
                    tile.draw(sceneId, viewPos)
                else 
                    # if no tile then clear 
                    ctxTiles.clearRect(viewPos.x, viewPos.y, tile_view_w, tile_view_h)

        if zoomChangeCanvasCopy
            zoomChangeCanvasCopy = !allTilesLoaded

    drawUnderlay = ->
        
        ctxUnderlay.setTransform(1, 0, 0, 1, 0, 0)
        ctxUnderlay.fillStyle = "#000"
        ctxUnderlay.fillRect(0, 0, canvasUnderlay.width, canvasUnderlay.height)

        if SEARCH.areSearchResults()
            searchResults = SEARCH.getSearchResults()

            if SEARCH.isParentLinkResult() 
                # LINK SEARCH
                
                parent = SEARCH.getParentLinkResult()

                viewPos = worldToView(new Vec2D(parent.x,parent.y)).round()
                viewRad = Math.max(Math.round(parent.r*worldToViewScale()),1)
                ctxUnderlay.strokeStyle = "#ccc"
                if highVerbosity
                    for link in searchResults
                        viewPosB = worldToView(new Vec2D(link.x,link.y)).round()
                        viewRadB = Math.max(Math.round(link.r*worldToViewScale()),1)

                        # clip link lines:
                        if (viewPos.x < 0 and viewPosB.x < 0) or (viewPos.x > canvasUnderlay.width and viewPosB.x > canvasUnderlay.width) or (viewPos.y < 0 and viewPosB.y < 0) or (viewPos.y > canvasUnderlay.height and viewPosB.y > canvasUnderlay.height)
                            continue

                        #diff = viewPosB.sub(viewPos)
                        #viewPosA = viewPos.add(diff.mul(viewRad/diff.len())).round()
                        halfLw = Math.min(0.5*link.freq,0.5*viewRad)
                        ctxUnderlay.lineWidth = 2*halfLw
                        ctxUnderlay.beginPath()
                        ctxUnderlay.moveTo(viewPos.x,viewPos.y)
                        ctxUnderlay.lineTo(viewPosB.x,viewPosB.y)
                        ctxUnderlay.stroke()

                    ctxUnderlay.fillStyle = "#fff"
                    for link in searchResults
                        viewPosB = worldToView(new Vec2D(link.x,link.y)).round()
                        viewRadB = Math.max(Math.round(link.r*worldToViewScale()),1)
                        # clip
                        if (-viewRadB < viewPosB.x < canvasOverlay.width+viewRadB) and (-viewRadB < viewPosB.y < canvasOverlay.height+viewRadB) 
                            halfLw = Math.min(0.5*link.freq,0.5*viewRad)
                            ctxUnderlay.beginPath()
                            ctxUnderlay.arc(viewPosB.x,viewPosB.y,halfLw+viewRadB*1.1,0,Math.PI*2,true)
                            ctxUnderlay.fill()
                
                ctxUnderlay.fillStyle = "#fff"
                ctxUnderlay.lineWidth = Math.min(4,viewRad+4)
                ctxUnderlay.beginPath()
                ctxUnderlay.arc(viewPos.x,viewPos.y,viewRad*1.1,0,Math.PI*2,true)
                ctxUnderlay.fill()

            else 
                # STANDARD SEARCH CIRCLES
                
                # NOW: use alpha overlay
                # outer filled circle
                ctxUnderlay.fillStyle = "#fff"
                for result in searchResults
                    viewPos = worldToView(new Vec2D(result.x,result.y))
                    viewRad = Math.round(result.r*worldToViewScale())
                    innerRad = Math.round((result.r+3)*worldToViewScale())
                    outerRad = Math.max(2*Math.round(Math.max(result.r,SEARCH_HALO_RAD/2)*worldToViewScale()),2)
                    # clip
                    if (-viewRad < viewPos.x < canvasOverlay.width+viewRad) and (-viewRad < viewPos.y < canvasOverlay.height+viewRad) 
                        ctxUnderlay.beginPath()
                        ctxUnderlay.arc(viewPos.x,viewPos.y,outerRad,0,Math.PI*2,true)
                        ctxUnderlay.arc(viewPos.x,viewPos.y,innerRad,0,Math.PI*2,false)
                        ctxUnderlay.fill()
                
                # outer circle if selected
                if (selectedId = SELECTED.getSelectedId())?
                    for result in searchResults when selectedId == result.id
                        viewPos = worldToView(new Vec2D(result.x,result.y))
                        viewRad = Math.round(result.r*worldToViewScale())
                        outerRad = Math.max(2*Math.round(Math.max(result.r,(SEARCH_HALO_RAD)/2)*worldToViewScale()),2)
                        # clip
                        if (-viewRad < viewPos.x < canvasOverlay.width+viewRad) and (-viewRad < viewPos.y < canvasOverlay.height+viewRad)
                            if specialTilesId == "heatmap"
                                ctxUnderlay.strokeStyle = "#00f"
                            else
                                ctxUnderlay.strokeStyle = "#f00"
                            ctxUnderlay.lineWidth = Math.min(4,viewRad+2)
                            ctxUnderlay.beginPath()
                            ctxUnderlay.arc(viewPos.x,viewPos.y,outerRad,0,Math.PI*2,true)
                            ctxUnderlay.stroke()

                # inner filled circle
                #ctxUnderlay.fillStyle = "#000"
                #for result in searchResults
                #    viewPos = worldToView(new Vec2D(result.x,result.y))
                #    viewRad = Math.round(result.r*worldToViewScale())
                #    innerRad = Math.round((result.r+3)*worldToViewScale())
                #    # clip
                #    if (-viewRad < viewPos.x < canvasOverlay.width+viewRad) and (-viewRad < viewPos.y < canvasOverlay.height+viewRad)
                #        ctxUnderlay.beginPath()
                #        ctxUnderlay.arc(viewPos.x,viewPos.y,innerRad,0,Math.PI*2,true)
                #        ctxUnderlay.fill()
       
    drawOverlay = ->
        
        ctxOverlay.setTransform(1, 0, 0, 1, 0, 0)
        ctxOverlay.clearRect(0, 0, canvasOverlay.width, canvasOverlay.height)
       

        if SEARCH.areSearchResults() and !SEARCH.isParentLinkResult() 
            searchResults = SEARCH.getSearchResults()

            # outer filled circle is alpha
            ctxOverlay.fillStyle = "rgba(255, 255, 255, 0.5)" #"#fff"
            for result in searchResults
                viewPos = worldToView(new Vec2D(result.x,result.y))
                viewRad = Math.round(result.r*worldToViewScale())
                outerRad = Math.max(2*Math.round(Math.max(result.r,SEARCH_HALO_RAD/2)*worldToViewScale()),2)
                innerRad = Math.round((result.r+3)*worldToViewScale())
                # clip
                if (-viewRad < viewPos.x < canvasOverlay.width+viewRad) and (-viewRad < viewPos.y < canvasOverlay.height+viewRad) 
                    ctxOverlay.beginPath()
                    ctxOverlay.arc(viewPos.x,viewPos.y,outerRad,0,Math.PI*2,true)
                    ctxOverlay.arc(viewPos.x,viewPos.y,innerRad,0,Math.PI*2,false)
                    ctxOverlay.fill()


        # box selection
        if SELECTED.isSelected() and (worldPos = SELECTED.getSelectedPos())? and (worldRad = SELECTED.getSelectedRad())?
            viewPos = worldToView(worldPos).round()
            viewRad = Math.max(Math.round(worldRad*worldToViewScale()),1)
            if specialTilesId == "heatmap"
                ctxOverlay.strokeStyle = "#00f"
            else
                ctxOverlay.strokeStyle = "#f00"
            # clip
            if (-viewRad < viewPos.x < canvasOverlay.width+viewRad) and (-viewRad < viewPos.y < canvasOverlay.height+viewRad) 
                ctxOverlay.lineWidth = Math.min(4,viewRad+2)
                ctxOverlay.beginPath()
                ctxOverlay.arc(viewPos.x,viewPos.y,viewRad,0,Math.PI*2,true)
                ctxOverlay.stroke()

        # draw labels
        if WORLD.isWorldReady()
            labels = getLabels()

            ctxOverlay.textAlign = "center"
            ctxOverlay.fillStyle = "#fff"
            ctxOverlay.strokeStyle = "#000"
            ctxOverlay.lineWidth = 1.6
            for label in labels
                vpos = worldToView(label.pos).round()
                pixR = label.r * worldToViewScale()
                drawTwo = (label.lbl2.length != 0) and (label.lbl1 == 'REVIEW' or label.lbl1 == 'LECTURE' or pixR > 40)
                drawAu = (label.au.length > 0) and (pixR > 50)

                # set font size based on pixel-radius of label (these could do with some fine-tuning)
                if pixR > 250
                    ctxOverlay.font = "14px sans-serif"
                    vpos.y += 5
                    textHalf = 7
                    textFull = 16
                else if pixR > 150
                    ctxOverlay.font = "12px sans-serif"
                    vpos.y += 4
                    textHalf = 6
                    textFull = 13
                else
                    ctxOverlay.font = "10px sans-serif"
                    vpos.y += 3
                    textHalf = 5
                    textFull = 11

                # draw the label
                if drawTwo
                    if drawAu
                        ctxOverlay.strokeText(label.lbl1, vpos.x, vpos.y - textFull)
                        ctxOverlay.fillText(label.lbl1, vpos.x, vpos.y - textFull)
                        ctxOverlay.strokeText(label.lbl2, vpos.x, vpos.y)
                        ctxOverlay.fillText(label.lbl2, vpos.x, vpos.y)
                        ctxOverlay.fillStyle = "#99f"
                        ctxOverlay.strokeText(label.au, vpos.x, vpos.y + textFull)
                        ctxOverlay.fillText(label.au, vpos.x, vpos.y + textFull)
                        ctxOverlay.fillStyle = "#fff"
                    else if label.lbl2[0] == '(' and label.lbl1.length > 30 and label.lbl1.indexOf('/') > 0
                        # a hack to split gr-qc name in two
                        lbls = label.lbl1.split('/')
                        ctxOverlay.strokeText(lbls[0], vpos.x, vpos.y - textFull)
                        ctxOverlay.fillText(lbls[0], vpos.x, vpos.y - textFull)
                        ctxOverlay.strokeText(lbls[1], vpos.x, vpos.y)
                        ctxOverlay.fillText(lbls[1], vpos.x, vpos.y)
                        ctxOverlay.strokeText(label.lbl2, vpos.x, vpos.y + textFull)
                        ctxOverlay.fillText(label.lbl2, vpos.x, vpos.y + textFull)
                    else
                        ctxOverlay.strokeText(label.lbl1, vpos.x, vpos.y - textHalf)
                        ctxOverlay.fillText(label.lbl1, vpos.x, vpos.y - textHalf)
                        ctxOverlay.strokeText(label.lbl2, vpos.x, vpos.y + textHalf + 1)
                        ctxOverlay.fillText(label.lbl2, vpos.x, vpos.y + textHalf + 1)
                else
                    if drawAu
                        ctxOverlay.strokeText(label.lbl1, vpos.x, vpos.y - textHalf)
                        ctxOverlay.fillText(label.lbl1, vpos.x, vpos.y - textHalf)
                        ctxOverlay.fillStyle = "#99f"
                        ctxOverlay.strokeText(label.au, vpos.x, vpos.y + textHalf + 1)
                        ctxOverlay.fillText(label.au, vpos.x, vpos.y + textHalf + 1)
                        ctxOverlay.fillStyle = "#fff"
                    else
                        ctxOverlay.strokeText(label.lbl1, vpos.x, vpos.y)
                        ctxOverlay.fillText(label.lbl1, vpos.x, vpos.y)


    drawAll = ->
        # check if we need to move to new search position
        if SEARCH.areSearchResults() and SEARCH.zoomOnceOnSearch()
            focusOnPositionList(SEARCH.getSearchResults())

        drawUnderlay()
        drawTiles()
        drawOverlay()
        requestedAnimation = false

    ###########################################################################
    # Public (exports)
    ###########################################################################

    exports.reload = (callbackPass,callbackFail) ->
        # Load tile data
        loadTilesCallback = (data) ->
            x_min = data.x_min
            y_min = data.y_min
            x_max = data.x_max
            y_max = data.y_max
            tile_px_w = data.tile_px_w
            tile_px_h = data.tile_px_h
            
            allTiles = []
            allLabelZones = []

            # start with a centred view
            # Start with a zoom so user can instantly pan
            # and also see main categories
            setNewZoom(1.5)
            setNewPan(new Vec2D(
                0.5 * (x_min + x_max - canvasOverlay.width*viewToWorldScale()),
                0.5 * (y_min + y_max - canvasOverlay.height*viewToWorldScale())))

            updateTileDepth()
            updateLabelDepth()
            if zoomExternalFunction?
                zoomExternalFunction()
            exports.draw()
            if callbackPass? 
                callbackPass()
        loadTilesFailCallback = ->
            # TODO
            console.log "Tile loading failed"
            if callbackFail? 
                callbackFail()
        subWorldPath = $("#mapSelect .select").val()
        if subWorldPath?
            WORLD.setSubWorldPath(subWorldPath)
        WORLD.loadWorldData(loadTilesCallback,loadTilesFailCallback)

    exports.initialise = ->
        canvasTiles = document.getElementById("canvasTiles")
        ctxTiles = canvasTiles.getContext("2d")

        canvasOverlay = document.getElementById("canvasOverlay")
        ctxOverlay    = canvasOverlay.getContext("2d") 

        canvasUnderlay = document.getElementById("canvasUnderlay")
        ctxUnderlay    = canvasUnderlay.getContext("2d") 

        exports.resize()
        #exports.reload()  # now called by main (with possible callback)

    exports.resize = (canvasWidth, canvasHeight, canvasLeft, canvasTop) ->
        if canvasUnderlay? 
            canvasUnderlay.width        = canvasWidth
            canvasUnderlay.height       = canvasHeight
            canvasUnderlay.style.top    = canvasTop    + 'px'
            canvasUnderlay.style.left   = canvasLeft   + 'px'
            canvasUnderlay.style.width  = canvasWidth  + 'px'
            canvasUnderlay.style.height = canvasHeight + 'px'
        if canvasTiles? 
            canvasTiles.width           = canvasWidth
            canvasTiles.height          = canvasHeight
            canvasTiles.style.top       = canvasTop    + 'px'
            canvasTiles.style.left      = canvasLeft   + 'px'
            canvasTiles.style.width     = canvasWidth  + 'px'
            canvasTiles.style.height    = canvasHeight + 'px'
            updateTileDepth()
        if canvasOverlay? 
            canvasOverlay.width         = canvasWidth
            canvasOverlay.height        = canvasHeight
            canvasOverlay.style.top     = canvasTop    + 'px'
            canvasOverlay.style.left    = canvasLeft   + 'px'
            canvasOverlay.style.width   = canvasWidth  + 'px'
            canvasOverlay.style.height  = canvasHeight + 'px'
            updateLabelDepth()

    exports.getTopCanvas = ->
        return canvasOverlay

    exports.jQueryAttach = ->
        return $("#canvasOverlay")

    exports.getEventWorldPosition = (event) ->
        return viewToWorld(eventToView(event))

    exports.doMousePan = (mouseEvent1, mouseEvent2) ->
        dx = (mouseEvent1.pageX - mouseEvent2.pageX)*viewToWorldScale()
        #dy = -(mouseEvent1.pageY - mouseEvent2.pageY)/worldToViewScaleY()
        dy = (mouseEvent1.pageY - mouseEvent2.pageY)*viewToWorldScale()
        setNewPan(pan.sub(new Vec2D(dx,dy)))

    exports.doKeyPan = (dirVec) ->
        shift = 1000
        setNewPan(pan.add(dirVec.mul(shift/zoom)))

    exports.doZoomBy = (event, zoomFac) ->
        if event?
            centrePos = viewToWorld(eventToView(event))
        else 
            centrePos = viewToWorld(new Vec2D(canvasTiles.width/2,canvasTiles.height/2))
        oldZoom = zoom
        setNewZoom(zoom * zoomFac)
        setNewPan(pan.mul(oldZoom/zoom).add(centrePos.mul(1 - oldZoom/zoom)))
        updateTileDepth()
        updateLabelDepth()
        if zoomExternalFunction?
            zoomExternalFunction()

    animateZoomInterval = -1
    
    exports.draw = ->
        if animateZoomInterval >= 0
            clearInterval(animateZoomInterval)
            animateZoomInterval = -1
        if not requestedAnimation
            requestedAnimation = true
            requestAnimationFrame(drawAll)

    exports.animateZoomIn = (event, zoomFactor, count, delay) ->
        if animateZoomInterval >= 0
            clearInterval(animateZoomInterval)
        animateZoomInterval = setInterval(->
            exports.doZoomBy(event, zoomFactor)
            requestAnimationFrame(drawAll)
            if count-- <= 0
                clearInterval(animateZoomInterval)
                animateZoomInterval = -1
                requestAnimationFrame(drawAll)
        , delay)


    exports.highVerbosity = () ->
        oldState = highVerbosity
        highVerbosity = true
        # return true if state changed
        return !oldState == highVerbosity

    exports.lowVerbosity = () ->
        oldState = highVerbosity
        highVerbosity = false
        # return true if state changed
        return !oldState == highVerbosity

    exports.bindZoomFunction = (func) ->
        if func?
            zoomExternalFunction = func
  
    # When to show welcome message / fading popup
    exports.showOverlay = () ->
        return zoom < 2

    # TODO temp, move this to separate state module
    exports.isHeatmap = ->
        return specialTilesId == "heatmap"

    exports.setHeatmap = (enable) ->
        if enable? and enable
            specialTilesId = "heatmap"
        else
            specialTilesId = null

    exports.getXZoom = ->
        return zoom

    exports.getWorldDimensions = ->
        return {
            x: x_max-x_min
            y: y_max-y_min
        }

    exports.getSearchHaloRad = ->
        return SEARCH_HALO_RAD

    return exports
