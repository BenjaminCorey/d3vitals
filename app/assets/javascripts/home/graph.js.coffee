class Vital extends Backbone.Model
  initialize: ->
    @

class Vitals extends Backbone.Collection
  model: Vital
  patient_id: 109302775
  comparator: (model) ->
    model.get 'taken_at'
  getDateRange: ->
    @dateRange
  setDateRange: (range) ->
    @dateRange = range
    @trigger 'filter:date', @dateRange
    @
  initialize: ->
    @setDateRange null
  
  toJSON: ->
    vitals = @filter (v) -> return true unless v.get('systolic') is null or v.get('diastolic') is null
    _(vitals).map (v) -> {
      date      : new Date v.get 'taken_at'
      systolic  : v.get 'systolic'
      diastolic : v.get 'diastolic'
    }

  getRenderData: (range) ->
    data = @toJSON()
    if range
      data = _(data).filter (d) ->
        range[0] <= d.date <= range[1]
    return data
  # url: -> 'http://localhost:3000/vitals.js?patient_id=' + @patient_id
  # initialize: ->
  #   @fetch({dataType: 'jsonp'})

class VitalsTableView extends Backbone.View
  initialize: ->
    @collection.on 'add remove reset', @render
    @collection.on 'filter:date', @render
    @$el.append("<thead><th>Date</th><th>Systolic</th><th>Diastolic</th></thead><tbody></tbody>")
    @render()
    @

  render: (range) =>
    data = @collection.getRenderData(range)
    table = d3.select(@el)
      .select('tbody')
      .selectAll('tr.vital-data')
      .data(data)
    table.enter()
        .append('tr')
        .attr('class','vital-data')
        .html((d, i) -> "<td>#{d3.time.format('%x')(d.date)}</td><td>#{d.systolic}</td><td>#{d.diastolic}</td>")
    table.exit()
        .remove()

class VitalsGraphView extends Backbone.View

  initialize: (options) ->
    @height = options.height or 300
    @width = options.width or @$el.width()
    @padding = 30
    @svg = d3.select(@el).append('svg')
      .attr('height', @height)
      .attr('width', @width)
    @vis = @svg.append('g')
      .attr('class', 'vis')
      .attr('clip-path', 'url(#vis-mask)')
    @sysSeries = @vis.append('g')
    @diaSeries = @vis.append('g')
    @axes = @svg.append('g')
    @xAxis = @axes.append('g')
      .attr('class', 'axis x-axis')
      .attr('transform', "translate(0, #{(@height - @padding)})")
    @yAxis = @axes.append('g')
      .attr('class', 'axis y-axis')
      .attr('transform', "translate(#{@padding}, 0)")
    @svg.append('clipPath')
      .attr('id', 'vis-mask')
      .append('rect')
      .attr('x', @padding)
      .attr('height', @height - @padding)
      .attr('width', @width - @padding * 3)
    @collection.on 'add remove reset', @render
    @collection.on 'filter:date', @render
    @render()
    @

  getData: ->
    @collection.toJSON() # null values are filtered at the collection level

  render: (range) =>
    data = @collection.getRenderData(range)
    
    if range
      xMin = range[0]
      xMax = range[1]
    else
      xMin = d3.min data, (d) -> new Date d.date
      xMax = d3.max data, (d) -> new Date d.date

    xScaleProto = d3.time.scale()
      .domain([xMin, xMax])
      .range([@padding, @width - @padding * 2])

    window.xScale = d3.time.scale()
      .domain([xScaleProto.invert(20), xScaleProto.invert(@width - 50)])
      .range([@padding, @width - @padding * 2])

    yScale = d3.scale.linear()
      .domain([
        50,
        d3.max data, (d) -> d.systolic
      ])
      .range([@height - @padding, @padding])
      .nice()
      .clamp(true)

    _xAxis = d3.svg.axis()
      .scale(xScale)
      .orient('bottom')
      .ticks(5)
      .tickFormat d3.time.format '%x'

    _yAxis = d3.svg.axis()
      .scale(yScale)
      .orient('left')
      .ticks(10)

    @xAxis.call (_xAxis)
    @yAxis.call (_yAxis)

    sysArea = d3.svg.area()
      .x( (d) -> xScale d.date )
      .y0( @height - @padding )
      .y1( (d) -> yScale d.systolic )

    area1 = @sysSeries.selectAll('path')
      .data([data])

    area1.enter()
      .append('path')
      .attr('class', 'area1')
      .attr('fill', 'rgba(50,50,200,.1)')

    area1.attr('d', sysArea)

    area1.exit()
      .remove()

    diaArea = d3.svg.area()
      .x( (d) -> xScale d.date )
      .y0( @height - @padding )
      .y1( (d) -> yScale d.diastolic )

    @diaSeries.append('path')
      .data(data)
      .attr('d', diaArea(data))
      .attr('fill', 'rgba(50,50,200,.1)')

    sys = @sysSeries.selectAll('circle')
        .data(data)
    sys.enter()
        .append('circle')
        .attr('class', 'point')
        .attr('stroke', '#00DD99')
        .attr('stroke-width', 2)
        .attr('fill', 'white')
        .attr('opacity', .75)
        .attr('r', 5)

    sys.attr('cx', (d) -> xScale d.date )
      .attr('cy', (d) -> yScale d.systolic )

    sys.exit()
      .remove()


    dia = @diaSeries.selectAll('circle')
        .data(data)
    dia.enter()
        .append('circle')
        .attr('class', 'point')
        .attr('stroke-width', 2)
        .attr('fill', 'white')
        .attr('opacity', .75)
        .attr('stroke', '#DD0000')
        .attr('r', 5)

    dia.attr('cx', (d) -> xScale d.date )
        .attr('cy', (d) -> yScale d.diastolic )
    dia.exit()
      .remove()

class VitalsFilterView extends Backbone.View

  initialize: (options) ->
    @height = options.height or 100
    @width = options.width or @$el.width()
    @padding = 30
    @svg = d3.select(@el).append('svg')
      .attr('height', @height)
      .attr('width', @width)
      # .on('mousemove', (e) -> console.log d3.mouse(@))
    @vis = @svg.append('g').attr('class', 'vis')
    @sysSeries = @vis.append('g')
    @diaSeries = @vis.append('g')
    @axes = @svg.append('g')
    
    # @yAxis = @axes.append('g').attr('class', 'axis y-axis')
    #  .attr('transform', "translate(#{@padding}, 0)")

    @xAxis = @axes.append('g').attr('class', 'axis x-axis')
      .attr('transform', "translate(0, #{(@height - @padding)})")
    
    @brush = @svg.append('g').attr('class', 'brush')
      .attr('transform', "translate(0, #{@padding})")
    @collection.on 'add remove reset', @render
    @render()
    @

  getData: ->
    @collection.toJSON() # null values are filtered at the collection level

  render: ->
    data = @getData()
    
    xMin = d3.min data, (d) -> new Date d.date
    xMax = d3.max data, (d) -> new Date d.date

    xScale = d3.time.scale()
      .domain([xMin, xMax])
      .range([@padding, @width - @padding * 2])

    yScale = d3.scale.linear()
      .domain([
        50,
        d3.max data, (d) -> d.systolic
      ])
      .range([@height - @padding, @padding])
      .nice()
      .clamp(true)

    window.brush = d3.svg.brush()
      .x(xScale)
      .on 'brush', =>
        range = brush.extent()
        unless range[0] < range[1]
          range = null
        @collection.trigger 'filter:date', range

    _xAxis = d3.svg.axis()
      .scale(xScale)
      .orient('bottom')
      .ticks(5)
      .tickFormat d3.time.format '%x'

    # _yAxis = d3.svg.axis()
    #   .scale(yScale)
    #   .orient('left')
    #   .ticks(5)

    # @yAxis.call (_yAxis)
    @xAxis.call (_xAxis)
    @brush.call (brush)
    
    @brush.selectAll('rect')
      .attr('height', @height - @padding*2)

    @brush.selectAll('.resize')
      .append('path')
      .attr('d', @resizePath)

    sysLine = d3.svg.line()
      .x((d) ->
        # console.log "Plotting x value: #{d.date} at #{xScale(d.date)}"
        xScale d.date
      )
      .y((d) ->
        # console.log "Plotting x value: #{d.systolic} at #{yScale(d.systolic)}"
        yScale d.systolic
      )
      .interpolate('basis')
    diaLine = d3.svg.line()
      .x((d) -> xScale d.date )
      .y((d) -> yScale d.diastolic )
      .interpolate('basis')

    @sysSeries.append('path')
      .attr('d', sysLine(data))
      .attr('fill', 'none')
      .attr('stroke', 'black')
    
    @diaSeries.append('path')
      .attr('d', diaLine(data))
      .attr('fill', 'none')
      .attr('stroke', 'black')

    @sysSeries.selectAll('circle')
        .data(data)
        .enter()
        .append('circle')
        .attr('class', 'point')
        .attr('cx', (d) -> xScale d.date )
        .attr('cy', (d) -> yScale d.systolic )
        .attr('r', 2)
    @diaSeries.selectAll('circle')
        .data(data)
        .enter()
        .append('circle')
        .attr('class', 'point')
        .attr('cx', (d) -> xScale d.date )
        .attr('cy', (d) -> yScale d.diastolic )
        .attr('r', 2)

$ ->
  # cached sample data
  window.vitals = new Vitals [{"taken_at":"2012-08-26T17:39:02Z","pulse":73.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":114.0,"id":3790,"resp":null,"temperature":null,"fat":null,"diastolic":80.0},{"taken_at":"2012-08-26T17:37:15Z","pulse":67.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":123.0,"id":3791,"resp":null,"temperature":null,"fat":null,"diastolic":73.0},{"taken_at":"2012-08-26T17:35:23Z","pulse":65.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":133.0,"id":3792,"resp":null,"temperature":null,"fat":null,"diastolic":76.0},{"taken_at":"2012-08-26T07:31:35Z","pulse":77.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":133.0,"id":3761,"resp":null,"temperature":null,"fat":null,"diastolic":77.0},{"taken_at":"2012-08-25T16:43:44Z","pulse":68.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":126.0,"id":3728,"resp":null,"temperature":null,"fat":null,"diastolic":81.0},{"taken_at":"2012-08-24T15:59:54Z","pulse":74.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":133.0,"id":3517,"resp":null,"temperature":null,"fat":null,"diastolic":90.0},{"taken_at":"2012-08-24T15:58:20Z","pulse":76.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":136.0,"id":3518,"resp":null,"temperature":null,"fat":null,"diastolic":90.0},{"taken_at":"2012-08-24T15:53:13Z","pulse":76.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":144.0,"id":3519,"resp":null,"temperature":null,"fat":null,"diastolic":93.0},{"taken_at":"2012-08-24T06:44:06Z","pulse":84.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":128.0,"id":3471,"resp":null,"temperature":null,"fat":null,"diastolic":84.0},{"taken_at":"2012-08-23T15:59:12Z","pulse":77.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":130.0,"id":3022,"resp":null,"temperature":null,"fat":null,"diastolic":83.0},{"taken_at":"2012-08-22T15:28:42Z","pulse":71.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":121.0,"id":2806,"resp":null,"temperature":null,"fat":null,"diastolic":80.0},{"taken_at":"2012-08-22T15:26:15Z","pulse":70.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":122.0,"id":2807,"resp":null,"temperature":null,"fat":null,"diastolic":81.0},{"taken_at":"2012-08-22T15:23:31Z","pulse":70.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":133.0,"id":2808,"resp":null,"temperature":null,"fat":null,"diastolic":82.0},{"taken_at":"2012-08-22T06:47:22Z","pulse":87.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":137.0,"id":2747,"resp":null,"temperature":null,"fat":null,"diastolic":86.0},{"taken_at":"2012-08-21T16:04:37Z","pulse":null,"weight":216.825,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":null,"id":2512,"resp":null,"temperature":null,"fat":37.993,"diastolic":null},{"taken_at":"2012-08-21T15:48:34Z","pulse":65.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":125.0,"id":2513,"resp":null,"temperature":null,"fat":null,"diastolic":85.0},{"taken_at":"2012-08-21T06:19:28Z","pulse":81.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":122.0,"id":2438,"resp":null,"temperature":null,"fat":null,"diastolic":82.0},{"taken_at":"2012-08-21T06:17:45Z","pulse":78.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":123.0,"id":2439,"resp":null,"temperature":null,"fat":null,"diastolic":80.0},{"taken_at":"2012-08-21T06:16:02Z","pulse":69.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":123.0,"id":2440,"resp":null,"temperature":null,"fat":null,"diastolic":81.0},{"taken_at":"2012-08-20T15:30:37Z","pulse":null,"weight":218.147,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":null,"id":2167,"resp":null,"temperature":null,"fat":37.041,"diastolic":null},{"taken_at":"2012-08-20T15:05:52Z","pulse":73.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":120.0,"id":2168,"resp":null,"temperature":null,"fat":null,"diastolic":80.0},{"taken_at":"2012-08-20T15:03:41Z","pulse":71.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":126.0,"id":2169,"resp":null,"temperature":null,"fat":null,"diastolic":84.0},{"taken_at":"2012-08-20T15:00:34Z","pulse":73.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":130.0,"id":2170,"resp":null,"temperature":null,"fat":null,"diastolic":85.0},{"taken_at":"2012-08-20T05:55:57Z","pulse":82.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":121.0,"id":2118,"resp":null,"temperature":null,"fat":null,"diastolic":82.0},{"taken_at":"2012-08-20T05:54:18Z","pulse":80.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":140.0,"id":2119,"resp":null,"temperature":null,"fat":null,"diastolic":82.0},{"taken_at":"2012-08-20T05:52:33Z","pulse":84.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":129.0,"id":2120,"resp":null,"temperature":null,"fat":null,"diastolic":87.0},{"taken_at":"2012-08-19T17:09:29Z","pulse":70.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":129.0,"id":2004,"resp":null,"temperature":null,"fat":null,"diastolic":80.0},{"taken_at":"2012-08-19T17:07:48Z","pulse":73.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":128.0,"id":2005,"resp":null,"temperature":null,"fat":null,"diastolic":84.0},{"taken_at":"2012-08-19T17:06:07Z","pulse":72.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":128.0,"id":2006,"resp":null,"temperature":null,"fat":null,"diastolic":84.0},{"taken_at":"2012-08-19T05:44:54Z","pulse":80.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":120.0,"id":1881,"resp":null,"temperature":null,"fat":null,"diastolic":70.0},{"taken_at":"2012-08-19T05:43:09Z","pulse":77.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":121.0,"id":1882,"resp":null,"temperature":null,"fat":null,"diastolic":72.0},{"taken_at":"2012-08-19T05:41:28Z","pulse":83.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":122.0,"id":1883,"resp":null,"temperature":null,"fat":null,"diastolic":76.0},{"taken_at":"2012-08-18T15:19:54Z","pulse":72.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":119.0,"id":1854,"resp":null,"temperature":null,"fat":null,"diastolic":78.0},{"taken_at":"2012-08-18T15:18:12Z","pulse":67.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":118.0,"id":1855,"resp":null,"temperature":null,"fat":null,"diastolic":76.0},{"taken_at":"2012-08-18T15:16:31Z","pulse":71.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":122.0,"id":1856,"resp":null,"temperature":null,"fat":null,"diastolic":81.0},{"taken_at":"2012-08-18T06:07:28Z","pulse":76.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":136.0,"id":1844,"resp":null,"temperature":null,"fat":null,"diastolic":81.0},{"taken_at":"2012-08-18T01:03:14Z","pulse":89.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":138.0,"id":1845,"resp":null,"temperature":null,"fat":null,"diastolic":90.0},{"taken_at":"2012-08-18T00:55:12Z","pulse":90.0,"weight":null,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":141.0,"id":1846,"resp":null,"temperature":null,"fat":null,"diastolic":84.0},{"taken_at":"2012-08-17T16:06:26Z","pulse":null,"weight":216.163,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":null,"id":1735,"resp":null,"temperature":null,"fat":37.302,"diastolic":null},{"taken_at":"2012-08-16T16:03:05Z","pulse":null,"weight":215.612,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":null,"id":1423,"resp":null,"temperature":null,"fat":38.586,"diastolic":null},{"taken_at":"2012-08-14T15:23:40Z","pulse":null,"weight":215.722,"is_active":true,"internal_user_id":null,"comments":null,"withings":true,"patient_id":109302775,"height":null,"systolic":null,"id":1424,"resp":null,"temperature":null,"fat":38.093,"diastolic":null},{"taken_at":"2012-08-13T21:27:20Z","pulse":80.0,"weight":220.0,"is_active":true,"internal_user_id":1000202,"comments":"","withings":false,"patient_id":109302775,"height":66.0,"systolic":132.0,"id":994,"resp":10,"temperature":null,"fat":null,"diastolic":64.0}]

  window.graphView = new VitalsGraphView
    collection: vitals
    el: $('#stage').append("<div id='vitals-graph' />").children('#vitals-graph')

  window.filterView = new VitalsFilterView
    collection: vitals
    el: $('#stage').append("<div id='vitals-filter' />").children('#vitals-filter')

  window.tableView = new VitalsTableView
    collection: vitals
    el: $('#stage').append('<table id="vitals-table" class="table table-striped"></table>').children('#vitals-table')

###
# Taken from crossfilter
resizePath = (d) ->
  e = +(d == 'e')
  x = if e then 1 else -1
  y = (h - 30 * 2) / 3
  """
  M#{(.5 * x)}, #{y}
  A6,6 0 0 #{e} #{(6.5 * x)}, #{(y + 6)}
  V#{(2 * y - 6)}
  A6,6 0 0 #{e} #{(.5 * x)},#{(2 * y)}
  Z
  M#{(2.5 * x)},#{(y + 8)}
  V#{(2 * y - 8)}
  M#{(4.5 * x)},#{(y + 8)}
  V#{(2 * y - 8)}
  """





