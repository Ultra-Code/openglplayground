const std = @import("std");
const c = @import("cimports.zig");
const Camera = @import("camera.zig").Camera;

// settings
pub const WIDTH = 1920.0;
pub const HEIGHT = 1080.0;

pub var camera = Camera.default();
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

    //tell GLFW that it should hide the cursor and capture it meaning
    //once the application has focus, the mouse cursor stays within the center of the window
    c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);

    std.log.info("OpenGL {s}, GLSL {s}\n", .{ c.glGetString(c.GL_VERSION), c.glGetString(c.GL_SHADING_LANGUAGE_VERSION) });

    return window.?;
}

// c.glfw: whenever the window size changed (by OS or user resize) this callback function executes
fn framebufferSizeCallback(
    _: ?*c.GLFWwindow, //window
    width: c_int,
    height: c_int,
) callconv(.C) void {
    // make sure the viewport matches the new window dimensions; note that width and
    // height will be significantly larger than specified on retina displays.
    c.glViewport(0, 0, width, height);
}

//initialize last cursor position to the center of the screen
var last_x: f64 = WIDTH / 2.0;
var last_y: f64 = HEIGHT / 2.0;

// glfw: whenever the mouse moves, this callback is called
pub fn mouseCallback(_: ?*c.GLFWwindow, xpos: f64, ypos: f64) callconv(.C) void {
    const x_offset = xpos - last_x;
    const y_offset = last_y - ypos; //reversed: y ranges is bottom to top

    //update last_x and last_y
    last_x = xpos;
    last_y = ypos;
    camera.cameraMovementWithMouse(@floatCast(f32, x_offset), @floatCast(f32, y_offset));
}

// glfw: whenever the mouse scroll wheel scrolls, this callback is called
pub fn scrollCallback(_: ?*c.GLFWwindow, _: f64, yoffset: f64) callconv(.C) void {
    camera.cameraZooming(@floatCast(f32, yoffset));
}

fn registerCallbackFunctions(window: *c.GLFWwindow) void {
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    _ = c.glfwSetCursorPosCallback(window, mouseCallback);
    _ = c.glfwSetScrollCallback(window, scrollCallback);
}

//Balance out camera movement speed
var last_frame_time: f32 = 0.0;
var delta_time: f32 = 0.0;

fn getDeltaTime() f32 {
    const current_frame_time = @floatCast(f32, c.glfwGetTime());
    //Time diff between current frame and last frame
    //it balances out frame rate to velocity of camera .ie if the last frame took forever to render the delta_time
    //value will increase we use this info to increase the velocity/speed of the camera to offset the previous lag
    const delta = current_frame_time - last_frame_time;
    last_frame_time = current_frame_time;
    return delta;
}

// process all input: query c.GLFW whether relevant keys are pressed/released this frame and react accordingly
fn processUserInput(window: *c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
    if (c.glfwGetKey(window, c.GLFW_KEY_W) == c.GLFW_PRESS)
        camera.cameraMovementWithKeyboard(.Forward, delta_time);
    if (c.glfwGetKey(window, c.GLFW_KEY_S) == c.GLFW_PRESS)
        camera.cameraMovementWithKeyboard(.Backward, delta_time);
    if (c.glfwGetKey(window, c.GLFW_KEY_A) == c.GLFW_PRESS)
        camera.cameraMovementWithKeyboard(.Left, delta_time);
    if (c.glfwGetKey(window, c.GLFW_KEY_D) == c.GLFW_PRESS)
        camera.cameraMovementWithKeyboard(.Right, delta_time);
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

    draw_box.store3dBoxOnGpu();
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
        //delta_time must be calculated per render loop
        delta_time = getDeltaTime();
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
        draw_box.rotate10boxes(shader_program);

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
