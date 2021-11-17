const std = @import("std");
usingnamespace @import("cimports.zig");
//cordinates for sampling texture
const texture_coordinates = [4][2]f32{
    [_]f32{ 1.0, 1.0 }, //upper right
    [_]f32{ 1.0, 0.0 }, //lower right
    [_]f32{ 0.0, 0.0 }, //lower left
    [_]f32{ 0.0, 1.0 }, //upper left
};

const rectangle_vertex_data = [4][6]f32{
    //rectangle using index drawing with color data for each vertice
    //first 3 vertices are for the point of the rectangle in 3d space
    //the last 3 are for the rgb color for that point in space
    [_]f32{ 0.5, 0.5, 0.0, 1.0, 0.0, 0.0 }, // top right
    [_]f32{ 0.5, -0.5, 0.0, 0.0, 1.0, 0.0 }, // bottom right
    [_]f32{ -0.5, -0.5, 0.0, 0.0, 0.0, 1.0 }, // bottom left
    [_]f32{ -0.5, 0.5, 0.0, 1.0, 1.0, 0.0 }, // top left
};

const drawing_index_order = [2][3]u32{
    [_]u32{ 0, 1, 2 }, // first triangle
    [_]u32{ 0, 3, 2 }, // second triangle
};

const Vertex = struct { vbo: [2]c_uint, vao: c_uint, ebo: c_uint };

var vertex: Vertex = undefined;

pub fn storeVboOnGpu() c_uint {
    const vo_num = 2;
    //vertex array object for holding vertex and glVertexAttribPointer
    //configurations
    var vao: c_uint = undefined;
    glGenVertexArrays(vo_num, &vao);

    var vbo: [2]c_uint = undefined;
    glGenBuffers(vo_num, &vbo);
    const texture_vbo: c_uint = vbo[0];
    const rectangle_vbo: c_uint = vbo[1];

    glBindVertexArray(vao);
    //specify buffer type
    glBindBuffer(GL_ARRAY_BUFFER, rectangle_vbo);
    //copy the triangle_vetex_data into the vbo's memory with target type
    //GL_ARRAY_BUFFER
    glBufferData(GL_ARRAY_BUFFER, @sizeOf(@TypeOf(rectangle_vertex_data)), &rectangle_vertex_data, GL_STATIC_DRAW);

    var ebo: c_uint = undefined;
    glGenBuffers(1, &ebo);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(drawing_index_order)), &drawing_index_order, GL_STATIC_DRAW);

    mapRectangleVertexToAttribute();

    glBindBuffer(GL_ARRAY_BUFFER, texture_vbo);
    glBufferData(GL_ARRAY_BUFFER, @sizeOf(@TypeOf(texture_coordinates)), &texture_coordinates, GL_STATIC_DRAW);

    mapTextureCoordinatesToAttribute();

    vertex = .{ .vbo = vbo, .vao = vao, .ebo = ebo };
    return vao;
}
fn mapTextureCoordinatesToAttribute() void {
    const vertex_data_type = GL_FLOAT;
    const normalize_vertex_data = GL_FALSE; // data is already in NDC
    const size_of_vertex_datatype = @sizeOf(@TypeOf(texture_coordinates[0][0]));
    const texture_coordinates_location = 2;
    const texture_attribute_size = 2;
    const space_between_consecutive_vertex_in_texture_coordinates = texture_attribute_size * size_of_vertex_datatype;
    glVertexAttribPointer(texture_coordinates_location, texture_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex_in_texture_coordinates, null);
    glEnableVertexAttribArray(texture_coordinates_location);
}

fn mapRectangleVertexToAttribute() void {
    // layout(location = 0).in our vertex shader for our aPos attribute
    const vertex_data_attribute_location = 0;
    // our in attribute data had 3 values x,y,z and type  vec3
    const vertex_data_attribute_size = 3;
    const vertex_color_attribute_size = 3;
    const vertex_data_type = GL_FLOAT;
    const normalize_vertex_data = GL_FALSE; // data is already in NDC
    const size_of_vertex_datatype = @sizeOf(@TypeOf(rectangle_vertex_data[0][0]));
    //specify the size of the consecutive columns of the input data
    //if the vertex attributes receive data from the same input
    //it is call stride.NOTE we could specify 0 for opengl to detect the
    //stide but this only works if our buffer is tightly pack
    //NOTE: here the + operator must have higher precedence over the * operator
    //for correct result
    const space_between_consecutive_vertex = (vertex_data_attribute_size + vertex_color_attribute_size) * size_of_vertex_datatype;
    // the offset of where the position begins in the buffer
    //in our case the offset is at 0 the begining of the array buffer
    const position_data_start_offset = null; // @intToPtr(*c_void, 0);
    glVertexAttribPointer(vertex_data_attribute_location, vertex_data_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex, position_data_start_offset);
    glEnableVertexAttribArray(vertex_data_attribute_location);

    const vertex_color_attribute_location = 1;
    //This is to give the offset of the color in the vertex buffer
    //The color is at the 3 position .NOTE: counting from 0 for arrays
    //and each of this vertices have a size of size_of_vertex_datatype
    //meaning for each vertex our color data start from the 3rd data in the
    //buffer .ie [0,1,2,3,4,5] color data start from 3 - 5 for each vertex
    const position_color_start_offset = @intToPtr(*c_void, vertex_color_attribute_size * size_of_vertex_datatype);
    glVertexAttribPointer(vertex_color_attribute_location, vertex_color_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex, position_color_start_offset);
    glEnableVertexAttribArray(vertex_color_attribute_location);
}

pub fn deinitRectangleBuffers() void {
    for (vertex.vbo) |vbo| {
        defer glDeleteBuffers(1, &vbo);
    }
    defer glDeleteBuffers(1, &vertex.ebo);
    defer glDeleteVertexArrays(1, &vertex.vao); //1 is the vao id
}
pub fn setUniformInShader(shader_program: c_uint) void {
    const time_value: f64 = glfwGetTime();
    // for varing the green color continuously from green to black and again
    const green_value = (std.math.sin(time_value) / 2) + 0.5;
    const vertex_color_location: c_int = glGetUniformLocation(shader_program, "vertex_color");
    //uninforms are useful for setting attributes that might change on every frame
    //or for interchanging data between your application and your shaders
    glUniform4f(vertex_color_location, 0.0, @floatCast(f32, green_value), 0.0, 1.0);
}
