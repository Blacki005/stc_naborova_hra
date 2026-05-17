shader_type canvas_item;

uniform float sweep_progress : hint_range(-0.5, 1.5) = -0.5;
uniform float sweep_width : hint_range(0.01, 0.5) = 0.15;

void fragment() {
	float d = abs(UV.x - sweep_progress);
	if (d < sweep_width) {
		float intensity = 1.0 - (d / sweep_width);
		intensity = pow(intensity, 1.5);
		COLOR.rgb += vec3(intensity * 0.8);
	}
}
