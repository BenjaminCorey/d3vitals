class D3Vitals.Views.VitalsIndex extends Backbone.View

  template: JST['vitals/index']

  initialize: ->
    @$el.append @template
      formatDate: d3.time.format '%x'
      vitals: @collection.toJSON()
    @render()

  render: =>
    @