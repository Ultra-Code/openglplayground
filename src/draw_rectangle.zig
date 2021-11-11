const std = @import("std");
usingnamespace @import("c_imports.zig");

const vertex_shader_source: [*:0]const u8 =
    //gl_Position is a predefined variable that specifies the output of the
    //vertex shader and is of type vec4. The last co-ordinate of the vec4
    //specifie the pespective division which is useful for 4d corodinates
    \\#version 460 core
    \\layout (location = 0) in vec3 input_vetex_data;
    \\
    \\void main(){
    \\gl_Position = vec4(input_vetex_data.x,input_vetex_data.y,input_vetex_data.z,1.0);
    \\}
;

const fragment_shader_source: [*:0]const u8 =
    //we specify the fragment shader output color using RGBA vec4
    \\#version 460 core
    \\out vec4 fragment_color_output;
    \\
    \\void main(){
    \\fragment_color_output = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
;

const rectangle_vertex_data = [4][3]f32{
    //rectangle using index drawing
    [_]f32{ 0.5, 0.5, 0.0 }, // top right}
    [_]f32{ 0.5, -0.5, 0 }, // bottom right
    [_]f32{ -0.5, -0.5, 0 }, // bottom left
    [_]f32{ -0.5, 0.5, 0 }, // top left
};

const drawing_index_order = [2][3]u32{
    [_]u32{ 0, 1, 2 }, // first triangle
    [_]u32{ 0, 3, 2 }, // second triangle
};

const Vertex = struct { vbo: c_uint, vao: c_uint, ebo: c_uint };

var vertex: Vertex = undefined;

pub fn storeVboOnGpu() c_uint {
    const vo_id = 1;
    //vertex array object for holding vertex and glVertexAttribPointer
    //configurations
    var vao: c_uint = undefined;
    glGenVertexArrays(vo_id, &vao);

    var vbo: c_uint = undefined;
    glGenBuffers(vo_id, &vbo);

    glBindVertexArray(vao);
    //specify buffer type
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    //copy the triangle_vetex_data into the vbo's memory with target type
    //GL_ARRAY_BUFFER
    glBufferData(GL_ARRAY_BUFFER, @sizeOf(@TypeOf(rectangle_vertex_data)), &rectangle_vertex_data, GL_STATIC_DRAW);

    var ebo: c_uint = undefined;
    glGenBuffers(vo_id, &ebo);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(drawing_index_order)), &drawing_index_order, GL_STATIC_DRAW);

    mapVertexDataToShaderAttribute();
    vertex = .{ .vbo = vbo, .vao = vao, .ebo = ebo };
    return vao;
}

fn mapVertexDataToShaderAttribute() void {
    // layout(location = 0).in our vertex shader for our aPos attribute
    const vertex_attribute_location = 0;
    // our in attribute data had 3 values x,y,z and type  vec3
    const vertex_attribute_size = 3;
    const vertex_data_type = GL_FLOAT;
    const normalize_vertex_data = GL_FALSE; // data is already in NDC
    // specify the size of the consecutive column of v attributes it is
    // call stride.NOTE we could specify 0 for opengl to detect the
    // stide but this only works if our buffer dis tightly pack
    const space_between_consecutive_vertex = vertex_attribute_size * @sizeOf(@TypeOf(rectangle_vertex_data[0][0]));
    // the offset of where the position begins in the buffer
    //in our case the offset is at 0 the begining of the array buffer
    const position_data_start_offset = null; // @intToPtr(*c_void, 0x0);
    glVertexAttribPointer(vertex_attribute_location, vertex_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex, position_data_start_offset);
    glEnableVertexAttribArray(vertex_attribute_location);
}
const main = @import("main.zig");

pub fn rectangleShaderProgram() c_uint {
    const vertex_shader = main.compileShader(GL_VERTEX_SHADER, vertex_shader_source);
    const fragment_shader = main.compileShader(GL_FRAGMENT_SHADER, fragment_shader_source);

    const shader_program = main.linkShaders(vertex_shader, fragment_shader);
    defer glDeleteShader(vertex_shader);
    defer glDeleteShader(fragment_shader);
    return shader_program;
}

pub fn deinitRectangleBuffers() void {
    defer glDeleteBuffers(1, &vertex.vbo);
    defer glDeleteBuffers(1, &vertex.ebo);
    defer glDeleteVertexArrays(1, &vertex.vao); //1 is the vao id
}
