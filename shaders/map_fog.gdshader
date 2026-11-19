shader_type canvas_item;

uniform sampler2D noise_tex : repeat_enable, filter_nearest;
uniform vec4 fog_color : source_color = vec4(0.86, 0.84, 0.78, 0.92);
uniform vec2 scroll_speed = vec2(0.015, 0.008);
uniform vec2 map_size = vec2(1152.0, 648.0);
uniform float pixel_size = 3.0;

// Hasta 12 zonas despejadas (x, y en píxeles del mapa, z = radio despejado)
uniform vec3 clear_zones[12];
uniform int clear_count = 0;
uniform float edge_softness = 45.0;

void fragment() {
	// Pixelamos las coordenadas UV para mantener estética pixel-art
	vec2 pixel_uv = floor(UV * (map_size / pixel_size)) / (map_size / pixel_size);
	vec2 world_pos = pixel_uv * map_size;
	
	// Ruido animado en dos capas para bordes de nube orgánicos
	float n1 = texture(noise_tex, pixel_uv * 2.5 + TIME * scroll_speed).r;
	float n2 = texture(noise_tex, pixel_uv * 4.0 - TIME * scroll_speed * 0.7).r;
	float cloud_noise = (n1 + n2) * 0.5;
	
	// Calculamos la visibilidad mínima (0.0 = despejado, 1.0 = cubierto de niebla)
	float fog_mask = 1.0;
	for (int i = 0; i < clear_count; i++) {
		vec2 center = clear_zones[i].xy;
		float radius = clear_zones[i].z;
		
		// Deformamos el borde del círculo con el ruido de nube
		float dist = distance(world_pos, center) + (cloud_noise - 0.5) * 35.0;
		float hole = smoothstep(radius - edge_softness, radius, dist);
		fog_mask = min(fog_mask, hole);
	}
	
	// Densidad final combinando la textura de nube con la máscara de zonas despejadas
	float alpha = fog_mask * clamp(0.65 + cloud_noise * 0.45, 0.0, 1.0) * fog_color.a;
	COLOR = vec4(fog_color.rgb, alpha);
}