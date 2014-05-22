define ['app/ajax'], (AJAX) ->
    run : ->
        module "AJAX"

        testServer = "http://pscp.robjk.net"
        failServer = "http://pscp.robjk.net:6666"

        test "GET callback: success", ->
            stop()
            AJAX.setServer(testServer)
            inputData =
                test: true
            testCallback = (data) ->
                equal data.test, "success", 
                    "Test property set to success"
                equal data.POST, false, 
                    "POST data set to false"
                start()
            errorCallback = (status) ->
                ok false, 
                    "Callback error: " + status
                start()
            AJAX.doRequest(inputData, testCallback, errorCallback)

        test "POST callback: success", ->
            stop()
            AJAX.setServer(testServer)
            inputData =
                test: true
            config =
                doPOST: true
            testCallback = (data) ->
                equal data.test, "success", 
                    "Test property set to success"
                equal data.POST, true, 
                    "POST data set to true"
                start()
            errorCallback = (status) ->
                ok false, 
                    "Callback error: " + status
                start()
            AJAX.doRequest(inputData, testCallback, errorCallback, config)

        asyncTest "Callback: error", ->
            AJAX.setServer(failServer)
            expect(1)
            inputData =
                test: true
            config = 
                timeout: 1
            testCallback = (status) ->
                equal status, "timeout",
                    "Status set to timeout"
                start()
            AJAX.doRequest(inputData, null, testCallback, config)
