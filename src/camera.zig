//simple fly style camera system that allows for free movement in a 3D environment/scene
const main = @import("main.zig");
const c = @import("cimports.zig");
const std = @import("std");
const glm = @import("glm.zig");
const cos = std.math.cos;
const sin = std.math.sin;
const vec3 = glm.vec3;
const Mat4 = glm.Mat4;
const Vec3 = glm.Vec3;
const radian = glm.radian;

// Defines several possible options for camera movement.
const CameraMovement = enum {
    Forward,
    Backward,
    Left,
    Right,
};
//To define a camera we need its position in world space, the direction it’s looking at,
//a vector pointing to the right and a vector pointing upwards from the camera.
// Default camera values

//To make sure the camera points towards the negative z-axis by default we can give the yaw
//a default value of a 90 degree clockwise rotation. Positive degrees rotate counter-clockwise
const YAW = -90.0;
const PITCH = 0.0;
const SPEED = 2.5;
const SENSITIVITY = 0.1;
const ZOOM = 45.0;

//Camera/View/Eye space matrix transformations
//we move the camera back 6 units which is equivalent to moving the scene back 6 units
//for better view of the whole scene
const CAM_POSITION = vec3(0.0, 0.0, 3.0);

//by default the camera is positioned to point in the +z axis which is pointing to u
//but because by convention (in OpenGL) the camera should points towards the negative z-axis
//so we flip the points into the -z plane towards the scene so that we can get the
//feeling of moving around the scene from our eye perspective == camera
const CAM_FRONT = vec3(0.0, 0.0, -1.0); //the direction that the camera is pointing in

//CAM_UP specifies the movement of the camera in the vertical plane
const CAM_UP = vec3(0.0, 1.0, 0.0);

//cross product of CAM_UP and CAM_FRONT .ie CAM_RIGHT == CAM_UP.cross(CAM_FRONT)
const CAM_RIGHT = vec3(-1.0, 0.0, 0.0);

// An abstract camera class that processes input and calculates the corresponding Euler Angles, Vectors and Matrices for use in OpenGL
pub const Camera = struct {
    // Camera Attributes
    position: Vec3,
    front: Vec3, //direction
    up: Vec3,
    right: Vec3,
    worldUp: Vec3,

    // Euler Angles
    yaw: f32,
    pitch: f32,

    // Camera options
    camera_speed: f32,

    //control mouse movement sensitivity
    mouse_sensitivity: f32,

    //the Field of view or fov largely defines how much we can see of the scene. When
    //the field of view becomes smaller, the scene’s projected space gets smaller
    //This smaller space is projected over the same NDC, giving the illusion of zooming in.
    field_of_view: f32,

    /// Constructor with vectors
    pub fn init(position: Vec3, up: Vec3, yaw: f32, pitch: f32) Camera {
        var camera = Camera{
            .position = position,
            .front = CAM_FRONT,
            .up = up,
            .right = CAM_RIGHT,
            .worldUp = CAM_UP,

            .yaw = yaw,
            .pitch = pitch,

            .camera_speed = SPEED,
            .mouse_sensitivity = SENSITIVITY,
            .zoom = ZOOM,
        };
        camera.updateCameraVectors();
        return camera;
    }

    pub fn default() Camera {
        var camera = Camera{
            .position = CAM_POSITION,
            .front = CAM_FRONT,
            .up = CAM_UP,
            .right = CAM_RIGHT,
            .worldUp = CAM_UP,

            .yaw = YAW,
            .pitch = PITCH,

            .camera_speed = SPEED,
            .mouse_sensitivity = SENSITIVITY,
            .field_of_view = ZOOM,
        };
        camera.updateCameraVectors();
        return camera;
    }

    //move around the scene
    /// Returns the view matrix calculated using Euler Angles and the LookAt Matrix
    pub fn walkAroundScene(self: Camera) Mat4 {

        //the direction of the camera(where the camera is looking) is the current position(CAM_POSITION) + the direction vector(CAM_FRONT)
        //This ensures that no matter how we move, the camera keeps looking at the target direction(CAM_FRONT)
        // const move_around = glm.lookAt(CAM_POSITION, CAM_POSITION.add(CAM_FRONT), CAM_UP);
        const move_around = glm.lookAt(self.position, self.position.add(self.front), self.up);
        return move_around;
    }

    ///Processes input received from any keyboard-like input system. Accepts input parameter in the form of camera defined ENUM (to abstract it from windowing systems)
    pub fn cameraMovementWithKeyboard(self: *Camera, direction: CameraMovement, deltaTime: f32) void {
        //speed of camera movement
        const velocity = self.camera_speed * deltaTime;
        switch (direction) {
            //Moving Foward
            // CAM_POSITION += camera_speed * CAM_FRONT;
            // CAM_FRONT * camera_speed increases the z component of CAM_FRONT
            //eg vec3(0.0,0.0,-1.0) * 0.1 == vec3(0.0,0.0,-0.1) .ie the z axis has been increased from -1.0 to -0.1
            //adding vec3(0.0,0.0,-0.1) to CAM_POSITION decreases the z component by 0.1 moving the camera towards the scene

            // CAM_POSITION = CAM_POSITION.add(CAM_FRONT.mulScalar(camera_speed));
            .Forward => self.position = self.position.add(self.front.mulScalar(velocity)),
            //Moving Backward
            // CAM_POSITION -= camera_speed * CAM_FRONT;
            //The same process happen for camera_speed * CAM_FRONT till the point of subtraction
            //subtracting vec3(0.0,0.0,-0.1) from CAM_POSITION .ie CAM_POSITION - vec3(0.0,0.0,-0.1)
            // - - 0.1 == 0.1 increasing the z-axis by 0.1 moving the camera away from the scene

            // CAM_POSITION = CAM_POSITION.sub(CAM_FRONT.mulScalar(camera_speed));
            .Backward => self.position = self.position.sub(self.front.mulScalar(velocity)),
            //Moving leftsided
            // CAM_POSITION -= CAM_FRONT.cross(CAM_UP) * camera_speed;
            //Then we do a cross product of the direction vector(CAM_FRONT) on the up vector(CAM_UP)
            //the result of a cross product is a vector perpendicular to both vectors
            //.ie we will get a vector that points in the positive x-axis’s direction .eg CAM_FRONT.cross(CAM_UP) == (1.0,-0.0,0.0)
            //CAM_POSITION - (1.0,-0.0,0.0) would decrease the x-axis of CAM_POSITION moving camera to the left

            // CAM_POSITION -= CAM_FRONT.cross(CAM_UP) * camera_speed;
            //OR
            //CAM_POSITION += CAM_UP.cross(CAM_FRONT) * camera_speed
            //NOTE: CAM_UP.cross(CAM_FRONT) produces a vec3 in the -x axis (-1.0,0.0,0.0) so we can add it to CAM_POSITION to move the camera left
            //NOTE: CAM_RIGHT == CAM_UP.cross(CAM_FRONT)
            // CAM_POSITION = CAM_POSITION.add(CAM_UP.cross(CAM_FRONT).mulScalar(camera_speed));
            // CAM_POSITION = CAM_POSITION.sub(CAM_FRONT.cross(CAM_UP).mulScalar(camera_speed));
            .Left => self.position = self.position.sub(self.right.mulScalar(velocity)),
            //Moving Rightsided
            //Like Moving leftsided above but adding (1.0,-0.0,0,0) to CAM_POSITION increases the x-axis component of CAM_POSITION
            //moving the camera to the right

            // CAM_POSITION += CAM_FRONT.cross(CAM_UP) * camera_speed;
            // CAM_POSITION = CAM_POSITION.add(CAM_FRONT.cross(CAM_UP).mulScalar(camera_speed));
            .Right => self.position = self.position.add(self.right.mulScalar(velocity)),
        }
    }

    // Processes input received from a mouse input system. Expects the offset value in both the x and y direction.
    pub fn cameraMovementWithMouse(self: *Camera, xoffset: f32, yoffset: f32) void {

        //update yaw and pitch
        self.yaw += xoffset * self.mouse_sensitivity;
        self.pitch += yoffset * self.mouse_sensitivity;

        //Add some constraints to the camera so users won’t be able to make weird camera movements
        //like causes a LookAt flip once direction vector is parallel to the world up vector
        //The pitch needs to be constrained in such a way that users won’t be able to look higher
        //than 89 degrees (at 90 degrees we get the LookAt flip) and also not below -89 degrees. This
        //ensures the user will be able to look up to the sky or below to his feet but not further
        //we set no constraint on the yaw value since we don’t want to constrain the user in horizontal rotation.
        if (self.pitch > 89.0)
            self.pitch = 89.0;
        if (self.pitch < -89.0)
            self.pitch = -89.0;

        // Update Front, Right and Up Vectors using the updated Euler angles
        self.updateCameraVectors();
    }

    //zooming camera
    //Processes input received from a mouse scroll-wheel event. Only requires input on the vertical wheel-axis
    pub fn cameraZooming(self: *Camera, yoffset: f32) void {

        //When scrolling/zooming the yoffset value tells us the amount we scrolled/zoomed vertical
        self.field_of_view -= yoffset;

        if (self.field_of_view <= 1.0)
            self.field_of_view = 1.0;
        if (self.field_of_view >= 45.0)
            self.field_of_view = 45.0;
    }

    // Calculates the front vector from the Camera's (updated) Euler Angles
    fn updateCameraVectors(self: *Camera) void {
        // Calculate the new Front vector
        self.front = self.updateCameraDirection();
        // Also re-calculate the Right and Up vector
        self.right = self.front.cross(self.worldUp).normalize();
        self.up = self.right.cross(self.front).normalize();
    }

    fn updateCameraDirection(self: Camera) Vec3 {
        const direction_x = cos(radian(self.yaw)) * cos(radian(self.pitch));
        const direction_y = sin(radian(self.pitch));
        const direction_z = sin(radian(self.yaw)) * cos(radian(self.pitch));
        //the computed direction vector contains all the rotations calculated from the mouse’s movement.
        const camera_direction = vec3(direction_x, direction_y, direction_z);
        return camera_direction.normalize();
    }

    pub fn fov(self: Camera) f32 {
        return radian(self.field_of_view);
    }

    pub fn rotateCamAroundScene() Mat4 {
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
};
