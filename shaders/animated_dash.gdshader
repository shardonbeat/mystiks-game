shader_type canvas_item;

uniform float speed = 1.5; // Velocidad a la que avanzan los trazos hacia el destino

void fragment() {
	// Desplazamos UV.x hacia atrás en el tiempo para que los trazos avancen desde el origen hacia el destino
	vec2 moving_uv = vec2(UV.x - TIME * speed, UV.y);
	COLOR = texture(TEXTURE, moving_uv) * COLOR;
}