#version 460 core

layout (location = 0) in vec3 input_vetex_data;
layout (location = 1) in vec2 texture_coordinates;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;
out vec2 fragment_texture_coordinates;

void main(){
    //gl_Position is a predefined variable that specifies the output of the
    //vertex shader and is of type vec4. The last co-ordinate of the vec4
    //specifie the pespective division which is useful for 4d corodinates
    //transform the input_vertex position by the mat4 transformations model,view,projection
    // note that we read the multiplication from right to left
    gl_Position = projection*view*model * vec4(input_vetex_data.xyz,1.0);
    fragment_texture_coordinates = texture_coordinates;
}
