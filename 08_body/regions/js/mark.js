(function() {
  var Mark;

  Mark = (function() {
    function Mark(options) {
      var defaults = {
        debug: true
      };
      this.options = $.extend(defaults, options);
      this.init();
    }

    Mark.prototype.init = function(){
      var _this = this;

      this.$asset = $('#body');
      this.data_loaded = new $.Deferred();

      $.when(this.data_loaded).done(function() {
        _this.loadListeners();
      });

      this.loadData();
    };

    Mark.prototype.activateRegion = function(id){
      $('.region').removeClass('active');
      $('.region[data-id="'+id+'"]').addClass('active');
      $('.region-link').removeClass('active');
      $('.region-link[data-id="'+id+'"]').addClass('active');
    };

    Mark.prototype.addRegion = function(id, active, styles){
      var _this = this,
          $region = $('<div class="region" data-id="'+id+'"></div>');

      // add styles
      if (styles) {
        $region.css(styles);
      }

      // add region to ui
      this.$asset.append($region);

      // activate and update button text
      if (active) {
        this.activateRegion(id);
      }

      // make it draggable
      $region.draggable({
        start: function(e){
          e.stopPropagation();
          _this.activateRegion(id);
        },
        drag: function(e){ e.stopPropagation(); },
        stop: function(e){
          e.stopPropagation();
          _this.submit();
        }

      // make it resizable
      }).resizable({
        start: function(e){
          e.stopPropagation();
          _this.activateRegion(id);
        },
        resize: function(e){ e.stopPropagation(); },
        stop: function(e){
          e.stopPropagation();
          _this.submit();
        }
      });

      // click on region, make active
      $region.on('click', function(e){
        e.preventDefault();
        _this.activateRegion(id);
      });

      return $region;
    };

    Mark.prototype.addRegionLink = function(region, active){
      var _this = this,
          $li = $('<li>'),
          $a = $('<a href="#" class="region-link" data-id="'+region.id+'>'+region.id+'</a>');

      if (active) $a.addClass('active');

      $a.on('click', function(e){
        e.preventDefault();
        _this.activateRegion(region.id);
      });

      $li.append($a);
      $('#region-list').append($li);
    };

    Mark.prototype.getRegionData = function($region){
      $region = $region || $('.region.active').first();

      var $asset = this.$asset,
          assetW = $asset.width(),
          assetH = $asset.height(),
          left = $region.offset().left - $asset.offset().left,
          top = $region.offset().top - $asset.offset().top,
          multiplier = 100,
          x = parseFloat(left/assetW) * multiplier,
          y = parseFloat(top/assetH) * multiplier,
          w = parseFloat($region.width()/assetW) * multiplier,
          h = parseFloat($region.height()/assetH) * multiplier;

      return {x:x, y:y, w:w, h:h};
    };

    Mark.prototype.loadData = function(){
      var _this = this;

      this.regions = [];

      $.ajax({
        dataType: "json",
        url: '../data/regions.json',
        success: function(data) {
          $.each(data, function(i, region){
            _this.regions.push(region);
            _this.addRegionLink(region, i===0);
            if (region.w > 0 && region.h > 0) {
              _this.addRegion(region.id, false, {
                top: region.y + '%',
                left: region.x + '%',
                width: region.w + '%',
                height: region.h + '%'
              });
            }
          });
          _this.data_loaded.resolve();
          _this.options.debug && console.log('Loaded '+data.length+' regions');
        }
      });
    };

    Mark.prototype.loadListeners = function(){
      var _this = this;

      var $asset = this.$asset,
          assetX = 0, assetY = 0, assetW = 0, assetH = 0,
          startX = 0, startY = 0,
          regionValue = {x: 0, y:0, w:0, h:0};

      // Starting to drag rectangle, remember start values
      $asset.hammer().bind('panstart', function(e) {
        e.stopPropagation();
        $('.region.active').remove();
        assetX = $asset.offset().left;
        assetY = $asset.offset().top;
        assetW = $asset.width();
        assetH = $asset.height();
        var eventX = e.gesture.center.x,
            eventY = e.gesture.center.y,
            offsetX = eventX - assetX,
            offsetY = eventY - assetY,
            id = $('.region-link.active').first().attr('data-id');
        startX = offsetX;
        startY = offsetY;

        // add region
        _this.addRegion(id, true);
      });

      // Dragging rectangle, update rectangle
      $asset.hammer().bind('panmove', function(e) {
        var eventX = e.gesture.center.x,
            eventY = e.gesture.center.y,
            offsetX = eventX - assetX,
            offsetY = eventY - assetY,
            width = Math.abs(offsetX-startX),
            height = Math.abs(offsetY-startY),
            left = (offsetX - startX < 0) ? offsetX : startX,
            top = (offsetY - startY < 0) ? offsetY : startY,
            $region = $('.region.active').first();

        // update rectangle css
        $region.css({
          width: width+'px',
          height: height+'px',
          left: left+'px',
          top: top+'px'
        });
      });

      // Stopped dragging rectangle: submit coordinates/dimensions
      $asset.hammer().bind('panend', function(e) {
        var regionValue = _this.getRegionData(),
            $region = $('.region.active').first();

        // update rectangle css
        $region.css({
          width: regionValue.w+'%',
          height: regionValue.h+'%',
          left: regionValue.x+'%',
          top: regionValue.y+'%'
        });
      });

    };

    Mark.prototype.submit = function(){
      var _this = this;

      $.each(this.regions, function(i, region){
        var positionData = _this.getRegionData($('.region[data-id="'+region.id+'"]'));
        $.extend(_this.regions[i], positionData);
      });

      $('#output').val(JSON.stringify(this.regions));
    };

    return Mark;

  })();

  $(function() {
    return new Mark({});
  });

}).call(this);
