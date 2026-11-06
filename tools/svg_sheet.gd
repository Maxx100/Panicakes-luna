extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	var svg_scale := float(args[1])
	var images: Array[Image] = []
	var width := 16
	var height := 0
	for path in args.slice(2):
		var img := Image.new()
		var err := img.load_svg_from_buffer(FileAccess.get_file_as_bytes(path), svg_scale)
		if err != OK:
			printerr("SVG FAIL %s: %s" % [path, error_string(err)])
			continue
		img.convert(Image.FORMAT_RGBA8)
		images.append(img)
		width += img.get_width() + 16
		height = maxi(height, img.get_height())
	var sheet := Image.create(width, height + 32, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#57518E"))
	var x := 16
	for img in images:
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, 16))
		x += img.get_width() + 16
	sheet.save_png(out)
	print("SHEET %s %dx%d" % [out, sheet.get_width(), sheet.get_height()])
	quit()
