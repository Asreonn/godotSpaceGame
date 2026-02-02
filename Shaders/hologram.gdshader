shader_type canvas_item;

uniform vec4 valid_color : source_color = vec4(0.0, 0.85, 0.9, 0.55);
uniform vec4 invalid_color : source_color = vec4(1.0, 0.2, 0.15, 0.55);
uniform bool is_valid = true;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float scan_speed : hint_range(0.5, 8.0) = 2.5;
uniform float scan_count : hint_range(2.0, 30.0) = 12.0;
uniform float pulse_speed : hint_range(0.5, 6.0) = 3.0;
uniform float edge_glow : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// Tamamen seffaf pikselleri atla
	if (tex.a < 0.01) {
		discard;
	}

	// Hologram rengi sec
	vec4 holo = is_valid ? valid_color : invalid_color;

	// Tarama cizgileri (yatay, yukari akan)
	float scan_raw = fract(UV.y * scan_count - TIME * scan_speed);
	float scan_line = smoothstep(0.82, 1.0, scan_raw) * 0.35;

	// Pulse (nabiz) efekti
	float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);

	// Kenar parlama (edge glow) - sprite sinirina yakin pikseller
	float edge_x = min(UV.x, 1.0 - UV.x);
	float edge_y = min(UV.y, 1.0 - UV.y);
	float edge = 1.0 - smoothstep(0.0, 0.08, min(edge_x, edge_y));
	float glow = edge * edge_glow;

	// Temel hologram gorunumu
	float base_alpha = holo.a + scan_line + pulse * 0.08 + glow * 0.5;

	COLOR.rgb = holo.rgb + vec3(scan_line * 0.4) + vec3(glow * holo.rgb * 2.0);
	COLOR.a = tex.a * clamp(base_alpha, 0.0, 1.0);

	// Build progress: asagidan yukariya dolma efekti
	if (progress > 0.005) {
		// Dolan kisim (UV.y = 1 alta karsilik gelir, ters ceviriyoruz)
		float fill_line = 1.0 - progress;
		float is_filled = step(fill_line, UV.y);  // dolu kisim = 1

		// Dolu kisimda opakligi artir ve rengi parlat
		float fill_boost = is_filled * progress * 0.5;
		COLOR.a += fill_boost * tex.a;
		COLOR.rgb += vec3(is_filled * progress * 0.25);

		// Dolum cizgisinde parlak cizgi
		float line_dist = abs(UV.y - fill_line);
		float fill_edge = 1.0 - smoothstep(0.0, 0.02, line_dist);
		COLOR.rgb += holo.rgb * fill_edge * 1.5;
		COLOR.a += fill_edge * 0.3 * tex.a;
	}

	COLOR.a = clamp(COLOR.a, 0.0, 1.0);
}
