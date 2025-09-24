shader_type canvas_item;

uniform float fade_amount = 0.4;

void fragment() {
    vec4 currentScreenContent = texture(TEXTURE, UV);
    COLOR = vec4(currentScreenContent.rgb * fade_amount, currentScreenContent.a);
}