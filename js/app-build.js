({
    baseUrl: ".",
    paths: {
        "jquery": "lib/jquery",
        "jquery.mousewheel": "lib/jquery.mousewheel",
        "jquery.autocomplete": "lib/jquery-ui-autocomplete.min",
        "jquery.autocomplete.html": "lib/jquery-ui-autocomplete.html",
        "requireLib": "lib/require"
    },
    name: "app/config",
    include: "requireLib",
    out: "app-build/pscp.js"
})
