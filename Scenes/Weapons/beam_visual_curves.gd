class_name BeamVisualCurves

## Beam gorsel efektleri icin gradient ve curve yardimcilari.
## Saf fabrika fonksiyonlari - state tutmaz.

static func create_beam_scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.clear_points()
	# Yumuşak çan eğrisi - yavaş büyü, yavaş küçül
	curve.add_point(Vector2(0.0, 0.0), 0.0, 2.0)
	curve.add_point(Vector2(0.3, 0.8), 0.5, 0.2)
	curve.add_point(Vector2(0.6, 1.0), 0.0, -0.3)
	curve.add_point(Vector2(1.0, 0.0), -1.5, 0.0)
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex

static func create_casting_scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.clear_points()
	# Smooth fade out
	curve.add_point(Vector2(0.0, 0.3), 0.0, 3.0)
	curve.add_point(Vector2(0.2, 1.0), 0.0, 0.0)
	curve.add_point(Vector2(0.6, 0.6), -0.5, -0.5)
	curve.add_point(Vector2(1.0, 0.0), -1.0, 0.0)
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex

static func create_beam_gradient() -> GradientTexture1D:
	var gradient := Gradient.new()
	# 5 noktalı yumuşak geçiş
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.85, 0.7, 1.0, 0.7),   # Başlangıç - yumuşak lavanta
		Color(0.75, 0.55, 0.95, 0.55), # Erken orta
		Color(0.6, 0.4, 0.85, 0.35),   # Orta - solmaya başlıyor
		Color(0.45, 0.25, 0.7, 0.15),  # Geç orta
		Color(0.3, 0.15, 0.5, 0.0)     # Bitiş - tamamen şeffaf
	])
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	return tex

static func create_muzzle_gradient() -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 0.4, 0.7, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.9, 1.0, 0.95),    # Baslangic - parlak beyaz-lavanta
		Color(0.9, 0.75, 1.0, 0.8),    # Erken
		Color(0.8, 0.6, 0.95, 0.55),   # Orta
		Color(0.6, 0.4, 0.8, 0.25),    # Gec
		Color(0.4, 0.2, 0.6, 0.0)      # Bitis
	])
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	return tex

static func create_line_gradient() -> Gradient:
	var gradient := Gradient.new()
	# Beam boyunca parlak renk gecisi
	gradient.offsets = PackedFloat32Array([0.0, 0.1, 0.4, 0.75, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.9, 1.0, 1.0),     # Muzzle - beyaz-parlak
		Color(0.9, 0.7, 1.0, 0.95),    # Erken - parlak lavanta
		Color(0.8, 0.6, 0.95, 0.8),    # Orta
		Color(0.65, 0.45, 0.85, 0.45), # Gec
		Color(0.5, 0.3, 0.7, 0.0)      # Uc - kaybolma
	])
	return gradient

static func create_width_curve() -> Curve:
	# Beam genişliği: başta ince, ortada normal, uçta sivrilen
	var curve := Curve.new()
	curve.clear_points()
	curve.add_point(Vector2(0.0, 0.7), 0.0, 1.0)
	curve.add_point(Vector2(0.15, 1.0), 0.3, 0.0)
	curve.add_point(Vector2(0.7, 1.0), 0.0, -0.3)
	curve.add_point(Vector2(1.0, 0.3), -1.5, 0.0)
	return curve
