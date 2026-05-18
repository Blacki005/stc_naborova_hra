shader_type canvas_item;

// Tint color for the ghost afterimage
uniform vec4 ghost_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
// Controls overall opacity (animated from code for fade-out)
uniform float alpha_mult : hint_range(0.0, 1.0) = 1.0;
// Horizontal distortion to convey speed
uniform float distortion : hint_range(0.0, 0.5) = 0.0;

void fragment() {
	// Slight UV distortion along Y for a speed-stretch feel
	vec2 uv = UV;
	uv.x += distortion * (UV.y - 0.5) * 0.3;

	vec4 tex = texture(TEXTURE, uv);

	// Mix original color toward ghost tint
	vec3 final_color = mix(tex.rgb, ghost_color.rgb, 0.65);

	// Subtle edge glow where sprite alpha transitions
	float edge = smoothstep(0.05, 0.35, tex.a) * (1.0 - smoothstep(0.35, 0.8, tex.a));
	final_color += ghost_color.rgb * edge * 0.5;

	COLOR = vec4(final_color, tex.a * alpha_mult);
}
