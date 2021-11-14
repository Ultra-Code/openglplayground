const std = @import("std");
usingnamespace @import("cimports.zig");

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

const shader = @import("shader.zig").Shader;
const draw_rectangle = @import("draw_rectangle.zig");

pub fn main() !void {
    if (glfwInit() == GLFW_FALSE) {
        // Initialization failed
        std.log.err("Initialization of glfw failed", .{});
    }
    defer glfwTerminate();
    setOpenglVersion();
    var window = initializeWindow();
    registerCallbackFunctions(window);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = &gpa.allocator;

    const shader_program = try shader.init(allocator, "shaders/rectangle.vert", "shaders/rectangle.frag");
    defer glDeleteProgram(shader_program.program_id);

    const vertex_vao = draw_rectangle.storeVboOnGpu();
    defer draw_rectangle.deinitRectangleBuffers();

    while (glfwWindowShouldClose(window) == GLFW_FALSE) {
        processUserInput(window);

        glClearColor(0.2, 0.3, 0.3, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);

        shader_program.useShader();
        glBindVertexArray(vertex_vao);
        //updating the uniform requires using the shader_program because it
        //sets the uniform on the current active shader's shader_program
        //draw_rectangle.setUniformInShader(shader_program);
        //const vertex_data_start = 0;
        //const number_of_vertices_to_draw = 3;
        //glDrawArrays(GL_TRIANGLES, vertex_data_start, number_of_vertices_to_draw);
        const number_of_indices_to_draw = 6;
        glDrawElements(GL_TRIANGLES, number_of_indices_to_draw, GL_UNSIGNED_INT, null);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }
}
