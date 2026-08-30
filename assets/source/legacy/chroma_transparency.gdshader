shader_type canvas_item;

uniform float light_threshold : hint_range(0.0, 1.0) = 0.78;

void fragment() {
	vec4 raw_sample = texture(TEXTURE, UV);
	vec4 sampled = raw_sample * COLOR;
	// Detect the baked checkerboard before applying outfit or hurt tints.
	// Otherwise a neutral background becomes coloured and no longer matches.
	float channel_min = min(raw_sample.r, min(raw_sample.g, raw_sample.b));
	float channel_max = max(raw_sample.r, max(raw_sample.g, raw_sample.b));
	if (channel_min > light_threshold && channel_max - channel_min < 0.12) {
		sampled.a = 0.0;
	}
	COLOR = sampled;
}
