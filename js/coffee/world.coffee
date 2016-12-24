# WORLD module
#
# Intended as an API.
# Talks to server and gives back results.
# Should hold no state beyond the details of todays "world".
# Should shield world from server json return formats.

define ['app/Vec2D','app/ajax'], (Vec2D, AJAX) ->
    exports = {}

    # Multiple tile servers to get around max http requests
    # per url
    DEFAULT_TILE_SERVERS = [
        "local_serve"
    ]

    tile_servers = $("#pscpConfig").data("tiles") ? DEFAULT_TILE_SERVERS
    
    tileServerIndex = 0

    worldReady = false

    subWorldPath = "/world" # if multple worlds on tile server

    dbSuffix = ""
    latestPaperId = 0
    newPaperBoundaryId = 0
    numberArxivPapers = 0
    lastDownloadDate = ""

    class TileDepth
        constructor: (depth, numx, numy, worldWidth, worldHeight) ->
            @depth = depth
            @numx = numx ? 0
            @numy = numy ? 0
            @width = worldWidth ? 0
            @height = worldHeight ? 0

    # Atm carbon copy of above, but may change in future
    class LabelDepth
        constructor: (depth, scale, numx, numy, worldWidth, worldHeight) ->
            @depth = depth
            @scale = scale
            @numx = numx ? 0
            @numy = numy ? 0
            @width = worldWidth ? 0
            @height = worldHeight ? 0

    tile_depths = null

    label_depths = null

    findTileDepth = (depth) ->
        for t in tile_depths when t.depth is depth
            return t
        return null 

    findLabelDepth = (depth) ->
        for l in label_depths when l.depth is depth
            return l
        return null 

    ###########################################################################
    # Public (exports)
    ###########################################################################

    exports.loadWorldData = (callbackPass,callbackFail) ->
        worldReady = false
        config =
            server: exports.getTileServer()
            urlExt: "/world_index.json"
            jsonpStatic: true
            jsonpCallback: "world_index" 
        request = {}
        handleSuccess = (ajaxData) ->
            #if ajaxData? and ajaxData?.tile?
            if ajaxData? and ajaxData?.tilings?
                dbSuffix = ajaxData?.dbsuffix ? "" 
                latestPaperId = ajaxData?.latestid ? 0
                
                newPaperBoundaryId = ajaxData?.newid ? latestPaperId
                
                numberArxivPapers = ajaxData?.numpapers ? 0
                lastDownloadDate  = ajaxData?.lastdl ? ""

                # get tiles info
                tile_depths = []
                tile_depths = (new TileDepth(tiling?.z,tiling?.nx,tiling?.ny,tiling?.tw,tiling?.th) for tiling in ajaxData.tilings when tiling?.z?)
                
                # get label zones info
                label_depths = []
                label_depths = (new LabelDepth(labeling?.z,labeling?.s,labeling?.nx,labeling?.ny,labeling?.w,labeling?.h) for labeling in ajaxData.zones when labeling?.z?)

                worldReady = true

                returnData =
                    x_min:      ajaxData?.xmin ? 0
                    y_min:      ajaxData?.ymin ? 0
                    x_max:      ajaxData?.xmax ? 0
                    y_max:      ajaxData?.ymax ? 0
                    tile_px_w:  ajaxData?.pixelw ? 0
                    tile_px_h:  ajaxData?.pixelh ? 0

                if callbackPass? 
                    callbackPass(returnData)
            else if callbackFail?
                callbackFail()
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError,config) 
        return

    exports.isWorldReady = ->
        worldReady
    
    exports.getLatestPaperId = ->
        latestPaperId

    exports.getNewPaperBoundaryId = ->
        newPaperBoundaryId

    exports.getNumberArxivPapers = ->
        numberArxivPapers

    exports.getLastDownloadDate = ->
        lastDownloadDate

    #exports.getClosestTiling = (totalNumTilesX) ->
    #    if tile_depths? and tile_depths.length > 0 
    #        #closest = tile_depths[0]
    #        closest = null
    #        for tiling in tile_depths 
    #            #if tiling.numx >= totalNumTilesX and Math.abs(tiling.numx-totalNumTilesX) < Math.abs(closest.numx-totalNumTilesX)
    #            if tiling.numx >= totalNumTilesX and (not closest? or tiling.numx < closest.numx)
    #                closest = tiling 
    #        if not closest?
    #            closest = tile_depths[0]

    # use maximum width calculation to make sure images are always sharp
    exports.getClosestTiling = (maximumTileWidth) ->
        if tile_depths? and tile_depths.length > 0
            closest = tile_depths[tile_depths.length - 1]
            for tiling in tile_depths
                if tiling.width <= maximumTileWidth and tiling.width > closest.width
                    closest = tiling

        else
            # Make sure we return something
            closest = new TileDepth(0)
        return {
            depth:  closest.depth
            numx:   closest.numx
            numy:   closest.numy
            width:  closest.width
            height: closest.height
        }

    exports.getClosestLabelZone = (scale) ->
        if label_depths? and label_depths.length > 0 
            closest = label_depths[0]
            for labeling in label_depths 
                if Math.abs(labeling.scale-scale) < Math.abs(closest.scale-scale)
                    closest = labeling 
        else
            # Make sure we return something
            closest = new LabelDepth(0)
        return {
            depth:  closest.depth
            scale:  closest.scale
            numx:   closest.numx
            numy:   closest.numy
            width:  closest.width
            height: closest.height
        }

    exports.setSubWorldPath = (path) ->
        if path? and path.length > 0 
            if path[0] != "/"
                path = "/#{path}"
            subWorldPath = path

    exports.getTileServer = () ->
        tileServerIndex += 1
        if tileServerIndex >= tile_servers.length
            tileServerIndex = 0
        return "#{tile_servers[tileServerIndex]}#{subWorldPath}"

    exports.getTileInfoAtPosition = (depth,dx,dy,specialTiles) ->
        # dx and dy are offsets from top-left corner
        suffix = ""
        if specialTiles? 
            if specialTiles == "heatmap"
                suffix = "-hm"
            if specialTiles == "grayscale"
                suffix = "-bw"
        # for now tiling is square
        tiling = findTileDepth(depth)
        nx = tiling.numx
        ny = tiling.numy
        ix = Math.ceil(dx / tiling.width)
        iy = Math.ceil(dy / tiling.height)
        #px = x_min + tiling.width*(ix-1)
        #py = y_min + tiling.height*(iy-1)
        if ix >= 1 and ix <= nx and iy >= 1 and iy <= ny
            path = "tiles#{suffix}/#{depth}/#{ix}/#{iy}.png" 
        else 
            path = null
        return {
            path: path
            #posx: px
            #posy: py
        }

    exports.fetchLabelZone = (depth,ix,iy,callbackPass,callbackFail) ->
        labeling = findLabelDepth(depth)
        labelZonePath = "/zones/#{depth}/#{ix}/#{iy}.json" 
        config =
            server: exports.getTileServer()
            urlExt: labelZonePath
            jsonpStatic: true
            jsonpCallback: "lz_#{depth}_#{ix}_#{iy}" 
        request = {}
        handleSuccess = (ajaxData) ->
            if ajaxData?
                returnData =
                    lbls: ajaxData.lbls ? []
                if callbackPass? 
                    callbackPass(returnData)
            else if callbackFail?
                callbackFail()
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError,config) 
        return


    exports.fetchMetaForPaperId = (id, callbackPass, callbackFail) ->
        request = 
            gdata: [id]
            flags: [0x01]
        handleSuccess = (ajaxData) ->
            returnData = 
                id :         ajaxData.papr[0]?.id ? 0
                numRefs:     ajaxData.papr[0]?.nr ? 0
                numCites:    ajaxData.papr[0]?.nc ? 0
                title:       ajaxData.papr[0]?.titl ? ""
                authors:     ajaxData.papr[0]?.auth ? ""
                journal:     ajaxData.papr[0]?.publ ? ""
                #arxivId:     ajaxData.papr[0]?.arxv ? ""
                #inspire:     ajaxData.papr[0]?.insp ? ""
                year:        ajaxData.papr[0]?.aux?.int1 ? 0
                mpg:         ajaxData.papr[0]?.aux?.int2 ? 0
                categories:  ajaxData.papr[0]?.aux?.str1 ? ""
                cocodes:     ajaxData.papr[0]?.aux?.str2 ? ""
            callbackPass(returnData)
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError) 
        
    exports.fetchAbstractForPaperId = (id, callbackPass, callbackFail) ->
        request = 
            gdata: [id]
            flags: [0x20]
        handleSuccess = (ajaxData) ->
            returnData =
                id :         ajaxData.papr[0]?.id ? 0
                abstract:    ajaxData.papr[0]?.abst ? ""
            callbackPass(returnData)
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError) 

    exports.fetchReferencesForId = (id, callbackPass, callbackFail) ->
        request =
            mr2l: id
            tbl: dbSuffix
        handleSuccess = (ajaxData) ->
            refs = []
            if ajaxData?.papr[0]?.ref?
                for ref in ajaxData.papr[0].ref
                    refs.push
                        id :  ref.id ? 0
                        freq: ref.f ? 1
                        x :   ref.x ? null
                        y :   ref.y ? null
                        r :   ref.r ? null
            returnData =
                id :         ajaxData?.papr[0]?.id ? 0
                x  :         ajaxData?.papr[0]?.x  ? null
                y  :         ajaxData?.papr[0]?.y  ? null
                r  :         ajaxData?.papr[0]?.r  ? null
                links :      refs
            callbackPass(returnData)
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError) 

    exports.fetchCitationsForId = (id, callbackPass, callbackFail) ->
        request =
            mc2l: id
            tbl: dbSuffix
        handleSuccess = (ajaxData) ->
            cites = []
            if ajaxData?.papr[0]?.cite?
                for cite in ajaxData?.papr[0]?.cite
                    cites.push
                        id :  cite.id ? 0
                        freq: cite.f ? 1
                        x :   cite.x ? null
                        y :   cite.y ? null
                        r :   cite.r ? null
            returnData =
                id :         ajaxData?.papr[0]?.id ? 0
                x  :         ajaxData?.papr[0]?.x  ? null
                y  :         ajaxData?.papr[0]?.y  ? null
                r  :         ajaxData?.papr[0]?.r  ? null
                links:       cites
            callbackPass(returnData)
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError) 

    exports.fetchLocationsForPaperIds = (ids, callbackPass, callbackFail) ->
        # TODO consider integrating this with gdata
        config = null
        request = 
            mp2l: ids
            tbl: dbSuffix
        if ids.length > 25
            config = { doPOST: true}
        handleSuccess = (ajaxData) ->
            returnData = []
            if ajaxData?
                for paper in ajaxData
                    returnData.push
                        id :        paper?.id ? 0
                        x  :        paper?.x ? null
                        y  :        paper?.y ? null
                        r  :        paper?.r ? null
            callbackPass(returnData)
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError, config) 
    
    exports.fetchPaperIdAtLocation = (x, y, callbackPass, callbackFail) ->
        request = 
            ml2p: [x,y]
            tbl: dbSuffix
        handleSuccess = (ajaxData) ->
            returnData =
                id :        ajaxData?.id ? 0
                x  :        ajaxData?.x ? null
                y  :        ajaxData?.y ? null
                r  :        ajaxData?.r ? null
            callbackPass(returnData)
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError) 
   

    exports.fetchSearchResults = (request,callbackPass,callbackFail) ->
        AJAX.doRequest(request,callbackPass,callbackFail) 


    ###
    exports.fetchKeywordInWindow = (x, y, w, h, callbackPass, callbackFail) ->
        request =
            mkws: [x,y,w,h]
        handleSuccess = (ajaxData) ->
            returnData = ajaxData ? []
            callbackPass(returnData)
        handleError = ->
            if callbackFail?
                callbackFail()
        AJAX.doRequest(request, handleSuccess, handleError) 
    ###

    return exports
