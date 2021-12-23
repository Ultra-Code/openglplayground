const std = @import("std");
const c = @import("cimports.zig");

const ImageInfo = struct { width: i32, height: i32, number_of_color_channels: i32, data: *u8 };

pub fn genTextureFromImage(image_path: []const u8, image_color: c_uint) c_uint {
    var texture_obj: c_uint = undefined;
    const number_of_textures = 1;
    c.glGenTextures(number_of_textures, &texture_obj);
    c.glBindTexture(c.GL_TEXTURE_2D, texture_obj);

    //set the texture wrapping/filtering options (on currently bound texture)
    setTextureWrapping();
    setTextureZoomFiltering();

    // load and generate the texture
    const image = loadTextureImage(image_path);
    defer c.stbi_image_free(image.data);
    //specifies the mipmap level for which we want to create a texture
    //the base level is 0
    const mipmap_level = 0;
    //Third args specifies format to store the texture
    //7th & 8th  args specifies format and datatype of source image
    const texture_border = 0;
    //this associates the texture_obj with out texture image
    c.glTexImage2D(c.GL_TEXTURE_2D, mipmap_level, @intCast(c_int, image_color), image.width, image.height, texture_border, image_color, c.GL_UNSIGNED_BYTE, image.data);
    //automatically generate all the required mipmaps for the currently bound texture
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
    return texture_obj;
}

fn loadTextureImage(image_path: []const u8) ImageInfo {
    var width: i32 = undefined;
    var height: i32 = undefined;
    var number_of_color_channels: i32 = undefined;
    const components_per_pixel = 0; //default 8 bit per pixel
    //Opengl expects the 0.0 coordinate on the y-axis to be on the bottom side
    //of the image, but images usually have 0.0 at the top of the y-axis.
    //stb_image.h can flip the y-axis during image loading by calling
    //c.stbi_set_flip_vertically_on_load(true) before loading any image
    const TRUE = 1;
    c.stbi_set_flip_vertically_on_load(TRUE);
    const data: ?*u8 = c.stbi_load(image_path.ptr, &width, &height, &number_of_color_channels, components_per_pixel);
    return .{ .width = width, .height = height, .number_of_color_channels = number_of_color_channels, .data = data orelse std.debug.panic(
        \\Failed to load texture at {0s} make sure that {0s} exist"
    , .{image_path}) };
}

fn setTextureWrapping() void {
    //texture corodinates s,t,r maps to x,y,z in 3d space
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_MIRRORED_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_MIRRORED_REPEAT);
}

fn setTextureZoomFiltering() void {
    //set filtering to use when texture is zoomed in or out.we can use a filtering
    //that works with mipmaps like c.GL_LINEAR_MIPMAP_NEAREST Note: mipmaps only
    //work for minimizing or downscaled textures
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_LINEAR);
}
