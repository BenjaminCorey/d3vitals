class D3Vitals.Views.VitalsGraph extends Backbone.View
  template: JST['vitals/graph']
  events:
    'click button': 'handleClick'
  initialize: =>
    @$el.append @template()
    @margin =
      top    : 20
      right  : 20
      bottom : 30
      left   : 40

    @width  = @$el.width() - @margin.left - @margin.right
    @height = 500 - @margin.top - @margin.bottom

    @x = d3.time.scale()
      .range [0, @width]

    @y = d3.scale.linear()
      .range [@height, 0]
    @color = d3.scale.category10()

    @xAxis = d3.svg.axis()
      .scale(@x)
      .orient('bottom')
    @yAxis = d3.svg.axis()
      .scale(@y)
      .orient('left')

    @svg = d3.select(@$('svg')[0])
      .attr 'height', 500

    @vis = @svg.select('.vis')
      .attr('transform', "translate(#{@margin.left},#{@margin.top})")

    @data = @getData()

    dataMap = d3.nest().key( (d) -> d.key ).entries(@data)

    $buttons = @$('.btn-group')
    
    for group in dataMap
      $buttons.append "<button class='btn' data-target='#{group.key}'>#{group.key}</button>"

    @$('[data-target="Systolic"]').addClass 'active'
    @render 'Systolic'

  parseDate: d3.time.format('%Y-%m-%dT%H:%M:%S').parse

  getData: =>
    data = @collection.toJSON()

    data.forEach (vital) =>
      vital.taken_at = @parseDate vital.taken_at

    return data


  handleClick: (e) =>
    key = $(e.target).data('target')
    @unrender(key)


  unrender: (key) ->
    d3.selectAll('.dot')
      .remove()

    d3.selectAll('.axis')
      .remove()

    @render( key )

  render: (key) =>

    data = @data.filter((d) -> d.key == "#{key}")

    @x.domain(d3.extent(data, (d) -> d.taken_at)).nice(d3.time.hour)
    @y.domain(d3.extent(data, (d) -> d.value)).nice()

    @axes = d3.select(@$('.axes')[0])
      .attr('transform', "translate(#{@margin.left},#{@margin.top})")

    @axes.append('g')
      .attr('class', 'x-axis axis')
      .attr('transform', "translate(0, #{@height})")
      .call(@xAxis)
      .append('text')
      .attr('class', 'label')
      .attr('x', @width - @margin.right)
      .attr('y', -6)
      .style('text-anchor', 'end')
      .text('Date')

    @axes.append('g')
      .attr('class', 'y-axis axis')
      .call(@yAxis)
      .append('text')
      .attr('class', 'label')
      .attr('transform', 'rotate(-90)')
      .attr('y', 6)
      .attr('dy', '.71em')
      .attr('text-anchor', 'end')
      .text("#{key}")

    @vis.selectAll('.dot')
      .data(data, (d) -> d.taken_at)
      .enter()
      .append('circle')
      .attr('class', 'dot')
      .attr('r', 0)
      .attr('cx', (d) => @x d.taken_at )
      .attr('cy', (d) => @y d.value )
      .style('stroke', (d) => @color "#{key}")
      .style('fill', (d) => @color "#{key}")
      .style('fill-opacity', .5)
      .transition()
      .attr('r', 5)


