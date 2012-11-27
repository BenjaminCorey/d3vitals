class D3Vitals.Collections.Vitals extends Backbone.Collection

  comparator: (model) ->
    model.get('taken_at')
  model: D3Vitals.Models.Vital
  url: '/vitals'