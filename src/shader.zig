const std = @import("std");
const c = @import("cimports.zig");
const glm = @import("glm.zig");
const Mat4 = glm.Mat4;
const Vec4 = glm.Vec4;

pub fn getMaximumNumberOfVertexAttributes() void {
    var number_of_attributes: c_int = undefined;
    c.glGetIntegerv(c.GL_MAX_VERTEX_ATTRIBS, &number_of_attributes);
    std.log.info(
        \\This hardware can have a maximum of {} vertex attributes in a vertex shader
    , .{number_of_attributes});
}
const Allocator = std.mem.Allocator;

pub const Shader = struct {
    program_id: c_uint,

    const ShaderType = enum(u32) { vertex_shader = c.GL_VERTEX_SHADER, fragment_shader = c.GL_FRAGMENT_SHADER };

    pub fn init(allocator: Allocator, vertex_path: []const u8, fragment_path: []const u8) !Shader {
        // 1. retrieve the vertex/fragment source code from filePath
        const vertex_shader_file = try std.fs.cwd().openFile(vertex_path, .{ .read = true, .write = false });
        defer vertex_shader_file.close();

        var vertex_source_buffer = try allocator.allocSentinel(u8, try vertex_shader_file.getEndPos(), '\x00');
        defer allocator.free(vertex_source_buffer);

        _ = try vertex_shader_file.read(vertex_source_buffer);

        const fragment_shader_file = try std.fs.cwd().openFile(fragment_path, .{ .read = true, .write = false });
        defer fragment_shader_file.close();

        var fragment_source_buffer = try allocator.allocSentinel(u8, try fragment_shader_file.getEndPos(), '\x00');
        defer allocator.free(fragment_source_buffer);

        _ = try fragment_shader_file.read(fragment_source_buffer);

        return Shader{ .program_id = shaderProgram(vertex_source_buffer.ptr, fragment_source_buffer.ptr) };
    }

    fn shaderProgram(vertex_source: [*:0]const u8, fragment_source: [*:0]const u8) c_uint {
        const vertex_shader = compileShader(c.GL_VERTEX_SHADER, vertex_source);
        const fragment_shader = compileShader(c.GL_FRAGMENT_SHADER, fragment_source);

        const shader_program = linkShaders(vertex_shader, fragment_shader);
        defer c.glDeleteShader(vertex_shader);
        defer c.glDeleteShader(fragment_shader);
        return shader_program;
    }

    fn compileShader(shader_type: c_uint, shader_source: [*:0]const u8) c_uint {
        // shader_type specify the type of the shader which could be
        // c.GL_VERTEX_SHADER or c.GL_FRAGMENT_SHADER ...
        const shader_obj: c_uint = c.glCreateShader(shader_type);
        const number_of_shaders = 1;
        //specify the shader to link to the vertex_shader_obj
        c.glShaderSource(shader_obj, number_of_shaders, &shader_source, null);
        c.glCompileShader(shader_obj);
        checkShaderCompileErrors(shader_obj, shader_type);
        return shader_obj;
    }

    fn linkShaders(vertex_shader: c_uint, fragment_shader: c_uint) c_uint {
        const shader_program_obj = c.glCreateProgram();
        c.glAttachShader(shader_program_obj, vertex_shader);
        c.glAttachShader(shader_program_obj, fragment_shader);
        c.glLinkProgram(shader_program_obj);
        checkShaderLinkErrors(shader_program_obj);
        // Always detach shaders after a successful link.
        c.glDetachShader(shader_program_obj, vertex_shader);
        c.glDetachShader(shader_program_obj, fragment_shader);
        return shader_program_obj;
    }

    fn checkShaderCompileErrors(shader_obj: c_uint, shader_type: c_uint) void {
        // check for shader errors
        var shader_state: c_int = undefined;
        const info_log_size = 512;
        var shader_info_log: [info_log_size:0]u8 = undefined;

        c.glGetShaderiv(shader_obj, c.GL_COMPILE_STATUS, &shader_state);
        if (shader_state == c.GL_FALSE) {
            c.glGetShaderInfoLog(shader_obj, info_log_size, null, &shader_info_log);
            if (shader_type == @enumToInt(ShaderType.vertex_shader)) {
                std.log.err("ERROR::VERTEX::SHADER::COMPILATION_FAILED : {s}", .{shader_info_log});
            } else {
                std.log.err("ERROR::FRAGMENT::SHADER::COMPILATION_FAILED : {s}", .{shader_info_log});
            }
            // We don't need the shader anymore.
            c.glDeleteShader(shader_obj);
            std.log.err("Error compiling the shader object {} Fix any syntax error in the shader_source", .{shader_obj});
            std.debug.panic("Failed to correctly compile shader file", .{});
        }
    }

    fn checkShaderLinkErrors(program_obj: c_uint) void {
        var shader_link_state: c_int = undefined;
        const info_log_size = 512;
        var shader_link_info_log: [info_log_size:0]u8 = undefined;
        c.glGetProgramiv(program_obj, c.GL_LINK_STATUS, &shader_link_state);
        if (shader_link_state == c.GL_FALSE) {
            c.glGetProgramInfoLog(program_obj, info_log_size, null, &shader_link_info_log);
            std.log.err("ERROR::SHADER::PROGRAM::LINKING_FALIED : {s}", .{shader_link_info_log});
            std.log.err(
                \\Fix the output of the previous shader to match the input of current shader {}
                \\And check and make sure there are no errors in your shaders
            , .{program_obj});
            c.glDeleteProgram(program_obj);
            std.debug.panic("Failed to correctly link shader files", .{});
        }
    }

    pub fn useShader(self: Shader) void {
        c.glUseProgram(self.program_id);
    }

    ///uninforms are useful for setting attributes that might change on every frame
    ///or for interchanging data between your application and your shaders
    pub fn setUniform(self: Shader, name: [:0]const u8, comptime T: type, value: T) void {
        if (T == bool or T == u8) {
            c.glUniform1i(c.glGetUniformLocation(self.program_id, name), @intCast(c_int, value));
        } else if (T == f32) {
            c.glUniform1f(c.glGetUniformLocation(self.program_id, name), value);
        } else if (T == Vec4) {
            c.glUniform4f(c.glGetUniformLocation(self.program_id, name), value.val[0], value.val[1], value.val[2], value.val[3]);
        } else if (T == Mat4) {
            const number_of_matrices = 1;
            const transpose_matrices = c.GL_FALSE;
            const matrix_data = &value.vals[0][0];
            c.glUniformMatrix4fv(c.glGetUniformLocation(self.program_id, name), number_of_matrices, transpose_matrices, matrix_data);
        } else {
            @compileError("Error: Setting glsl uniform with your specified type T is not supported");
        }
    }
};
