shader_type canvas_item;

uniform float light_threshold : hint_range(0.0, 1.0) = 0.78;

void fragment() {
	vec4 sampled = texture(TEXTURE, UV) * COLOR;
	float channel_min = min(sampled.r, min(sampled.g, sampled.b));
	float channel_max = max(sampled.r, max(sampled.g, sampled.b));
	if (channel_min > light_threshold && channel_max - channel_min < 0.12) {
		sampled.a = 0.0;
	}
	COLOR = sampled;
}
