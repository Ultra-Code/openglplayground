#version 460 core
//input variable from vertex shader (same name and type)
in vec2 fragment_texture_coordinates;

//we specify the fragment shader output color using RGBA vec4
//fragment shader color output
out vec4 fragment_color_output;

uniform sampler2D container_texture_obj;   //texture unit 0
uniform sampler2D smilelyface_texture_obj; //texture unit 1

void main(){
    //linearly interpolate between both textures (80% container, 20% smilelyface)
    float linear_interpolation_percentage = 0.2;
    fragment_color_output = mix(texture(container_texture_obj,fragment_texture_coordinates) ,texture(smilelyface_texture_obj,fragment_texture_coordinates),linear_interpolation_percentage);
}
