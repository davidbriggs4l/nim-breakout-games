import sdl2
import ./constants

type
  Target = ref object
    x, y: float32
    is_dead*: bool

# Game state
var
  quitGame = false
  ev = sdl2.defaultEvent
  # ball_pos = Point(x: 100, y: 100)
  # ball_velocity = Point(x: 1, y: 1)
  
  bar_x:  float32 = WINDOW_WIDTH / 2 - BAR_LENGTH / 2
  # ball position start
  ball_x:      float32 = WINDOW_WIDTH / 2 - BALL_SIZE / 2
  ball_y:      float32 = BAR_Y - BAR_THICKNESS / 2 - BALL_SIZE
  # ball position end
  dx:     float32 = 1
  dy:     float32 = 1
  bar_dx: float32 = 0
  state = getKeyboardState(nil)
  pause = false
  started = false
  targets_pool: seq[Target] = @[
    Target(x: 100, y: 100, is_dead: false),
    Target(x: 100 + TARGET_WIDTH + TARGET_PADDING, y: 100, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 2, y: 100, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 3, y: 100, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 4, y: 100, is_dead: false),

    Target(x: 100, y: 150, is_dead: false),
    Target(x: 100 + TARGET_WIDTH + TARGET_PADDING, y: 150, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 2, y: 150, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 3, y: 150, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 4, y: 150, is_dead: false),

    Target(x: 100, y: 200, is_dead: false),
    Target(x: 100 + TARGET_WIDTH + TARGET_PADDING, y: 200, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 2, y: 200, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 3, y: 200, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 4, y: 200, is_dead: false),

    Target(x: 100, y: 250, is_dead: false),
    Target(x: 100 + TARGET_WIDTH + TARGET_PADDING, y: 250, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 2, y: 250, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 3, y: 250, is_dead: false),
    Target(x: 100 + (TARGET_WIDTH + TARGET_PADDING) * 4, y: 250, is_dead: false),
  ]
  targets_pool_count = 0
# type
#   Point = object
#     x: float32
#     y: float32
proc make_rect(x: float32, y: float32, w: float32, h: float32): sdl2.Rect =
  var rect: Rect = (x: cint(x), y: cint(y), w: cint(w), h: cint(h))
  return rect

proc target_rect(target: Target): sdl2.Rect =
  return make_rect(target.x, target.y, TARGET_WIDTH, TARGET_HEIGHT)
  

proc ball_rect(x: float32, y: float32): sdl2.Rect =
  return make_rect(x, y, float32(BALL_SIZE), float32(BALL_SIZE))

proc bar_rect(): sdl2.Rect =
  return make_rect(float32(bar_x), float32(BAR_Y - BAR_THICKNESS / 2), float32(BAR_LENGTH), float32(BAR_THICKNESS))

proc has_intersection(rect1: var sdl2.Rect, rect2: var sdl2.Rect): bool =
  var ballw = rect1.w
  var ballh = rect1.h
  var barw = rect2.w
  var barh = rect2.h

  var ballx = rect1.x
  var bally = rect1.y
  var barx = rect2.x
  var bary = rect2.y

  barw += barx
  barh += bary
  ballw += ballx
  ballh += bally

  return (barw < barx or barw > ballx) and (barh < bary or barh > bally) and (ballw < ballx or ballw > barx) and (ballh < bally or ballh > bary)


proc update(dt: float32) =
  if not pause and started:
    #bar_x += bar_dx * BAR_SPEED * dt # increse the speed of the bar when moving horizontally

    # if bar_x < 0: bar_x = 0
    # if bar_x > WINDOW_WIDTH - BAR_LENGTH: bar_x = WINDOW_WIDTH - BAR_LENGTH

    bar_x = clamp(bar_x + bard_x * BAR_SPEED * dt, 0, WINDOW_WIDTH - BAR_LENGTH) # avoid bar overflow

    var new_ball_x_pos = ball_x + dx * BALL_SPEED * dt
    var ball_rect = ball_rect(new_ball_x_pos, ball_y)
    var bar_rect = bar_rect()
    var cond_x = new_ball_x_pos < 0 or new_ball_x_pos + BALL_SIZE > WINDOW_WIDTH or has_intersection(ball_rect, bar_rect)
    for target in targets_pool:
      if cond_x: break
      if not target.is_dead:
        var target_rect = target_rect(target)
        cond_x = cond_x or has_intersection(ball_rect, target_rect)
        if cond_x: target.is_dead = true
    if(cond_x):
      dx *= -1
      new_ball_x_pos = ball_x + dx * BALL_SPEED * dt
    ball_x = new_ball_x_pos

    var new_ball_y_pos = ball_y + dy * BALL_SPEED * dt
    ball_rect = ball_rect(ball_x, new_ball_y_pos)

    var cond_y = new_ball_y_pos < 0 or new_ball_y_pos + BALL_SIZE > WINDOW_HEIGHT
    if not cond_y:
      cond_y = cond_y or has_intersection(ball_rect, bar_rect)
      if cond_y and not (dx == 0):
        dx = bar_dx
    for target in targets_pool:
      if cond_y: break
      if not target.is_dead:
        var target_rect = target_rect(target)
        cond_y = cond_y or has_intersection(ball_rect, target_rect)
        if cond_y: target.is_dead = true
    if(cond_y):
      dy *= -1
      new_ball_y_pos = ball_y + dy * BALL_SPEED * dt
    ball_y = new_ball_y_pos


proc render(renderer: var RendererPtr) =
  # render start
  # - ball start
  renderer.setDrawColor 0xFF, 0xFF, 0xFF, 0xFF
  var ball_rect = ball_rect(ball_x, ball_y)
  renderer.fillRect(ball_rect)
  # - ball end  

  # - player bar start
  renderer.setDrawColor 0xFF, 0, 0, 0xFF
  var bar_rect = bar_rect()
  renderer.fillRect(bar_rect)
  # - player bar end

  renderer.setDrawColor 0, 0xFF, 0, 0xFF
  for target in targets_pool:
    if not target.is_dead:
      var target_rect = target_rect(target)
      renderer.fillRect(target_rect)

  # render end

proc main() =
  discard sdl2.init(INIT_EVERYTHING)
  
  var
    window: WindowPtr
    renderer: RendererPtr

  window = sdl2.createWindow(WINDOW_TITLE, 
   SDL_WINDOWPOS_CENTERED, 
    SDL_WINDOWPOS_CENTERED, 
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    SDL_WINDOW_SHOWN)

  renderer = sdl2.createRenderer(window, -1, Renderer_Accelerated or Renderer_PresentVsync)

  
  while quitGame != true:
    while sdl2.pollEvent(ev):
      case ev.kind
      of QuitEvent:
        quitGame = true
        break
      of KeyDown:
        var key = ev.key.keysym.sym
        case key.chr
        of 'a': bar_x -= 10
        of 'd': bar_x += 10
        of 'q':
          quitGame = true
          break
        of ' ': pause = not pause
        else: discard
      else: discard
    
    bar_dx = 0
    if state[SDL_SCANCODE_A.int] != 0:
      bar_dx += -1
      if not started:
        started = true
        dx = -1

    if state[SDL_SCANCODE_D.int] != 0:
      bar_dx += 1
      if not started:
        started = true
        dx = 1

    update(DELTA_TIME_SEC)

    renderer.setDrawColor 0x18, 0x18, 0x18, 0xFF
    renderer.clear

    render(renderer)

    renderer.present

    sdl2.delay 1000 div FPS

  destroy renderer
  destroy window

      

when isMainModule:
  main()