//we specify the fragment shader output color using RGBA vec4
#version 460 core
// input variable from vertex shader (same name and type)
in vec3 fragment_color;
//fragment shader color output
out vec4 fragment_color_output;

uniform sampler2D texture_obj;

in vec2 fragment_texture_coordinates;

void main(){
    fragment_color_output = texture(texture_obj,fragment_texture_coordinates) * vec4(fragment_color,1.0);
}

