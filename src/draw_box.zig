const std = @import("std");
const c = @import("cimports.zig");
const Shader = @import("shader.zig").Shader;
const glm = @import("glm.zig");
const Mat4 = glm.Mat4;
const vec3 = glm.vec3;
// set up vertex data (and buffer(s)) and configure vertex attributes
const vertices_of_3D_box = [36][5]f32{
    //positions            //texture coords
    //face1
    [_]f32{ -0.5, -0.5, -0.5, 0.0, 0.0 },
    [_]f32{ 0.5, -0.5, -0.5, 1.0, 0.0 },
    [_]f32{ 0.5, 0.5, -0.5, 1.0, 1.0 },
    [_]f32{ 0.5, 0.5, -0.5, 1.0, 1.0 },
    [_]f32{ -0.5, 0.5, -0.5, 0.0, 1.0 },
    [_]f32{ -0.5, -0.5, -0.5, 0.0, 0.0 },

    //face2
    [_]f32{ -0.5, -0.5, 0.5, 0.0, 0.0 },
    [_]f32{ 0.5, -0.5, 0.5, 1.0, 0.0 },
    [_]f32{ 0.5, 0.5, 0.5, 1.0, 1.0 },
    [_]f32{ 0.5, 0.5, 0.5, 1.0, 1.0 },
    [_]f32{ -0.5, 0.5, 0.5, 0.0, 1.0 },
    [_]f32{ -0.5, -0.5, 0.5, 0.0, 0.0 },

    //face3
    [_]f32{ -0.5, 0.5, 0.5, 1.0, 0.0 },
    [_]f32{ -0.5, 0.5, -0.5, 1.0, 1.0 },
    [_]f32{ -0.5, -0.5, -0.5, 0.0, 1.0 },
    [_]f32{ -0.5, -0.5, -0.5, 0.0, 1.0 },
    [_]f32{ -0.5, -0.5, 0.5, 0.0, 0.0 },
    [_]f32{ -0.5, 0.5, 0.5, 1.0, 0.0 },

    //face4
    [_]f32{ 0.5, 0.5, 0.5, 1.0, 0.0 },
    [_]f32{ 0.5, 0.5, -0.5, 1.0, 1.0 },
    [_]f32{ 0.5, -0.5, -0.5, 0.0, 1.0 },
    [_]f32{ 0.5, -0.5, -0.5, 0.0, 1.0 },
    [_]f32{ 0.5, -0.5, 0.5, 0.0, 0.0 },
    [_]f32{ 0.5, 0.5, 0.5, 1.0, 0.0 },

    //face5
    [_]f32{ -0.5, -0.5, -0.5, 0.0, 1.0 },
    [_]f32{ 0.5, -0.5, -0.5, 1.0, 1.0 },
    [_]f32{ 0.5, -0.5, 0.5, 1.0, 0.0 },
    [_]f32{ 0.5, -0.5, 0.5, 1.0, 0.0 },
    [_]f32{ -0.5, -0.5, 0.5, 0.0, 0.0 },
    [_]f32{ -0.5, -0.5, -0.5, 0.0, 1.0 },

    //face6
    [_]f32{ -0.5, 0.5, -0.5, 0.0, 1.0 },
    [_]f32{ 0.5, 0.5, -0.5, 1.0, 1.0 },
    [_]f32{ 0.5, 0.5, 0.5, 1.0, 0.0 },
    [_]f32{ 0.5, 0.5, 0.5, 1.0, 0.0 },
    [_]f32{ -0.5, 0.5, 0.5, 0.0, 0.0 },
    [_]f32{ -0.5, 0.5, -0.5, 0.0, 1.0 },
};
const Vertex = struct { vbo: c_uint, vao: c_uint };

var vertex: Vertex = undefined;

pub fn store3dBoxOnGpu() c_uint {
    const vo_num = 1;
    //vertex array object for holding vertex and c.glVertexAttribPointer
    //configurations
    var vao: c_uint = undefined;
    c.glGenVertexArrays(vo_num, &vao);

    var vbo: c_uint = undefined;
    c.glGenBuffers(vo_num, &vbo);

    c.glBindVertexArray(vao);
    //specify buffer type
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    //copy the vertices_of_3D_box into the vbo's memory with target type c.GL_ARRAY_BUFFER
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices_of_3D_box)), &vertices_of_3D_box, c.GL_STATIC_DRAW);

    map3dBoxVertexToAttribute();
    vertex = .{ .vbo = vbo, .vao = vao };
    return vao;
}

fn map3dBoxVertexToAttribute() void {
    // layout(location = 4).in our vertex shader for our box3D attribute
    const vertex_data_attribute_location = 0;
    // our in attribute data we have 3 values x,y,z for triangle coordinates and type  vec3
    const vertex_data_attribute_size = 3;
    //the texture coordinates are the next 2 values after the x,y,z values
    const vertex_texture_coordinate_attribute_size = 2;
    const vertex_data_type = c.GL_FLOAT;
    const normalize_vertex_data = c.GL_FALSE; // data is already in NDC
    //eg. size of a single data of our vertex data is f32 which is equivalent to 4byte
    const size_of_single_data_in_vertex = @sizeOf(@TypeOf(vertices_of_3D_box[0][0]));
    //specify the size of the consecutive columns of the input data.If the vertex attributes receive data from the same input
    //The consecutive spaces is call stride.NOTE we could specify 0 for opengl to detect the stide but this only works if our buffer is tightly pack
    //NOTE: here the + operator must have higher precedence over the * operator for correct result
    const space_between_consecutive_vertex = (vertex_data_attribute_size + vertex_texture_coordinate_attribute_size) * size_of_single_data_in_vertex;
    //the offset of where the position begins in the buffer in our case the offset is at 0 the begining of the array buffer
    const data_start_offset = null; // @intToPtr(*c_void, 0);
    c.glVertexAttribPointer(vertex_data_attribute_location, vertex_data_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex, data_start_offset);
    c.glEnableVertexAttribArray(vertex_data_attribute_location);

    const vertex_texture_coordinate_attribute_location = 1;
    //This is to give the offset of the texture coordinates in the vertices_of_3D_box buffer.The texture coords
    //starts at the 3 position .NOTE: counting from 0 for arrays and each of this vertices have a size of size_of_single_data_in_vertex
    //meaning for each vertex our texture coordinates data start from the 3rd data in the buffer .ie [0,1,2,3,4] color data start from 3 - 4 for each vertex
    const texture_coordinate_start_offset = @intToPtr(*anyopaque, vertex_texture_coordinate_attribute_size * size_of_single_data_in_vertex);
    c.glVertexAttribPointer(vertex_texture_coordinate_attribute_location, vertex_texture_coordinate_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex, texture_coordinate_start_offset);
    c.glEnableVertexAttribArray(vertex_texture_coordinate_attribute_location);
}

pub fn deinit3dBoxBuffers() void {
    defer c.glDeleteBuffers(1, &vertex.vbo);
    defer c.glDeleteVertexArrays(1, &vertex.vao); //1 is the vao id
}

pub fn rotate3dBox(shader_program: Shader) void {
    //rotate the local space to the world space
    const model = glm.rotation(@floatCast(f32, c.glfwGetTime()) * glm.radian(50.0), vec3(0.5, 1.0, 0.0));
    //move the world space backward into to the view space along the -z plane
    const view_backward = glm.translation(vec3(0.0, 0.0, -4.0));
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
}
