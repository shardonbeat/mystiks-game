shader_type canvas_item;

uniform vec4 edge_color : source_color = vec4(0.03, 0.06, 0.11, 0.92);
uniform vec4 mist_color : source_color = vec4(0.75, 0.88, 0.95, 0.14);
uniform float vignette_intensity : hint_range(0.0, 2.0) = 1.15;
uniform float vignette_softness : hint_range(0.1, 1.0) = 0.55;
uniform float left_ui_shadow : hint_range(0.0, 1.0) = 0.35;
uniform float mist_speed : hint_range(0.0, 0.2) = 0.025;

// Ruido procedural ligero para la bruma
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * noise(p);
		p *= 2.02;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	// 1. Viñeta alrededor de los bordes de la pantalla
	vec2 centered_uv = UV - vec2(0.55, 0.5); // Desplazada un poco a la derecha para centrar el mar
	float dist = length(centered_uv * vec2(1.15, 1.0));
	float vignette = smoothstep(vignette_softness - 0.25, vignette_softness + 0.35, dist * vignette_intensity);
	
	// Sombra extra suave en el tercio izquierdo para que los botones se lean nítidos
	float left_shade = smoothstep(0.45, 0.0, UV.x) * left_ui_shadow;
	float border_alpha = clamp(vignette + left_shade, 0.0, 1.0);
	
	// 2. Dos capas de bruma moviéndose en direcciones ligeramente distintas
	vec2 mist_uv1 = UV * vec2(3.5, 2.2) + vec2(TIME * mist_speed, TIME * mist_speed * 0.3);
	vec2 mist_uv2 = UV * vec2(5.0, 3.0) - vec2(TIME * mist_speed * 0.6, -TIME * mist_speed * 0.2);
	float mist = (fbm(mist_uv1) * 0.6 + fbm(mist_uv2) * 0.4);
	mist = smoothstep(0.42, 0.78, mist);
	
	// Mezclamos el marco oscuro con la bruma flotante
	vec3 final_rgb = mix(mist_color.rgb, edge_color.rgb, border_alpha);
	float final_alpha = clamp(border_alpha * edge_color.a + mist * mist_color.a * (1.0 - border_alpha * 0.5), 0.0, 1.0);
	
	COLOR = vec4(final_rgb, final_alpha);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
