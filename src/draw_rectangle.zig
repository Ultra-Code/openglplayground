const std = @import("std");
const c = @import("cimports.zig");
const Shader = @import("shader.zig").Shader;
const glm = @import("glm.zig");
const Vec4 = glm.Vec4;
const Mat4 = glm.Mat4;
const vec3 = glm.vec3;
const vec4 = glm.vec4;
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
    //vertex array object for holding vertex and c.glVertexAttribPointer
    //configurations
    var vao: c_uint = undefined;
    c.glGenVertexArrays(vo_num, &vao);

    var vbo: [2]c_uint = undefined;
    c.glGenBuffers(vo_num, &vbo);
    const texture_vbo: c_uint = vbo[0];
    const rectangle_vbo: c_uint = vbo[1];

    c.glBindVertexArray(vao);
    //specify buffer type
    c.glBindBuffer(c.GL_ARRAY_BUFFER, rectangle_vbo);
    //copy the triangle_vetex_data into the vbo's memory with target type
    //c.GL_ARRAY_BUFFER
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(rectangle_vertex_data)), &rectangle_vertex_data, c.GL_STATIC_DRAW);

    var ebo: c_uint = undefined;
    c.glGenBuffers(1, &ebo);

    c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo);
    c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(drawing_index_order)), &drawing_index_order, c.GL_STATIC_DRAW);

    mapRectangleVertexToAttribute();

    c.glBindBuffer(c.GL_ARRAY_BUFFER, texture_vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(texture_coordinates)), &texture_coordinates, c.GL_STATIC_DRAW);

    mapTextureCoordinatesToAttribute();

    vertex = .{ .vbo = vbo, .vao = vao, .ebo = ebo };
    return vao;
}
fn mapTextureCoordinatesToAttribute() void {
    const vertex_data_type = c.GL_FLOAT;
    const normalize_vertex_data = c.GL_FALSE; // data is already in NDC
    const size_of_vertex_datatype = @sizeOf(@TypeOf(texture_coordinates[0][0]));
    const texture_coordinates_location = 2;
    const texture_attribute_size = 2;
    const space_between_consecutive_vertex_in_texture_coordinates = texture_attribute_size * size_of_vertex_datatype;
    c.glVertexAttribPointer(texture_coordinates_location, texture_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex_in_texture_coordinates, null);
    c.glEnableVertexAttribArray(texture_coordinates_location);
}

fn mapRectangleVertexToAttribute() void {
    // layout(location = 0).in our vertex shader for our aPos attribute
    const vertex_data_attribute_location = 0;
    // our in attribute data had 3 values x,y,z and type  vec3
    const vertex_data_attribute_size = 3;
    const vertex_color_attribute_size = 3;
    const vertex_data_type = c.GL_FLOAT;
    const normalize_vertex_data = c.GL_FALSE; // data is already in NDC
    const size_of_vertex_datatype = @sizeOf(@TypeOf(rectangle_vertex_data[0][0]));
    //specify the size of the consecutive columns of the input data.If the vertex attributes receive data from the same input
    //The consecutive spaces is call stride.NOTE we could specify 0 for opengl to detect the stide but this only works if our buffer is tightly pack
    //NOTE: here the + operator must have higher precedence over the * operator for correct result
    const space_between_consecutive_vertex = (vertex_data_attribute_size + vertex_color_attribute_size) * size_of_vertex_datatype;
    // the offset of where the position begins in the buffer
    //in our case the offset is at 0 the begining of the array buffer
    const position_data_start_offset = null; // @intToPtr(*c_void, 0);
    c.glVertexAttribPointer(vertex_data_attribute_location, vertex_data_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex, position_data_start_offset);
    c.glEnableVertexAttribArray(vertex_data_attribute_location);

    const vertex_color_attribute_location = 1;
    //This is to give the offset of the color in the vertex buffer
    //The color is at the 3 position .NOTE: counting from 0 for arrays
    //and each of this vertices have a size of size_of_vertex_datatype
    //meaning for each vertex our color data start from the 3rd data in the
    //buffer .ie [0,1,2,3,4,5] color data start from 3 - 5 for each vertex
    const position_color_start_offset = @intToPtr(*anyopaque, vertex_color_attribute_size * size_of_vertex_datatype);
    c.glVertexAttribPointer(vertex_color_attribute_location, vertex_color_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex, position_color_start_offset);
    c.glEnableVertexAttribArray(vertex_color_attribute_location);
}

pub fn deinitRectangleBuffers() void {
    for (vertex.vbo) |vbo| {
        defer c.glDeleteBuffers(1, &vbo);
    }
    defer c.glDeleteBuffers(1, &vertex.ebo);
    defer c.glDeleteVertexArrays(1, &vertex.vao); //1 is the vao id
}

pub fn setUniformInShader(shader_program: Shader) void {
    const time_value: f64 = c.glfwGetTime();
    // for varing the green color continuously from green to black and again
    const green_value = (std.math.sin(time_value) / 2) + 0.5;
    shader_program.setUniform("vertex_color", Vec4, vec4(0.0, @floatCast(f32, green_value), 0.0, 1.0));
}
pub fn setTransformation(shader_program: Shader) void {
    const translation = glm.translation(vec3(0.5, -0.5, 0.0));
    const rotation = glm.rotation(@floatCast(f32, c.glfwGetTime()), vec3(0.0, 0.0, 1.0));
    const transformation = translation.matmul(rotation);
    shader_program.setUniform("transformation", Mat4, transformation);
    const number_of_indices_to_draw = 6;
    c.glDrawElements(c.GL_TRIANGLES, number_of_indices_to_draw, c.GL_UNSIGNED_INT, null);
}

pub fn set3dTransformatin(shader_program: Shader) void {
    //rotate the local space to the world space
    const model = glm.rotation(glm.radian(-55.0), vec3(1.0, 0.0, 0.0));
    //move the world space backward into to the view space along the -z plane
    const view_backward = glm.translation(vec3(0.0, 0.0, -3.0));
    //project our view space to clip space along the 45* fov
    const perspective_width = 800.0;
    const perspective_height = 600.0;
    const aspect_ratio = perspective_width / perspective_height;
    const near_of_fustrum = 0.1;
    const far_of_fustrum = 100.0;
    const projection = glm.perspective(45.0, aspect_ratio, near_of_fustrum, far_of_fustrum);
    //set uniforms in vertex shader
    shader_program.setUniform("model", Mat4, model);
    shader_program.setUniform("view", Mat4, view_backward);
    shader_program.setUniform("projection", Mat4, projection);
    const number_of_indices_to_draw = 6;
    c.glDrawElements(c.GL_TRIANGLES, number_of_indices_to_draw, c.GL_UNSIGNED_INT, null);
}
