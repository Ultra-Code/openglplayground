//gl_Position is a predefined variable that specifies the output of the
//vertex shader and is of type vec4. The last co-ordinate of the vec4
//specifie the pespective division which is useful for 4d corodinates
#version 460 core
layout (location = 0) in vec3 input_vetex_data;
uniform vec4 vertex_color;
layout (location = 1) in vec3 input_vertex_color;
out vec4 fragment_color;

void main(){
    gl_Position = vec4(input_vetex_data.xyz,1.0);
    //output variable to dark-red// vec4(0.5, 0.0, 0.0, 1.0);
    fragment_color = vec4(input_vertex_color,1.0);
}
