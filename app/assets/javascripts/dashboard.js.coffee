# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
ready = ->
  for i in [1..3]
    $("div[data-load]").filter("[data-load-order=" + i + "]").filter("[data-loaded!=true]").filter(":visible").each ->
      path = $(this).attr('data-load')
      $(this).attr('data-loaded', true)
      # passes the query string to sub-modules for fields pre-filling
      $.ajax({
        url: path + '?' + window.location.search.substring(1),
        dataType: 'html',
        success: (data) =>
          $(this).html(data)
          FB.XFBML.parse()
      })

$(document).ready(ready)
$(document).on('page:load', ready)