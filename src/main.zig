const std = @import("std");
const panic = std.debug.panic;
usingnamespace @import("c_imports.zig");

const WIDTH = 680;
const HEIGHT = 640;

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

fn setOpenglVersion() void {
    const major = 4;
    const minor = 6;

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, major);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, minor);
    // Means not to use backward compatibility features
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
}

fn initializeWindow() *GLFWwindow {
    var window: ?*GLFWwindow = glfwCreateWindow(WIDTH, HEIGHT, "First Step Into OpenGL", null, null);
    if (window == null) {
        // Window or OpenGL context creation failed
        glfwTerminate();
        panic("Failed to create a GLFW window \n", .{});
    }
    glfwMakeContextCurrent(window);
    std.log.info("OpenGL {s}, GLSL {s}\n", .{ glGetString(GL_VERSION), glGetString(GL_SHADING_LANGUAGE_VERSION) });

    return window.?;
}

fn framebufferSizeCallback(window: ?*GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    glViewport(0, 0, width, height);
}

fn registerCallbackFunctions(window: *GLFWwindow) void {
    _ = glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
}

fn processUserInput(window: *GLFWwindow) void {
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
        glfwSetWindowShouldClose(window, GLFW_TRUE);
    }
}

fn shaderCompileErrorHandling(shader_obj: c_uint) void {
    // check for shader errors
    var shader_compile_state: c_int = undefined;
    const info_log_size = 512;
    var shader_info_log: [*:0]u8 = undefined;

    glGetShaderiv(shader_obj, GL_COMPILE_STATUS, &shader_compile_state);

    if (shader_compile_state == GL_FALSE) {
        glGetShaderInfoLog(shader_obj, info_log_size, null, shader_info_log);
        std.log.err("ERROR::SHADER::COMPILATION_FAILED : {s}\n", .{shader_info_log});
        std.debug.panic("Error compiling the shader object {}\nFix any syntax error in the shader_source", .{shader_obj});
    }
}

fn compileShader(shader_type: c_uint, shader_source: [*:0]const u8) c_uint {
    // shader_type specify the type of the shader which could be
    // GL_VERTEX_SHADER or GL_FRAGMENT_SHADER ...
    const shader_obj: c_uint = glCreateShader(shader_type);
    const number_of_shaders = 1;
    //specify the shader to link to the vertex_shader_obj
    glShaderSource(shader_obj, number_of_shaders, &shader_source, null);
    glCompileShader(shader_obj);
    shaderCompileErrorHandling(shader_obj);
    return shader_obj;
}

fn linkShaders(vertex_shader: c_uint, fragment_shader: c_uint) c_uint {
    const shader_program_obj = glCreateProgram();
    glAttachShader(shader_program_obj, vertex_shader);
    glAttachShader(shader_program_obj, fragment_shader);
    glLinkProgram(shader_program_obj);
    linkShaderErrorHandling(shader_program_obj);
    return shader_program_obj;
}

fn linkShaderErrorHandling(shader_obj: c_uint) void {
    var shader_link_state: c_int = undefined;
    const info_log_size = 512;
    var shader_link_info_log: [*:0]u8 = undefined;
    glGetProgramiv(shader_obj, GL_LINK_STATUS, &shader_link_state);
    if (shader_link_state == GL_FALSE) {
        glGetProgramInfoLog(shader_obj, info_log_size, null, shader_link_info_log);
        std.log.err("ERROR::SHADER::LINKING_FALIED : {s}\n", .{shader_link_info_log});
        std.debug.panic("Fix the output of the previous shader to match the input of current shader {}", .{shader_obj});
    }
}
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

fn storeVboOnGpu() Vertex {
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
    const vertex = Vertex{ .vbo = vbo, .vao = vao, .ebo = ebo };
    return vertex;
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

pub fn main() void {
    if (glfwInit() == GLFW_FALSE) {
        // Initialization failed
        panic("Initialization of glfw failed", .{});
    }
    defer glfwTerminate();
    setOpenglVersion();
    var window = initializeWindow();
    registerCallbackFunctions(window);

    const vertex_shader = compileShader(GL_VERTEX_SHADER, vertex_shader_source);
    const fragment_shader = compileShader(GL_FRAGMENT_SHADER, fragment_shader_source);

    const shader_program = linkShaders(vertex_shader, fragment_shader);
    defer glDeleteShader(vertex_shader);
    defer glDeleteShader(fragment_shader);
    defer glDeleteProgram(shader_program);

    const vertex = storeVboOnGpu();
    defer glDeleteBuffers(1, &vertex.vbo);
    defer glDeleteBuffers(1, &vertex.ebo);
    defer glDeleteVertexArrays(1, &vertex.vao); //1 is the vao id
    std.debug.print("drawing_index_order has a lenght of {d}\n", .{@sizeOf(@TypeOf(drawing_index_order))});

    while (glfwWindowShouldClose(window) == GLFW_FALSE) {
        processUserInput(window);

        glClearColor(0.2, 0.3, 0.3, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        glUseProgram(shader_program);
        glBindVertexArray(vertex.vao);
        //        const vertex_data_start = 0;
        //        const number_of_vertices_to_draw = 3;
        //        glDrawArrays(GL_TRIANGLES, vertex_data_start, number_of_vertices_to_draw);
        const number_of_indices_to_draw = 6;
        glDrawElements(GL_TRIANGLES, number_of_indices_to_draw, GL_UNSIGNED_INT, null);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }
}
