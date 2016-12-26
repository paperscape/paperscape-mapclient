# AJAX module
# 
# Performs ajax requests. Holds no state except for server address.

define ['jquery'], ($) ->
   
    exports = {}

    DEFAULT_TIMEOUT        = 20000
    DEFAULT_URL_EXTENSION  = "/wombat"
    DEFAULT_SERVER         = "http://localhost:8089"

    server  = $("#pscpConfig").data("server")  ? DEFAULT_SERVER
    timeout = $("#pscpConfig").data("ajaxTimeout") ? DEFAULT_TIMEOUT

    ajaxSuccess = (data, status, xhr, callback) ->
        if callback? 
            callback(data.r)

    ajaxStaticSuccess = (data, status, xhr, callback) ->
        if callback?
            callback(data)

    ajaxError = (status, xhr, callback) ->
        console.log(status,xhr)
        if callback? 
            callback(status)

    exports.getServer = ->
        server

    exports.setTimeout = (newTimeout) ->
        timeout = newTimeout

    exports.setServer = (newServer) ->
        server = newServer

    exports.setDefaults = () ->
        server  = DEFAULT_SERVER
        timeout = DEFAULT_TIMEOUT

    exports.doRequest = (inputData, successCallback, errorCallback, config) ->
        #console.log("ajax requ", inputData);
        urlExt  = DEFAULT_URL_EXTENSION 
        reqServer  = server
        reqTimeout = timeout
        reqJsonpCallback = null
        reqJsonpStatic   = false
        doPOST = false
        if config?
            if config.doPOST?
                doPOST = config.doPOST
            if config.urlExt?
                urlExt = config.urlExt
            if config.timeout?
                reqTimeout = config.timeout
            if config.server?
                reqServer = config.server
            if config.jsonpCallback?
                reqJsonpCallback  = config.jsonpCallback
            if config.jsonpStatic?
                reqJsonpStatic  = config.jsonpStatic
        url = reqServer + urlExt
        # jQuery 1.5 supports jsonp ajax fails provided a timeout is specified!
        # see http://www.haykranen.nl/2011/02/25/jquery-1-5-and-jsonp-requests/
        ajaxParams =
            url: url
            data: inputData
            success: (data, textStatus, xhr) ->
                ajaxSuccess(data, textStatus, xhr, successCallback)
            error: (xhr, textStatus, errorThrown) -> 
                ajaxError(textStatus, xhr, errorCallback)
            dataType: "jsonp"
            timeout: reqTimeout
        if doPOST
            ajaxParams.type = "POST"
            ajaxParams.crossDomain = true
            ajaxParams.dataType = "json"
        if reqJsonpCallback?
            ajaxParams.jsonpCallback = reqJsonpCallback
        if reqJsonpStatic
            ajaxParams.success = (data, textStatus, xhr) ->
                ajaxStaticSuccess(data, textStatus, xhr, successCallback)
        $.ajax(ajaxParams)

    return exports 
