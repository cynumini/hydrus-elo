#version 460

layout(set = 1, binding = 0) uniform UBO {
    ivec2 screen;
};

layout(location=0) in vec2 vertex_position;
layout(location=1) in vec2 instance_position;
layout(location=2) in vec2 instance_size;
layout(location=3) in uint texture_index_in;

layout(location=0) out vec2 uv;
layout(location=1) out uint texture_index_out;

void main() {
    vec2 proj_scale = 2.0F / screen;
    vec2 proj_offset = -screen / 2.0F;
    proj_scale.y *= -1;

    vec2 position = vertex_position * instance_size + instance_position;
    position = (position+ proj_offset) * proj_scale;
    gl_Position = vec4(position, 0.0F, 1.0F);
    uv = vertex_position;
    texture_index_out = texture_index_in;
    // uv = uv_position + (vertex_position * uv_size);
}
