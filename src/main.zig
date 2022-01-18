const std = @import("std");
const c = @import("cimports.zig");

pub const WIDTH = 800;
pub const HEIGHT = 600;

fn setOpenglVersion() void {
    const major = 4;
    const minor = 6;

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, major);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, minor);
    // Means not to use backward compatibility features
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
}

fn initializeWindow() *c.GLFWwindow {
    var window: ?*c.GLFWwindow = c.glfwCreateWindow(WIDTH, HEIGHT, "First Step Into OpenGL", null, null);
    if (window == null) {
        // Window or OpenGL context creation failed
        c.glfwTerminate();
        std.log.err("Failed to create a GLFW window \n", .{});
    }
    c.glfwMakeContextCurrent(window);
    std.log.info("OpenGL {s}, GLSL {s}\n", .{ c.glGetString(c.GL_VERSION), c.glGetString(c.GL_SHADING_LANGUAGE_VERSION) });

    return window.?;
}

fn framebufferSizeCallback(
    _: ?*c.GLFWwindow, //window
    width: c_int,
    height: c_int,
) callconv(.C) void {
    c.glViewport(0, 0, width, height);
}

fn registerCallbackFunctions(window: *c.GLFWwindow) void {
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
}

fn processUserInput(window: *c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
    const processCameraMovement = @import("draw_box.zig").processCameraMovement;
    processCameraMovement(window);
}

const shader = @import("shader.zig").Shader;
const draw_box = @import("draw_box.zig");
const texture = @import("texture.zig");

pub fn main() !void {
    if (c.glfwInit() == c.GLFW_FALSE) {
        // Initialization failed
        std.log.err("Initialization of glfw failed", .{});
    }
    defer c.glfwTerminate();
    setOpenglVersion();
    var window = initializeWindow();
    registerCallbackFunctions(window);

    // configure global opengl state
    c.glEnable(c.GL_DEPTH_TEST);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // build and compile our shader program
    const shader_program = try shader.init(allocator, "shaders/rectangle.vert", "shaders/rectangle.frag");
    defer c.glDeleteProgram(shader_program.program_id);

    const vertex_vao = draw_box.store3dBoxOnGpu();
    defer draw_box.deinit3dBoxBuffers();

    // load and create a texture
    const container_texture_obj = texture.genTextureFromImage("assets/texture/container.jpg", c.GL_RGB);
    //png images have alpha chanels so image color type is GL_RGBA
    const smilelyface_texture_obj = texture.genTextureFromImage("assets/texture/awesomeface.png", c.GL_RGBA);

    // tell opengl for each sampler to which texture unit it belongs to (only has to be done once)
    shader_program.useShader(); // don't forget to activate/use the shader before setting uniforms!
    //set uniform to match the texture units in the fragment shader
    shader_program.setUniform("container_texture_obj", u8, 0);
    shader_program.setUniform("smilelyface_texture_obj", u8, 1);

    //render loop
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        // input
        processUserInput(window);

        // render
        c.glClearColor(0.2, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        //bind textures on corresponding texture units
        //location of a texture is  known as a texture unit. The default texture unit for a texture is 0
        //which is the default active texture unit if none is activated
        //but one can be manually activated a texture unit with glActiveTexture
        c.glActiveTexture(c.GL_TEXTURE0); // activate texture unit first
        c.glBindTexture(c.GL_TEXTURE_2D, container_texture_obj);

        c.glActiveTexture(c.GL_TEXTURE1);
        c.glBindTexture(c.GL_TEXTURE_2D, smilelyface_texture_obj);

        //reactivate shader per each render call/frame because transformations modify uniforms in the vertex shader
        shader_program.useShader();
        c.glBindVertexArray(vertex_vao);
        draw_box.rotate10boxes(shader_program);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
