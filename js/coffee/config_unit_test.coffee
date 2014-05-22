requirejs.config
    baseUrl: 'js'
    paths:
        'jquery': "lib/jquery-1.8.3.min"
        'jquery.mousewheel': "lib/jquery.mousewheel"
        'QUnit': 'lib/qunit-1.11.0'
    shim: 
        "jquery.mousewheel": 
            deps: ["jquery"]
            exports: "jQuery.mousewheel"
        'QUnit': 
            exports: 'QUnit'
            init: ->
                QUnit.config.autoload = false
                QUnit.config.autostart = false


# require the unit tests.
requirejs [
    'QUnit'
    'tests/Vec2D_test'
    'tests/ajax_test'
    'tests/world_test'
    'tests/mapview_test'
], (QUNIT, VEC2D_TEST, AJAX_TEST, WORLD_TEST, MAPVIEW_TEST) ->
            
    # run the tests:
    VEC2D_TEST.run()
    AJAX_TEST.run()
    WORLD_TEST.run()
    MAPVIEW_TEST.run()

    # start QUnit:
    QUNIT.load()
    QUNIT.start()
