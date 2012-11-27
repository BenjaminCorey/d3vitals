window.D3Vitals =
  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  initialize: ->
    window.app = new D3Vitals.Routers.Vitals()
    Backbone.history.start( pushState: true )

$(document).ready ->
  D3Vitals.initialize()
