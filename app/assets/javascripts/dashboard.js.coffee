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

  $(document.body).on 'keyup', '#transfer_form input[name=amount_usd], #transfer_form input[name=amount_btc]', (event) ->
    exchange_rate = parseFloat($('#transfer_form input[name=exchange_rate]').val())
    usd_to_btc = ($(this).attr('name') == 'amount_usd')
    currency = if usd_to_btc then "USD" else "BTC"
    $("#currency").val(currency)
    rate = (if usd_to_btc then (1.0 / exchange_rate) else exchange_rate)
    other = $(this).parent().parent().find('input[name!=' + $(this).attr('name') + ']').first()
    console.log $('#transfer_form input[name=amount_usd], #transfer_form input[name=amount_btc]').remove($(this))
    other.val(parseFloat($(this).val()) * rate)

  $("#transaction-history").load($("#transaction-history").attr('data-load'))

$(document).ready(ready)
$(document).on('page:load', ready)