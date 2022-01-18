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
    return vao;
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
    const perspective_width = 800.0;
    const perspective_height = 600.0;
    const aspect_ratio = perspective_width / perspective_height;
    const near_of_fustrum = 0.1;
    const far_of_fustrum = 100.0;
    const projection = glm.perspective(glm.radian(45.0), aspect_ratio, near_of_fustrum, far_of_fustrum);
    //set uniforms in vertex shader
    shader_program.setUniform("model", Mat4, model);
    shader_program.setUniform("view", Mat4, view_backward);
    shader_program.setUniform("projection", Mat4, projection);
    const vertex_data_start = 0;
    const number_of_vertices_to_draw = 36;
    c.glDrawArrays(c.GL_TRIANGLES, vertex_data_start, number_of_vertices_to_draw);
}

fn rotateCamAroundScene() Mat4 {
    //opengl uses the right handed coordinate system with middle finger(+z plane) pointing to u
    //index finger(+y plane) pointing up and thumb (+x plane) pointing to you right
    //moving in the +z plane which is equivalent to moving the camera backward moves the scene rather backwards
    //NOTE: lookAt rotate and translate the world/scene in the opposite direction of where we want the camera to move
    const view_radius = 10.0;
    const cam_x = std.math.sin(@floatCast(f32, c.glfwGetTime())) * view_radius;
    const cam_y = std.math.cos(@floatCast(f32, c.glfwGetTime())) * view_radius;
    const view_around = glm.lookAt(vec3(cam_x, 0.0, cam_y), vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));
    return view_around;
}

//Camera/View/Eye space matrix transformations
//we move the camera back 6 units which is equivalent to moving the scene back 6 units
//for better view of the whole scene
var cam_position = glm.vec3(0.0, 0.0, 6.0);
//by default the camera is positioned to point in the +z axis which is pointing to u
//but because by convention (in OpenGL) the camera should points towards the negative z-axis
//so we flip the points into the -z plane towards the scene so that we can get the
//feeling of moving around the scene from our eye perspective == camera
var cam_front = glm.vec3(0.0, 0.0, -1.0);
//cam_up specifies the movement of the camera in the vertical plane
var cam_up = glm.vec3(0.0, 1.0, 0.0);

///move around the scene
fn walkAroundScene() Mat4 {
    //the direction of the camera(where the camera is looking) is the current position(cam_position) + the direction vector(cam_front)
    //This ensures that no matter how we move, the camera keeps looking at the target direction(cam_front)
    const move_around = glm.lookAt(cam_position, cam_position.add(cam_front), cam_up);
    return move_around;
}

//Balance out camera movement speed
var last_frame_time: f32 = 0.0;

fn getDeltaTime() f32 {
    const current_frame_time = @floatCast(f32, c.glfwGetTime());
    //Time diff between current frame and last frame
    //it balances out frame rate to velocity of camera .ie if the last frame took forever to render the delta_time
    //value will increase we use this info to increase the velocity/speed of the camera to offset the previous lag
    const delta_time = current_frame_time - last_frame_time;
    last_frame_time = current_frame_time;
    return delta_time;
}

pub fn processCameraMovement(window: *c.GLFWwindow) void {
    //speed of camera movement
    const camera_speed = 3 * getDeltaTime();

    //Moving Foward
    // cam_position += camera_speed * cam_front;
    // cam_front * camera_speed increases the z component of cam_front
    //eg vec3(0.0,0.0,-1.0) * 0.1 == vec3(0.0,0.0,-0.1) .ie the z axis has been increased from -1.0 to -0.1
    //adding vec3(0.0,0.0,-0.1) to cam_position decreases the z component by 0.1 moving the camera towards the scene
    if (c.glfwGetKey(window, c.GLFW_KEY_W) == c.GLFW_PRESS) {
        cam_position = cam_position.add(cam_front.mulScalar(camera_speed));
    }
    //Moving Backward
    // cam_position -= camera_speed * cam_front;
    //The same process happen for camera_speed * cam_front till the point of subtraction
    //subtracting vec3(0.0,0.0,-0.1) from cam_position .ie cam_position - vec3(0.0,0.0,-0.1)
    // - - 0.1 == 0.1 increasing the z-axis by 0.1 moving the camera away from the scene
    if (c.glfwGetKey(window, c.GLFW_KEY_S) == c.GLFW_PRESS) {
        cam_position = cam_position.sub(cam_front.mulScalar(camera_speed));
    }
    //Moving leftsided
    // cam_position -= cam_front.cross(cam_up) * camera_speed;
    //Then we do a cross product of the direction vector(cam_front) on the up vector(cam_up)
    //the result of a cross product is a vector perpendicular to both vectors
    //.ie we will get a vector that points in the positive x-axis’s direction .eg cam_front.cross(cam_up) == (1.0,-0.0,0.0)
    //cam_position - (1.0,-0.0,0.0) would decrease the x-axis of cam_position moving camera to the left
    if (c.glfwGetKey(window, c.GLFW_KEY_A) == c.GLFW_PRESS) {
        // cam_position -= cam_front.cross(cam_up) * camera_speed;
        //OR
        //cam_position += cam_up.cross(cam_front) * camera_speed
        //NOTE: cam_up.cross(cam_front) produces a vec3 in the -x axis (-1.0,0.0,0.0) so we can add it to cam_position to move the camera left
        // cam_position = cam_position.add(cam_up.cross(cam_front).mulScalar(camera_speed));
        cam_position = cam_position.sub(cam_front.cross(cam_up).mulScalar(camera_speed));
    }
    //Moving Rightsided
    //Like Moving leftsided above but adding (1.0,-0.0,0,0) to cam_position increases the x-axis component of cam_position
    //moving the camera to the right
    if (c.glfwGetKey(window, c.GLFW_KEY_D) == c.GLFW_PRESS) {
        // cam_position += cam_front.cross(cam_up) * camera_speed;
        cam_position = cam_position.add(cam_front.cross(cam_up).mulScalar(camera_speed));
    }
}

pub fn rotate10boxes(shader_program: Shader) void {
    // world space positions of our cubes
    const cubePositions = [10]glm.Vec3{
        glm.vec3(0.0, 0.0, 0.0),
        glm.vec3(2.0, 5.0, -15.0),
        glm.vec3(-1.5, -2.2, -2.5),
        glm.vec3(-3.8, -2.0, -12.3),
        glm.vec3(2.4, -0.4, -3.5),
        glm.vec3(-1.7, 3.0, -7.5),
        glm.vec3(1.3, -2.0, -2.5),
        glm.vec3(1.5, 2.0, -2.5),
        glm.vec3(1.5, 0.2, -1.5),
        glm.vec3(-1.3, 1.0, -1.5),
    };

    // create transformations
    const view_around = walkAroundScene();
    //project our view space to clip space along the 45* fov
    const main = @import("main.zig");
    const perspective_width = main.WIDTH;
    const perspective_height = main.HEIGHT;
    const aspect_ratio = perspective_width / perspective_height;
    const near_of_fustrum = 0.1;
    const far_of_fustrum = 100.0;
    const projection = glm.perspective(glm.radian(45.0), aspect_ratio, near_of_fustrum, far_of_fustrum);

    // pass transformation matrices to the shader
    // note: currently we set the projection matrix each frame, but since the projection matrix
    // rarely changes it's often best practice to set it outside the main loop only once.
    shader_program.setUniform("projection", Mat4, projection);
    shader_program.setUniform("view", Mat4, view_around);

    for (cubePositions) |cube, index| {
        // calculate the model matrix for each object and pass it to shader before drawing
        const model_translation = glm.translation(cube);
        const angle = 20.0 * @intToFloat(f32, index);
        const model_rotation = glm.rotation(glm.radian(angle), glm.vec3(1.0, 0.3, 0.5));
        const model = model_translation.matmul(model_rotation);
        shader_program.setUniform("model", Mat4, model);
        const vertex_data_start = 0;
        const number_of_vertices_to_draw = 36;
        c.glDrawArrays(c.GL_TRIANGLES, vertex_data_start, number_of_vertices_to_draw);
    }
}
