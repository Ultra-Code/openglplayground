//we specify the fragment shader output color using RGBA vec4
#version 460 core
// input variable from vertex shader (same name and type)
in vec4 fragment_color;
//fragment shader color output
out vec4 fragment_color_output;

void main(){
    fragment_color_output = fragment_color;
}

