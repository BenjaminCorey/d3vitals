class D3Vitals.Routers.Vitals extends Backbone.Router
  routes:
    '': 'home'
    'vitals': 'vitals'
  home: ->
    console.log 'home route triggered'
  vitals: ->
    window.vitals = new D3Vitals.Collections.Vitals $('.stage').data('vitals')
    window.vitalsGraph = new D3Vitals.Views.VitalsGraph
      el           : $ '.stage'
      collection   : window.vitals
    window.vitalsView = new D3Vitals.Views.VitalsIndex
      el         : $ '.stage' 
      collection : window.vitals