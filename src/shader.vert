#version 460

layout(set = 1, binding = 0) uniform UBO {
    vec2 screen;
};

layout(location=0) in vec2 position;
layout(location=1) in vec2 instance_position;
layout(location=2) in vec2 instance_size;
layout(location=3) in uint texture_index_in;

layout(location=0) out vec2 uv_out;
layout(location=1) out uint texture_index_out;

void main() {
    vec2 proj_offset = -screen / 2.0F;
    vec2 proj_scale  = 2.0F / screen;
    proj_scale.y *= -1.0F;
    vec2 pos0 = position * instance_size + instance_position;
    pos0 = (pos0 + proj_offset) * proj_scale;
    gl_Position = vec4(pos0, 0.0F, 1.0F);
    uv_out = position;
    texture_index_out = texture_index_in;
}
