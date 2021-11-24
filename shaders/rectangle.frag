//we specify the fragment shader output color using RGBA vec4
#version 460 core
// input variable from vertex shader (same name and type)
in vec3 fragment_color;
//fragment shader color output
out vec4 fragment_color_output;

uniform sampler2D container_texture_obj;   //texture unit 0
uniform sampler2D smilelyface_texture_obj; //texture unit 1

in vec2 fragment_texture_coordinates;

void main(){
    //linearly interpolate between both textures (80% container, 20% smilelyface)
    vec1 linear_interpolation_percentage = vec1(0.2);
    fragment_color_output = mix(texture(container_texture_obj,fragment_texture_coordinates) * vec4(fragment_color,1.0),texture(smilelyface_texture_obj,fragment_texture_coordinates),linear_interpolation_percentage);
}

