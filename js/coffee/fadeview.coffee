# FADEVIEW module
#
# Popup that displays information about the current WORLD.
# Fades out view when user zooms in.

define ['app/world','jquery'], (WORLD,$) ->

    exports = {}

    # for key-popup state; could be moved to its own module
    welcomePopupVisible = false

    ###########################################################################
    # Public (exports)
    ###########################################################################

    exports.show = ->
        if not welcomePopupVisible
            numPapers = "" + WORLD.getNumberArxivPapers()
            if numPapers.length > 6
                numPapers = numPapers[0...-6] + "," + numPapers[-6..]
            if numPapers.length > 3
                numPapers = numPapers[0...-3] + "," + numPapers[-3..]
            lastDownloadDate = WORLD.getLastDownloadDate()
            $("#welcomePopup .total").html(numPapers)
            #$("#welcomePopup .update").html(lastDownloadDate)
            $("#welcomePopup").stop().fadeIn()
            welcomePopupVisible = true

    exports.hide = ->
        if welcomePopupVisible
            $("#welcomePopup").stop().fadeOut()
            welcomePopupVisible = false

    return exports
