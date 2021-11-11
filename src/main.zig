const std = @import("std");
usingnamespace @import("c_imports.zig");

const WIDTH = 680;
const HEIGHT = 640;

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
        std.log.err("Failed to create a GLFW window \n", .{});
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

pub fn compileShader(shader_type: c_uint, shader_source: [*:0]const u8) c_uint {
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

pub fn linkShaders(vertex_shader: c_uint, fragment_shader: c_uint) c_uint {
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

const shader = @import("shader.zig");
const draw_rectangle = @import("draw_rectangle.zig");

pub fn main() void {
    if (glfwInit() == GLFW_FALSE) {
        // Initialization failed
        std.log.err("Initialization of glfw failed", .{});
    }
    defer glfwTerminate();
    setOpenglVersion();
    var window = initializeWindow();
    registerCallbackFunctions(window);
    shader.getMaximumNumberOfVertexAttributes();

    const shader_program = draw_rectangle.rectangleShaderProgram();
    defer glDeleteProgram(shader_program);

    const vertex_vao = draw_rectangle.storeVboOnGpu();
    defer draw_rectangle.deinitRectangleBuffers();

    while (glfwWindowShouldClose(window) == GLFW_FALSE) {
        processUserInput(window);

        glClearColor(0.2, 0.3, 0.3, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        glUseProgram(shader_program);
        glBindVertexArray(vertex_vao);
        //updating the uniform requires using the shader_program because it
        //sets the uniform on the current active shader's shader_program
        draw_rectangle.setUniformInShader(shader_program);
        //        const vertex_data_start = 0;
        //        const number_of_vertices_to_draw = 3;
        //        glDrawArrays(GL_TRIANGLES, vertex_data_start, number_of_vertices_to_draw);
        const number_of_indices_to_draw = 6;
        glDrawElements(GL_TRIANGLES, number_of_indices_to_draw, GL_UNSIGNED_INT, null);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }
}
