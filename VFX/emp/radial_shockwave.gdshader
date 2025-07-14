shader_type canvas_item;

//emp effect
uniform vec2 center;
uniform float force;
uniform float size;
uniform float thickness;
uniform sampler2D screen_texture : hint_screen_texture;

//range indicator
uniform float mark_thickness = 0.01;
uniform vec4 mark_color : source_color = vec4(1.0);
uniform float subdivision = 128.0;
uniform sampler2D noise;
uniform float noise_strength = 0.065;


void fragment(){
    //Shockwave effect taken from: https://www.youtube.com/watch?v=SCHdglr35pk
    //Difference is using UV rather than SCREEN UV and ratio.
    float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
    vec2 scaled_uv = (UV - vec2(0.5, 0.0)) /  vec2(1.0, 1.0) + vec2(0.5, 0.0);//<-- differences here in UV
    float mask = (1.0 - smoothstep(size - 0.1, size, length(scaled_uv - center))) * smoothstep(size - thickness - 0.2, size - thickness, length(scaled_uv - center));
    vec2 disp = normalize(scaled_uv - center) * force * mask;
    COLOR = texture(screen_texture, SCREEN_UV - disp);

    //Range indicator for the emp
    vec2 pixel_uv = vec2(round(UV.x * subdivision) / subdivision, round(UV.y * subdivision) / subdivision);
	vec2 centered_uv = pixel_uv * vec2(2.0) - 1.0;
	float uv_dist = (centered_uv.x * centered_uv.x + centered_uv.y * centered_uv.y) + (texture(noise, pixel_uv * (vec2(sin(TIME))) + vec2(0.5)).r) * noise_strength;
	if (uv_dist * 0.5 > size * size && uv_dist * 0.5 < size * size + mark_thickness){
		COLOR = mark_color;
	}
}