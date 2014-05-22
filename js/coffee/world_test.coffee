define ['app/Vec2D','app/ajax','app/world'], (Vec2D, AJAX, WORLD) ->
    run : ->
        
        module "WORLD"
        
        test "Load world tile data", ->
            AJAX.setDefaults()
            testCallback = (dims) ->
                #dims = WORLD.getDimensions()
                #ok not isNaN(dims.padding) and dims.padding >= 0,
                #    "World padding should be non-negative number: #{dims.padding}"
                ok not isNaN(dims.tile_px_w) and dims.tile_px_w > 0 and
                   not isNaN(dims.tile_px_h) and dims.tile_px_h > 0,
                   "Tile pixel width and height should be positive numbers: #{dims.tile_px_w}x#{dims.tile_px_h}"
                
                ok not isNaN(dims.x_min) and not isNaN(dims.y_min) and 
                   not isNaN(dims.x_max) and not isNaN(dims.y_max) and
                   dims.x_min < dims.x_max  and dims.y_min < dims.y_max,
                   "World dimensions should not be zero or negative: x = [#{dims.x_min},#{dims.x_max}] , y = [#{dims.y_min},#{dims.y_max}]"
                
                latestPaperId = WORLD.getLatestPaperId()
                ok not isNaN(latestPaperId) and latestPaperId.toString().length == 10,
                    "Latest paper id should be 10 digit number: #{latestPaperId}"
                
                newPaperBoundaryId = WORLD.getNewPaperBoundaryId()
                ok not isNaN(newPaperBoundaryId) and newPaperBoundaryId.toString().length == 10 and newPaperBoundaryId < latestPaperId,
                    "Boundary paper id should be 10 digit number: #{latestPaperId}, and less than latest paper id"

                ## Test tilings (tune as necessary with tile data)
                
                ok WORLD.isWorldReady(),
                    "World ready"
                
                # TODO    
                #equal WORLD.getClosestTiling(5).depth, 0 
                #equal WORLD.getClosestTiling(5).numx, 4
                #equal WORLD.getClosestTiling(120).depth, 3
                #equal WORLD.getClosestTiling(120).numx, 72
                #equal WORLD.getClosestTiling(200).depth, 4
                #equal WORLD.getClosestTiling(200).numx, 216 


                # Test tile urls
                #dims = WORLD.getDimensions()
                depth = WORLD.getClosestTiling(256).depth
                # Currently x direction sets the y-tiling
                farEdge = dims.x_max - 50 -dims.x_min
                # Add 10 as rounding errors adding up!
                middle = Math.ceil((dims.x_max - dims.x_min)/2)+50
                tileInfo = WORLD.getTileInfoAtPosition(depth,farEdge,middle)
                equal tileInfo.path, "tiles/0/4/3.png"

                equal WORLD.getClosestLabelZone(5).depth, 0 

                start()
            errorCallback = ->
                ok false,
                    "Callback error"
                start()
            stop()
            WORLD.loadWorldData(testCallback,errorCallback)
               
        test "Meta for paper id", ->
            testId = 2115344314
            AJAX.setDefaults()
            testCallback = (wrapData) ->
                equal wrapData.id, testId, 
                    "Get back correct id"
                equal wrapData.authors, "R.Fleischer,R.Knegjens", 
                    "Get back correct author"
                equal wrapData.title[..18], "Effective Lifetimes", 
                    "Get back correct title"
                equal wrapData.arxivId, "1109.5115", 
                    "Get back correct arxiv id"
                equal wrapData.categories, "hep-ph,hep-ex", 
                    "Get back correct categories"
                equal wrapData.inspire, "928287", 
                    "Get back correct inspire record"
                equal wrapData.journal[..9], "EuroPhysJC", 
                    "Get back correct journal"
                ok not isNaN(wrapData.numCites), 
                    "Number cites given as number"
                start()
            errorCallback = ->
                ok false,
                    "Callback error"
                start()
            stop()
            WORLD.fetchMetaForPaperId(testId,testCallback,errorCallback)


        test "Abstract for paper id", ->
            testId = 2115344314
            stop()
            AJAX.setDefaults()
            testCallback = (wrapData) ->
                equal(wrapData.id, testId, "Get back correct id")
                abstStr = wrapData.abstract[..10]
                ok abstStr == "Measurement" or abstStr == "(no abstrac",
                    "Get back first 10 characters of abstract"
                start()
            errorCallback = ->
                ok false,
                    "Callback error"
                start()
            WORLD.fetchAbstractForPaperId(testId,testCallback,errorCallback)

        test "Fetch location of paper id", ->
            testId = 2115344314
            AJAX.setDefaults()
            testCallback = (wrapData) ->
                equal wrapData[0].id, testId, 
                    "Get back correct id" 
                ok wrapData[0].x? and wrapData[0].y? and wrapData[0].r?, 
                    "x,y,r defined" 
                start()
            errorCallback = ->
                ok false,
                    "Callback error"
                start()
            stop()
            WORLD.fetchLocationsForPaperIds([testId],testCallback,errorCallback)
       
        test "Fetch paper id at location (calls inverse first)", ->
            testId = 2115344314
            AJAX.setDefaults()
            testCallback = (wrapData) ->
                equal wrapData.id, 2115344314, 
                    "Get back correct id"
                start()
            errorCallback = ->
                ok false,
                    "Callback error" 
                start()
            prepCallback = (wrapData) ->
                WORLD.fetchPaperIdAtLocation(wrapData[0].x,wrapData[0].y,testCallback,errorCallback)
            stop()
            WORLD.fetchLocationsForPaperIds([testId],prepCallback,errorCallback)

        ###
        test "Fetch keywords in window", ->
            AJAX.setDefaults()
            stop()
            testCallback = (wrapData) ->
                equal wrapData[0].kw, "test keyword", 
                    "Get back correct keyword" 
                start()
            errorCallback = ->
                ok false,
                    "Callback error"
                start()
            WORLD.fetchKeywordInWindow(0,0,100,100,testCallback,errorCallback)
        ###
