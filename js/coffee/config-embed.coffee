requirejs.config
    baseUrl: 'js'
    paths:
        'jquery': "lib/jquery-3.1.1"
        'jquery.mousewheel': "lib/jquery.mousewheel"
        'jquery.autocomplete': "lib/jquery-ui-autocomplete.min"
        'jquery.autocomplete.html': "lib/jquery-ui-autocomplete.html"
    shim:
        "jquery.mousewheel":
            deps: ["jquery"]
        "jquery.autocomplete":
            deps: ["jquery"]
        "jquery.autocomplete.html":
            deps: ["jquery","jquery.autocomplete"]

requirejs ['app/main-embed']
