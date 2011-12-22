$ = @jQuery

class NanoScroll

  constructor: (@el, options) ->
    ### Probably not necessarry to define this for filesize reasons
    @slider   = null
    @pane     = null
    @content  = null
    @scrollH  = 0
    @sliderH  = 0
    @paneH    = 0
    @sliderY  = 0
    @offsetY  = 0
    @contentH = 0
    @contentY = 0
    @isDrag   = false
    ###

    options or= {}
    @generate()
    @createEvents()
    @addEvents()
    @reset()
    return
  
  createEvents: ->
    ## filesize reasons
    mousemove = 'mousemove'
    mouseup   = 'mouseup'
    @events =
      down: (e) =>
        @isDrag  = true
        @offsetY = e.clientY - @slider.offset().top
        @pane.addClass 'active'
        $(document).bind mousemove, @events.drag
        $(document).bind mouseup, 	@events.up
        false

      drag: (e) =>
        @sliderY = e.clientY - @el.offset().top - @offsetY
        @scroll()
        false

      up: (e) =>
        @isDrag = false
        @pane.removeClass 'active'
        $(document).unbind mousemove, @events.drag
        $(document).unbind mouseup, 	@events.up
        false

      resize: (e) =>
        @reset()
        #@scroll()

      panedown: (e) =>
        @sliderY = e.clientY - @el.offset().top - @sliderH * .5
        @scroll()
        @events.down e

      scroll: (e) =>
        return if @isDrag is true
        top = @content[0].scrollTop / (@content[0].scrollHeight - @content[0].clientHeight) * (@paneH - @sliderH)
        @slider.css top: top + 'px'

      wheel: (e) =>
        @sliderY +=  -e.wheelDeltaY || -e.delta
        @scroll()
        return false


  addEvents: ->
    $(window).bind 'resize'  , @events.resize
    @slider.bind 'mousedown' , @events.down
    @pane.bind 'mousedown'   , @events.panedown
    @content.bind 'scroll'   , @events.scroll

    if window.addEventListener
      @pane[0].addEventListener 'mousewheel'     , @events.wheel
      @pane[0].addEventListener 'DOMMouseScroll' , @events.wheel

  removeEvents: ->
    $(window).unbind 'resize'  , @events.resize
    @slider.unbind 'mousedown' , @events.down
    @pane.unbind 'mousedown'   , @events.panedown
    @content.unbind 'scroll'   , @events.scroll

    if window.addEventListener
      @pane[0].removeEventListener 'mousewheel'     , @events.wheel
      @pane[0].removeEventListener 'DOMMouseScroll' , @events.wheel

  getScrollbarWidth: ->
    outer                = document.createElement 'div'
    outer.style.position = 'absolute'
    outer.style.width    = '100px'
    outer.style.height   = '100px'
    outer.style.overflow = 'scroll'
    document.body.appendChild outer
    noscrollWidth  = outer.offsetWidth
    yesscrollWidth = outer.scrollWidth
    document.body.removeChild outer
    noscrollWidth - yesscrollWidth

    
  generate: ->
    @el.append '<div class="pane"><div class="slider"></div></div>'
    @content = $ @el.children()[0]
    @slider  = @el.find '.slider'
    @pane    = @el.find '.pane'
    @scrollW = @getScrollbarWidth()
    @scrollW = 0 if @scrollbarWidth is 0
    @content.css
      right  : -@scrollW + 'px'

    # scumbag IE7
    if $.browser.msie?
      @pane.hide() if parseInt($.browser.version) < 8
    return

  reset: ->
    if @isDead is true
      @isDead = false
      @pane.show()
      @addEvents()

    @contentH  = @content[0].scrollHeight + @scrollW
    @paneH     = @pane.outerHeight()
    @sliderH   = @paneH / @contentH * @paneH
    @sliderH   = Math.round @sliderH
    @scrollH   = @paneH - @sliderH
    @slider.height 	@sliderH

    if @paneH >= @content[0].scrollHeight
      @pane.hide()
    else
      @pane.show()
    return

  scroll: ->
    @sliderY    = Math.max 0, @sliderY
    @sliderY    = Math.min @scrollH, @sliderY
    scrollValue = @paneH - @contentH + @scrollW
    scrollValue = scrollValue * @sliderY / @scrollH
    # scrollvalue = (paneh - ch + sw) * sy / sw
    @content.scrollTop -scrollValue
    @slider.css top: @sliderY

  scrollBottom: (offsetY) ->
    @reset()
    @content.scrollTop @contentH - @content.height() - offsetY
    return

  scrollTop: (offsetY) ->
    @reset()
    @content.scrollTop offsetY + 0
    return
  
  stop: ->
    @isDead = true
    @removeEvents()
    @pane.hide()
    return

  
$.fn.nanoScroller = (options) ->
  options or= {}
  scrollbar = @data 'scrollbar'
  if scrollbar is undefined
    scrollbar = new NanoScroll this, options
    @data 'scrollbar': scrollbar
    return

  return scrollbar.scrollBottom(options.scrollBottom) if options.scrollBottom
  return scrollbar.scrollTop(options.scrollTop)       if options.scrollTop
  return scrollbar.scrollBottom(0)                    if options.scroll is 'bottom'
  return scrollbar.scrollTop(0)                       if options.scroll is 'top'
  return scrollbar.stop()                             if options.stop   is true
  return scrollbar.reset()
