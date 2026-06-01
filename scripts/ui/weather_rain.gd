extends Control
class_name WeatherRain
## Code-drawn rain overlay; amount + storm slant read from the Weather autoload each frame. Pure visual.

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var amt := Weather.rain_amount()
	if amt <= 0.02:
		return
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var n := int(140.0 * amt)
	var slant := 4.0 + (6.0 if Weather.is_storm() else 0.0)
	var col := Color(0.7, 0.8, 1.0, 0.28 + 0.16 * amt)
	for i in n:
		var px := fmod(float(i) * 73.0 + 13.0, w)
		var phase := fmod(float(i) * 0.0917, 1.0)
		var speed := 420.0 + 260.0 * phase
		var y := fmod(_t * speed + phase * h, h)
		var ln := 10.0 + 8.0 * phase
		draw_line(Vector2(px, y), Vector2(px - slant, y + ln), col, 1.0)
