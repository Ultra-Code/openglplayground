const std = @import("std");
const main = @import("main.zig");
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

pub fn store3dBoxOnGpu() void {
    const vo_num = 1;
    //vertex array object for holding vertex and c.glVertexAttribPointer configurations
    //set up vertex data (and buffer(s))
    var vao: c_uint = undefined;
    c.glGenVertexArrays(vo_num, &vao);

    var vbo: c_uint = undefined;
    c.glGenBuffers(vo_num, &vbo);

    c.glBindVertexArray(vao);
    //specify buffer type
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    //copy the vertices_of_3D_box into the vbo's memory with target type c.GL_ARRAY_BUFFER
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices_of_3D_box)), &vertices_of_3D_box, c.GL_STATIC_DRAW);

    // configure vertex attributes
    map3dBoxVertexToAttribute();
    vertex = .{ .vbo = vbo, .vao = vao };
}

fn map3dBoxVertexToAttribute() void {
    // layout(location = 0).in our vertex shader for our box3D attribute
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

    // position attribute
    c.glVertexAttribPointer(vertex_data_attribute_location, vertex_data_attribute_size, vertex_data_type, normalize_vertex_data, space_between_consecutive_vertex, data_start_offset);
    c.glEnableVertexAttribArray(vertex_data_attribute_location);

    const vertex_texture_coordinate_attribute_location = 1;
    //This is to give the offset of the texture coordinates in the vertices_of_3D_box buffer.The texture coords
    //starts at the 3 position .NOTE: counting from 0 for arrays and each of this vertices have a size of size_of_single_data_in_vertex
    //meaning for each vertex our texture coordinates data start from the 3rd data in the buffer .ie [0,1,2,3,4] color data start from 3 to 4 for each vertex
    const texture_coordinate_start_offset = @intToPtr(*anyopaque, vertex_data_attribute_size * size_of_single_data_in_vertex);

    // texture coord attribute
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
    //aspect_ratio must be a f32 so WIDTH and HEIGHT must be f32.
    //NOTE: with integer aspect_ratio the fustrum is jagguled improporsionally , artefacts look streched or unbalanced especially with higher resolution
    const perspective_width = main.WIDTH;
    const perspective_height = main.HEIGHT;
    const aspect_ratio = perspective_width / perspective_height;
    const near_of_fustrum = 0.1;
    const far_of_fustrum = 100.0;
    const projection = glm.perspective(glm.radian(45.0), aspect_ratio, near_of_fustrum, far_of_fustrum);
    //set uniforms in vertex shader
    shader_program.setUniform("model", Mat4, model);
    shader_program.setUniform("view", Mat4, view_backward);
    shader_program.setUniform("projection", Mat4, projection);
    c.glBindVertexArray(vertex.vao);
    const vertex_data_start = 0;
    const number_of_vertices_to_draw = 36;
    c.glDrawArrays(c.GL_TRIANGLES, vertex_data_start, number_of_vertices_to_draw);
}

pub fn rotate10boxes(shader_program: Shader) void {
    // world space positions of our cubes
    const cubePositions = [10]glm.Vec3{
        vec3(0.0, 0.0, 0.0),
        vec3(2.0, 5.0, -15.0),
        vec3(-1.5, -2.2, -2.5),
        vec3(-3.8, -2.0, -12.3),
        vec3(2.4, -0.4, -3.5),
        vec3(-1.7, 3.0, -7.5),
        vec3(1.3, -2.0, -2.5),
        vec3(1.5, 2.0, -2.5),
        vec3(1.5, 0.2, -1.5),
        vec3(-1.3, 1.0, -1.5),
    };

    // create transformations
    var camera = main.camera;
    const view_around = camera.walkAroundScene();
    //project our view space to clip space along the 45* fov
    const perspective_width = main.WIDTH;
    const perspective_height = main.HEIGHT;
    const aspect_ratio = perspective_width / perspective_height;
    const near_of_fustrum = 0.1;
    const far_of_fustrum = 100.0;
    const projection = glm.perspective(camera.fov(), aspect_ratio, near_of_fustrum, far_of_fustrum);

    // pass transformation matrices to the shader
    // note: currently we set the projection matrix each frame, but since the projection matrix
    // rarely changes it's often best practice to set it outside the main loop only once.
    shader_program.setUniform("projection", Mat4, projection);
    shader_program.setUniform("view", Mat4, view_around);
    // render boxes
    c.glBindVertexArray(vertex.vao);
    for (cubePositions) |cube, index| {
        // calculate the model matrix for each object and pass it to shader before drawing
        const model_translation = glm.translation(cube);
        const angle = 20.0 * @intToFloat(f32, index);
        const model_rotation = glm.rotation(glm.radian(angle), vec3(1.0, 0.3, 0.5));
        const model = model_translation.matmul(model_rotation);
        shader_program.setUniform("model", Mat4, model);
        const vertex_data_start = 0;
        const number_of_vertices_to_draw = 36;
        c.glDrawArrays(c.GL_TRIANGLES, vertex_data_start, number_of_vertices_to_draw);
    }
}
