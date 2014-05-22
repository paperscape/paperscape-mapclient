# DETAILVIEW module
#
# 

define ['app/mapview','jquery'], (MAPVIEW,$) ->

    exports = {}

    detailViewVisible = false

    ###########################################################################
    # Public (exports)
    ###########################################################################

    exports.reload = ->
        if detailViewVisible
            zoomx = MAPVIEW.getXZoom()
            $("#detailView .zoomx").html(zoomx.toFixed(2))
            dims = MAPVIEW.getWorldDimensions()
            $("#detailView .dims").html("#{dims.x} x #{dims.y}")
            $("#detailView .viewx").html((dims.x/zoomx).toFixed(0))

    exports.show = ->
        if not detailViewVisible
            detailViewVisible = true
            exports.reload()
        $("#detailView").show()

    exports.hide = ->
        detailViewVisible = false
        $("#detailView").hide()

    exports.toggle = ->
        if detailViewVisible 
            exports.hide()
        else 
            exports.show()

    return exports
