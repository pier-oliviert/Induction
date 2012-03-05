(function() {
  var DataPoint, Dimensions, Measure, Measures, Series, _Dimension,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  window.Chart = (function(_super) {

    __extends(Chart, _super);

    function Chart() {
      Chart.__super__.constructor.apply(this, arguments);
    }

    Chart.prototype.parse = function(json) {
      var m, value;
      this.set("dimension", Dimension((function() {
        var _i, _len, _ref, _results;
        _ref = json.values;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          value = _ref[_i];
          _results.push(value[json.dimension]);
        }
        return _results;
      })()));
      return this.set("measures", new Measures((function() {
        var _i, _len, _ref, _results;
        _ref = json.measures;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          m = _ref[_i];
          _results.push(new Measure((function() {
            var _j, _len2, _ref2, _results2;
            _ref2 = json.values;
            _results2 = [];
            for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
              value = _ref2[_j];
              _results2.push(value[m]);
            }
            return _results2;
          })()));
        }
        return _results;
      })()));
    };

    Chart.prototype.series = function() {
      var measure, value, _i, _len, _ref, _results;
      _ref = this.get("measures").models;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        measure = _ref[_i];
        _results.push(new Series((function() {
          var _j, _len2, _ref2, _results2;
          _ref2 = _.zip(this.get("dimension").values, measure.values);
          _results2 = [];
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            value = _ref2[_j];
            _results2.push({
              x: value[0],
              y: value[1]
            });
          }
          return _results2;
        }).call(this)));
      }
      return _results;
    };

    return Chart;

  })(Backbone.Model);

  Measure = (function(_super) {

    __extends(Measure, _super);

    function Measure() {
      Measure.__super__.constructor.apply(this, arguments);
    }

    Measure.prototype.initialize = function(values) {
      this.values = values;
      return this.domain = [_.min(this.values), _.max(this.values)];
    };

    return Measure;

  })(Backbone.Model);

  Measures = (function(_super) {

    __extends(Measures, _super);

    function Measures() {
      Measures.__super__.constructor.apply(this, arguments);
    }

    Measures.prototype.initialize = function(measures) {
      return this.models = measures;
    };

    Measures.prototype.scale = function() {
      var extrema, measure;
      extrema = _.flatten((function() {
        var _i, _len, _ref, _results;
        _ref = this.models;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          measure = _ref[_i];
          _results.push(measure.domain);
        }
        return _results;
      }).call(this));
      return d3.scale.linear().domain([_.min(extrema), _.max(extrema)]);
    };

    return Measures;

  })(Backbone.Collection);

  window.Dimension = function(values) {
    var value;
    value = values[0];
    if (_.isString(value) && d3.time.format("%Y/%m/%d").parse(value)) {
      return new Dimensions.Temporal(values);
    } else if (Number(value)) {
      return new Dimensions.Numeric(values);
    } else {
      return new Dimensions.Ordinal(values);
    }
  };

  _Dimension = (function(_super) {

    __extends(_Dimension, _super);

    function _Dimension() {
      _Dimension.__super__.constructor.apply(this, arguments);
    }

    _Dimension.prototype.initialize = function(values) {
      this.values = values;
      return this.domain = [d3.min(this.values), d3.max(this.values)];
    };

    _Dimension.prototype.scale = function() {
      return d3.scale.linear().domain(this.domain);
    };

    return _Dimension;

  })(Backbone.Model);

  Dimensions = {};

  Dimensions.Numeric = (function(_super) {

    __extends(Numeric, _super);

    function Numeric() {
      Numeric.__super__.constructor.apply(this, arguments);
    }

    return Numeric;

  })(_Dimension);

  Dimensions.Temporal = (function(_super) {

    __extends(Temporal, _super);

    function Temporal() {
      Temporal.__super__.constructor.apply(this, arguments);
    }

    Temporal.prototype.initialize = function(values) {
      var value;
      this.format = d3.time.format("%Y/%m/%d");
      return Temporal.__super__.initialize.call(this, (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = values.length; _i < _len; _i++) {
          value = values[_i];
          _results.push(this.format.parse(value));
        }
        return _results;
      }).call(this));
    };

    Temporal.prototype.scale = function() {
      return d3.scale.linear().domain(this.domain);
    };

    return Temporal;

  })(_Dimension);

  Dimensions.Ordinal = (function(_super) {

    __extends(Ordinal, _super);

    function Ordinal() {
      Ordinal.__super__.constructor.apply(this, arguments);
    }

    return Ordinal;

  })(_Dimension);

  DataPoint = (function(_super) {

    __extends(DataPoint, _super);

    function DataPoint() {
      DataPoint.__super__.constructor.apply(this, arguments);
    }

    DataPoint.prototype.initialize = function(point) {
      this.x = point.x;
      return this.y = point.y;
    };

    return DataPoint;

  })(Backbone.Model);

  Series = (function(_super) {

    __extends(Series, _super);

    function Series() {
      Series.__super__.constructor.apply(this, arguments);
    }

    Series.prototype.model = DataPoint;

    return Series;

  })(Backbone.Collection);

  window.ChartView = (function(_super) {

    __extends(ChartView, _super);

    function ChartView() {
      ChartView.__super__.constructor.apply(this, arguments);
    }

    ChartView.prototype.initialize = function(chart, settings) {
      this.chart = chart;
      if (settings == null) settings = {};
      _.bindAll(this);
      this.width = settings.w || 800;
      this.height = settings.h || 400;
      return this.margins = settings.m || [30, 30, 30, 30];
    };

    ChartView.prototype.render = function() {
      return d3.select("body").append("svg:svg").attr("width", this.width).attr("height", this.height);
    };

    return ChartView;

  })(Backbone.View);

  window.Charts = {};

  window.Charts.ScatterplotChartView = (function(_super) {

    __extends(ScatterplotChartView, _super);

    function ScatterplotChartView() {
      ScatterplotChartView.__super__.constructor.apply(this, arguments);
    }

    ScatterplotChartView.prototype.render = function() {
      var fill, layers, svg, xAxis, xScale, yAxis, yScale;
      ScatterplotChartView.__super__.render.apply(this, arguments);
      fill = d3.scale.category10();
      xScale = this.chart.get("dimension").scale().range([this.margins[0], this.width - this.margins[2]]);
      yScale = this.chart.get("measures").scale().range([this.height - this.margins[3], this.margins[1]]);
      xAxis = d3.svg.axis().scale(xScale).orient("bottom").tickSize(-this.height).tickSubdivide(false);
      yAxis = d3.svg.axis().scale(yScale).orient("left").tickSize(-this.width, 0, 0).ticks(4);
      svg = d3.select("svg");
      svg.append("g").attr("class", "x axis").attr("transform", "translate(0," + this.height + ")").call(xAxis);
      svg.append("g").attr("class", "y axis").attr("transform", "translate(" + (this.margins[0] - 5) + ", 0)").call(yAxis);
      layers = svg.selectAll("g.layer").data(this.chart.series()).enter().append("g").attr("class", "layer").style("fill", function(d, i) {
        return fill(i);
      });
      return layers.selectAll("path").data(function(d) {
        return d.models;
      }).enter().append("circle").attr("cx", function(p) {
        return xScale(p.x);
      }).attr("cy", function(p) {
        return yScale(p.y);
      }).attr("r", 5);
    };

    return ScatterplotChartView;

  })(window.ChartView);

  window.Charts.DonutChartView = (function(_super) {

    __extends(DonutChartView, _super);

    function DonutChartView() {
      DonutChartView.__super__.constructor.apply(this, arguments);
    }

    DonutChartView.prototype.render = function() {
      var arc, arcs, fill, pie, r, svg;
      DonutChartView.__super__.render.apply(this, arguments);
      fill = d3.scale.category10();
      r = _.min([this.width, this.height]) / 2;
      svg = d3.select("svg").data([this.chart.series()[0].models]).append("svg:g").attr("transform", "translate(" + r + "," + r + ")");
      pie = d3.layout.pie().value(function(p) {
        return p.y;
      });
      arc = d3.svg.arc().innerRadius(r / 2).outerRadius(r);
      arcs = svg.selectAll("g.slice").data(pie).enter().append("svg:g").attr("class", "slice");
      arcs.append("svg:path").style("fill", function(d, i) {
        return fill(i);
      }).attr("d", arc);
      return arcs.append("svg:text").attr("transform", function(d, i) {}, d.innerRadius = r / 2, d.outerRadius = r, "translate(" + arc.centroid(d) + ")").attr("text-anchor", "middle");
    };

    return DonutChartView;

  })(window.ChartView);

  window.Charts.LineChartView = (function(_super) {

    __extends(LineChartView, _super);

    function LineChartView() {
      LineChartView.__super__.constructor.apply(this, arguments);
    }

    LineChartView.prototype.render = function() {
      var fill, layers, line, svg, xAxis, xScale, yAxis, yScale;
      LineChartView.__super__.render.apply(this, arguments);
      svg = d3.select("svg").data(this.chart.series()).append("svg:g");
      fill = d3.scale.category10();
      xScale = this.chart.get("dimension").scale().range([this.margins[0], this.width - this.margins[2]]);
      yScale = this.chart.get("measures").scale().range([this.height - this.margins[3], this.margins[1]]);
      xAxis = d3.svg.axis().scale(xScale).orient("bottom").tickSize(-this.height).tickSubdivide(false);
      yAxis = d3.svg.axis().scale(yScale).orient("left").tickSize(-this.width, 0, 0).ticks(4);
      svg.append("g").attr("class", "x axis").attr("transform", "translate(0," + this.height + ")").call(xAxis);
      svg.append("g").attr("class", "y axis").attr("transform", "translate(" + (this.margins[0] - 5) + ", 0)").call(yAxis);
      line = d3.svg.line().x(function(d) {
        return xScale(d.x);
      }).y(function(d) {
        return yScale(d.y);
      });
      layers = svg.selectAll("g.layer").data(this.chart.series()).enter().append("g").attr("class", "layer");
      layers.style("stroke", function(d, i) {
        return fill(i);
      });
      return layers.selectAll("path").data(function(d) {
        return [d];
      }).enter().append("path").attr("d", function(d) {
        return line(d.models);
      });
    };

    return LineChartView;

  })(window.ChartView);

}).call(this);
