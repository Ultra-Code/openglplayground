const std = @import("std");
usingnamespace @import("cimports.zig");

pub fn getMaximumNumberOfVertexAttributes() void {
    var number_of_attributes: c_int = undefined;
    glGetIntegerv(GL_MAX_VERTEX_ATTRIBS, &number_of_attributes);
    std.log.info(
        \\This hardware can have a maximum of {} vertex attributes in a vertex shader
    , .{number_of_attributes});
}
const Allocator = std.mem.Allocator;

pub const Shader = struct {
    program_id: c_uint,

    const ShaderType = enum(u32) { vertex_shader = GL_VERTEX_SHADER, fragment_shader = GL_FRAGMENT_SHADER };

    pub fn init(allocator: *Allocator, vertex_path: []const u8, fragment_path: []const u8) !Shader {
        // 1. retrieve the vertex/fragment source code from filePath
        const vertex_shader_file = try std.fs.cwd().openFile(vertex_path, .{ .read = true, .write = false });
        defer vertex_shader_file.close();

        var vertex_code_buffer = try allocator.alloc(u8, try vertex_shader_file.getEndPos());
        defer allocator.free(vertex_code_buffer);

        const vertex_size = try vertex_shader_file.read(vertex_code_buffer);
        const vertex_source = try std.cstr.addNullByte(allocator, vertex_code_buffer);

        const fragment_shader_file = try std.fs.cwd().openFile(fragment_path, .{ .read = true, .write = false });
        defer fragment_shader_file.close();

        var fragment_source_buffer = try allocator.alloc(u8, try fragment_shader_file.getEndPos());
        defer allocator.free(fragment_source_buffer);

        const fragment_size = try fragment_shader_file.read(fragment_source_buffer);
        const fragment_source = try std.cstr.addNullByte(allocator, fragment_source_buffer);

        return Shader{ .program_id = shaderProgram(vertex_source, fragment_source) };
    }

    fn shaderProgram(vertex_source: [*:0]const u8, fragment_source: [*:0]const u8) c_uint {
        const vertex_shader = compileShader(GL_VERTEX_SHADER, vertex_source);
        const fragment_shader = compileShader(GL_FRAGMENT_SHADER, fragment_source);

        const shader_program = linkShaders(vertex_shader, fragment_shader);
        defer glDeleteShader(vertex_shader);
        defer glDeleteShader(fragment_shader);
        return shader_program;
    }

    fn compileShader(shader_type: c_uint, shader_source: [*:0]const u8) c_uint {
        // shader_type specify the type of the shader which could be
        // GL_VERTEX_SHADER or GL_FRAGMENT_SHADER ...
        const shader_obj: c_uint = glCreateShader(shader_type);
        const number_of_shaders = 1;
        //specify the shader to link to the vertex_shader_obj
        glShaderSource(shader_obj, number_of_shaders, &shader_source, null);
        glCompileShader(shader_obj);
        checkShaderCompileErrors(shader_obj, shader_type);
        return shader_obj;
    }

    fn linkShaders(vertex_shader: c_uint, fragment_shader: c_uint) c_uint {
        const shader_program_obj = glCreateProgram();
        glAttachShader(shader_program_obj, vertex_shader);
        glAttachShader(shader_program_obj, fragment_shader);
        glLinkProgram(shader_program_obj);
        checkShaderLinkErrors(shader_program_obj);
        return shader_program_obj;
    }

    fn checkShaderCompileErrors(shader_obj: c_uint, shader_type: c_uint) void {
        // check for shader errors
        var shader_state: c_int = undefined;
        const info_log_size = 512;
        var shader_info_log: [info_log_size:0]u8 = undefined;

        glGetShaderiv(shader_obj, GL_COMPILE_STATUS, &shader_state);
        if (shader_state == GL_FALSE) {
            glGetShaderInfoLog(shader_obj, info_log_size, null, &shader_info_log);
            if (shader_type == @enumToInt(ShaderType.vertex_shader)) {
                std.log.err("ERROR::VERTEX::SHADER::COMPILATION_FAILED : {s}", .{shader_info_log});
            } else { //error_type == @enumToInt(ShaderType.fragment_shader)
                std.log.err("ERROR::FRAGMENT::SHADER::COMPILATION_FAILED : {s}", .{shader_info_log});
            }
            std.log.err("Error compiling the shader object {} Fix any syntax error in the shader_source", .{shader_obj});
            std.debug.panic("Failed to correctly compile shader file", .{});
        }
    }

    fn checkShaderLinkErrors(shader_obj: c_uint) void {
        var shader_link_state: c_int = undefined;
        const info_log_size = 512;
        var shader_link_info_log: [info_log_size:0]u8 = undefined;
        glGetProgramiv(shader_obj, GL_LINK_STATUS, &shader_link_state);
        if (shader_link_state == GL_FALSE) {
            glGetProgramInfoLog(shader_obj, info_log_size, null, &shader_link_info_log);
            std.log.err("ERROR::SHADER::PROGRAM::LINKING_FALIED : {s}", .{shader_link_info_log});
            std.log.err(
                \\Fix the output of the previous shader to match the input of current shader {}
                \\And check and make sure there are no errors in your shaders
            , .{shader_obj});
            std.debug.panic("Failed to correctly link shader files", .{});
        }
    }

    pub fn useShader(self: Shader) void {
        glUseProgram(self.program_id);
    }

    pub fn setUniform(self: Shader, name: [:0]const u8, comptime T: type, value: T) void {
        if (T == bool or T == u8) {
            glUniform1i(glGetUniformLocation(self.program_id, name), @intCast(c_int, value));
        } else if (T == f32) {
            glUniform1f(glGetUniformLocation(self.program_id, name), value);
        }
    }
};
