#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer PositionBuffer {
    vec2 positions[];
};

layout(set = 0, binding = 1, std430) restrict buffer VelocityBuffer {
    vec2 velocities[];
};

layout(set = 0, binding = 2, std430) restrict buffer AngleBuffer {
    float angles[];
};

layout(set = 0, binding = 3, std430) restrict buffer BouncedBuffer {
    uint bounced[];
};

layout(set = 0, binding = 4, std430) restrict buffer OutputBuffer {
    vec4 transforms[];  // xy = position, z = frame, w = flags (1 = cull)
};

layout(push_constant, std430) uniform Params {
    float delta;
    float screen_width;
    float screen_height;
    float tri_radius;
    uint count;
    float rotation_speed;
} params;

void main() {
    uint i = gl_GlobalInvocationID.x;
    if (i >= params.count) return;

    // Update position
    vec2 pos = positions[i] + velocities[i] * params.delta;
    positions[i] = pos;

    // Cull check
    float margin = 20.0;
    if (pos.x < -margin || pos.x > params.screen_width + margin ||
        pos.y < -margin || pos.y > params.screen_height + margin) {
        transforms[i] = vec4(pos, 0.0, 1.0);  // flag for cull
        return;
    }

    // Screen bounce (once only)
    if (bounced[i] == 0u) {
        vec2 vel = velocities[i];
        bool did_bounce = false;

        if ((pos.x < params.tri_radius && vel.x < 0.0) ||
            (pos.x > params.screen_width - params.tri_radius && vel.x > 0.0)) {
            velocities[i].x = -vel.x;
            did_bounce = true;
        } else if ((pos.y < params.tri_radius && vel.y < 0.0) ||
                   (pos.y > params.screen_height - params.tri_radius && vel.y > 0.0)) {
            velocities[i].y = -vel.y;
            did_bounce = true;
        }

        if (did_bounce) {
            bounced[i] = 1u;
        }
    }

    // Update rotation
    float angle = mod(angles[i] + params.rotation_speed, 360.0);
    angles[i] = angle;

    // Calculate frame (0-71)
    float frame = floor(angle / 360.0 * 72.0);

    // Output transform data
    transforms[i] = vec4(pos, frame / 72.0, 0.0);
}
