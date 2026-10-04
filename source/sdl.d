import std.string;

enum LogPriority
{
    INVALID,
    TRACE,
    VERBOSE,
    DEBUG,
    INFO,
    WARN,
    ERROR,
    CRITICAL,
    COUNT
}

private extern (C) void SDL_SetLogPriorities(LogPriority priority);

void setLogPriorities(LogPriority priority)
{
    SDL_SetLogPriorities(priority);
}

private extern (C) bool SDL_SetAppMetadata(const(char)* appname, const(char)* appversion,
    const(char)* appidentifier);

bool setAppMetadata(string appname, string appversion, string appidentifier)
{
    return SDL_SetAppMetadata(toStringz(appname), toStringz(appversion), toStringz(appidentifier));
}

enum InitFlags : uint
{
    AUDIO = 0x00000010u,
    VIDEO = 0x00000020u,
    JOYSTICK = 0x00000200u,
    HAPTIC = 0x00001000u,
    GAMEPAD = 0x00002000u,
    EVENTS = 0x00004000u,
    SENSOR = 0x00008000u,
    CAMERA = 0x00010000u,
}

private extern (C) bool SDL_Init(InitFlags flags);

bool init(InitFlags flags)
{
    return SDL_Init(flags);
}

private extern (C) void SDL_Quit();

void quit()
{
    SDL_Quit();
}

extern (C) struct Window;

enum WindowFlags : ulong
{
    NONE = 0x0000000000000000UL,
    FULLSCREEN = 0x0000000000000001UL,
    OPENGL = 0x0000000000000002UL,
    OCCLUDED = 0x0000000000000004UL,
    HIDDEN = 0x0000000000000008UL,
    BORDERLESS = 0x0000000000000010UL,
    RESIZABLE = 0x0000000000000020UL,
    MINIMIZED = 0x0000000000000040UL,
    MAXIMIZED = 0x0000000000000080UL,
    MOUSE_GRABBED = 0x0000000000000100UL,
    INPUT_FOCUS = 0x0000000000000200UL,
    MOUSE_FOCUS = 0x0000000000000400UL,
    EXTERNAL = 0x0000000000000800UL,
    MODAL = 0x0000000000001000UL,
    HIGH_PIXEL_DENSITY = 0x0000000000002000UL,
    MOUSE_CAPTURE = 0x0000000000004000UL,
    MOUSE_RELATIVE_MODE = 0x0000000000008000UL,
    ALWAYS_ON_TOP = 0x0000000000010000UL,
    UTILITY = 0x0000000000020000UL,
    TOOLTIP = 0x0000000000040000UL,
    POPUP_MENU = 0x0000000000080000UL,
    KEYBOARD_GRABBED = 0x0000000000100000UL,
    FILL_DOCUMENT = 0x0000000000200000UL,
    VULKAN = 0x0000000010000000UL,
    METAL = 0x0000000020000000UL,
    TRANSPARENT = 0x0000000040000000UL,
    NOT_FOCUSABLE = 0x0000000080000000UL,
}

private extern (C) Window* SDL_CreateWindow(const(char)* title, int w, int h, WindowFlags flags);

Window* createWindow(string title, int w, int h, WindowFlags flags)
{
    return SDL_CreateWindow(toStringz(title), w, h, flags);
}

private extern (C) void SDL_DestroyWindow(Window* window);

void destroyWindow(Window* window)
{
    SDL_DestroyWindow(window);
}

enum GPUShaderFormat : uint
{
    INVALID = 0,
    PRIVATE = 1u << 0,
    SPIRV = 1u << 1,
    DXBC = 1u << 2,
    DXIL = 1u << 3,
    MSL = 1u << 4,
    METALLIB = 1u << 5,
}

extern (C) struct GPUDevice;
private extern (C) GPUDevice* SDL_CreateGPUDevice(GPUShaderFormat format_flags, bool debug_mode,
    const(char)* name);

GPUDevice* createGPUDevice(GPUShaderFormat format_flags, bool debug_mode, const(char)* name)
{
    return SDL_CreateGPUDevice(format_flags, debug_mode, name);
}

extern (C) void SDL_DestroyGPUDevice(GPUDevice* device);

void destroyWindow(GPUDevice* device)
{
    SDL_DestroyGPUDevice(device);
}

extern (C) bool SDL_ClaimWindowForGPUDevice(GPUDevice* device, Window* window);

bool claimWindowForGPUDevice(GPUDevice* device, Window* window)
{
    return SDL_ClaimWindowForGPUDevice(device, window);
}

extern (C) struct GPUSampler;

extern (C) enum GPUFilter
{
    NEAREST,
    LINEAR
}

extern (C) enum GPUSamplerMipmapMode
{
    NEAREST,
    LINEAR
}

extern (C) enum GPUSamplerAddressMode
{
    SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
    SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT,
    SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE
}

extern (C) enum GPUCompareOp
{
    INVALID,
    NEVER,
    LESS,
    EQUAL,
    LESS_OR_EQUAL,
    GREATER,
    NOT_EQUAL,
    GREATER_OR_EQUAL,
    ALWAYS
}

alias PropertiesID = uint;

extern (C) struct GPUSamplerCreateInfo
{
    GPUFilter min_filter;
    GPUFilter mag_filter;
    GPUSamplerMipmapMode mipmap_mode;
    GPUSamplerAddressMode address_mode_u;
    GPUSamplerAddressMode address_mode_v;
    GPUSamplerAddressMode address_mode_w;
    float mip_lod_bias;
    float max_anisotropy;
    GPUCompareOp compare_op;
    float min_lod;
    float max_lod;
    bool enable_anisotropy;
    bool enable_compare;
    ubyte padding1;
    ubyte padding2;
    PropertiesID props;
}

extern (C) GPUSampler* SDL_CreateGPUSampler(GPUDevice* device, const(GPUSamplerCreateInfo)* createinfo);

GPUSampler* createGPUSampler(GPUDevice* device, const(GPUSamplerCreateInfo)* createinfo)
{
    return SDL_CreateGPUSampler(device, createinfo);
}

extern (C) void SDL_ReleaseGPUSampler(GPUDevice* device, GPUSampler* sampler);

void releaseGPUSampler(GPUDevice* device, GPUSampler* sampler)
{
    SDL_ReleaseGPUSampler(device, sampler);
}

extern (C) struct GPUShader;

extern (C) enum GPUVertexInputRate
{
    VERTEX,
    INSTANCE
}

extern (C) struct GPUVertexBufferDescription
{
    uint slot;
    uint pitch;
    GPUVertexInputRate input_rate;
    uint instance_step_rate;
}

extern (C) enum GPUVertexElementFormat
{
    INVALID,

    INT,
    INT2,
    INT3,
    INT4,

    UINT,
    UINT2,
    UINT3,
    UINT4,

    FLOAT,
    FLOAT2,
    FLOAT3,
    FLOAT4,

    BYTE2,
    BYTE4,

    UBYTE2,
    UBYTE4,

    BYTE2_NORM,
    BYTE4_NORM,

    UBYTE2_NORM,
    UBYTE4_NORM,

    SHORT2,
    SHORT4,

    USHORT2,
    USHORT4,

    SHORT2_NORM,
    SHORT4_NORM,

    USHORT2_NORM,
    USHORT4_NORM,

    HALF2,
    HALF4
}

extern (C) struct GPUVertexAttribute
{
    uint location;
    uint buffer_slot;
    GPUVertexElementFormat format;
    uint offset;
}

extern (C) struct GPUVertexInputState
{
    const(GPUVertexBufferDescription)* vertex_buffer_descriptions;
    uint num_vertex_buffers;
    const(GPUVertexAttribute)* vertex_attributes;
    uint num_vertex_attributes;
}

extern (C) enum GPUPrimitiveType
{
    TRIANGLELIST,
    TRIANGLESTRIP,
    LINELIST,
    LINESTRIP,
    POINTLIST
}

extern (C) enum GPUFillMode
{
    FILL,
    LINE
}

extern (C) enum GPUCullMode
{
    NONE,
    FRONT,
    BACK
}

extern (C) enum GPUFrontFace
{
    COUNTER_CLOCKWISE,
    CLOCKWISE
}

extern (C) struct GPURasterizerState
{
    GPUFillMode fill_mode;
    GPUCullMode cull_mode;
    GPUFrontFace front_face;
    float depth_bias_constant_factor;
    float depth_bias_clamp;
    float depth_bias_slope_factor;
    bool enable_depth_bias;
    bool enable_depth_clip;
    ubyte padding1;
    ubyte padding2;
}

extern (C) enum GPUSampleCount
{
    COUNT_1,
    COUNT_2,
    COUNT_4,
    COUNT_8
}

extern (C) struct GPUMultisampleState
{
    GPUSampleCount sample_count;
    uint sample_mask;
    bool enable_mask;
    bool enable_alpha_to_coverage;
    ubyte padding2;
    ubyte padding3;
}

extern (C) enum GPUStencilOp
{
    INVALID,
    KEEP,
    ZERO,
    REPLACE,
    INCREMENT_AND_CLAMP,
    DECREMENT_AND_CLAMP,
    INVERT,
    INCREMENT_AND_WRAP,
    DECREMENT_AND_WRAP
}

extern (C) struct GPUStencilOpState
{
    GPUStencilOp fail_op;
    GPUStencilOp pass_op;
    GPUStencilOp depth_fail_op;
    GPUCompareOp compare_op;
}

extern (C) struct GPUDepthStencilState
{
    GPUCompareOp compare_op;
    GPUStencilOpState back_stencil_state;
    GPUStencilOpState front_stencil_state;
    ubyte compare_mask;
    ubyte write_mask;
    bool enable_depth_test;
    bool enable_depth_write;
    bool enable_stencil_test;
    ubyte padding1;
    ubyte padding2;
    ubyte padding3;
}

extern (C) enum GPUTextureFormat
{
    INVALID,
    A8_UNORM,
    R8_UNORM,
    R8G8_UNORM,
    R8G8B8A8_UNORM,
    R16_UNORM,
    R16G16_UNORM,
    R16G16B16A16_UNORM,
    R10G10B10A2_UNORM,
    B5G6R5_UNORM,
    B5G5R5A1_UNORM,
    B4G4R4A4_UNORM,
    B8G8R8A8_UNORM,
    BC1_RGBA_UNORM,
    BC2_RGBA_UNORM,
    BC3_RGBA_UNORM,
    BC4_R_UNORM,
    BC5_RG_UNORM,
    BC7_RGBA_UNORM,
    BC6H_RGB_FLOAT,
    BC6H_RGB_UFLOAT,
    R8_SNORM,
    R8G8_SNORM,
    R8G8B8A8_SNORM,
    R16_SNORM,
    R16G16_SNORM,
    R16G16B16A16_SNORM,
    R16_FLOAT,
    R16G16_FLOAT,
    R16G16B16A16_FLOAT,
    R32_FLOAT,
    R32G32_FLOAT,
    R32G32B32A32_FLOAT,
    R11G11B10_UFLOAT,
    R8_UINT,
    R8G8_UINT,
    R8G8B8A8_UINT,
    R16_UINT,
    R16G16_UINT,
    R16G16B16A16_UINT,
    R32_UINT,
    R32G32_UINT,
    R32G32B32A32_UINT,
    R8_INT,
    R8G8_INT,
    R8G8B8A8_INT,
    R16_INT,
    R16G16_INT,
    R16G16B16A16_INT,
    R32_INT,
    R32G32_INT,
    R32G32B32A32_INT,
    R8G8B8A8_UNORM_SRGB,
    B8G8R8A8_UNORM_SRGB,
    BC1_RGBA_UNORM_SRGB,
    BC2_RGBA_UNORM_SRGB,
    BC3_RGBA_UNORM_SRGB,
    BC7_RGBA_UNORM_SRGB,
    D16_UNORM,
    D24_UNORM,
    D32_FLOAT,
    D24_UNORM_S8_UINT,
    D32_FLOAT_S8_UINT,
    ASTC_4x4_UNORM,
    ASTC_5x4_UNORM,
    ASTC_5x5_UNORM,
    ASTC_6x5_UNORM,
    ASTC_6x6_UNORM,
    ASTC_8x5_UNORM,
    ASTC_8x6_UNORM,
    ASTC_8x8_UNORM,
    ASTC_10x5_UNORM,
    ASTC_10x6_UNORM,
    ASTC_10x8_UNORM,
    ASTC_10x10_UNORM,
    ASTC_12x10_UNORM,
    ASTC_12x12_UNORM,
    ASTC_4x4_UNORM_SRGB,
    ASTC_5x4_UNORM_SRGB,
    ASTC_5x5_UNORM_SRGB,
    ASTC_6x5_UNORM_SRGB,
    ASTC_6x6_UNORM_SRGB,
    ASTC_8x5_UNORM_SRGB,
    ASTC_8x6_UNORM_SRGB,
    ASTC_8x8_UNORM_SRGB,
    ASTC_10x5_UNORM_SRGB,
    ASTC_10x6_UNORM_SRGB,
    ASTC_10x8_UNORM_SRGB,
    ASTC_10x10_UNORM_SRGB,
    ASTC_12x10_UNORM_SRGB,
    ASTC_12x12_UNORM_SRGB,
    ASTC_4x4_FLOAT,
    ASTC_5x4_FLOAT,
    ASTC_5x5_FLOAT,
    ASTC_6x5_FLOAT,
    ASTC_6x6_FLOAT,
    ASTC_8x5_FLOAT,
    ASTC_8x6_FLOAT,
    ASTC_8x8_FLOAT,
    ASTC_10x5_FLOAT,
    ASTC_10x6_FLOAT,
    ASTC_10x8_FLOAT,
    ASTC_10x10_FLOAT,
    ASTC_12x10_FLOAT,
    ASTC_12x12_FLOAT
}

extern (C) enum GPUBlendFactor
{
    INVALID,
    ZERO,
    ONE,
    SRC_COLOR,
    ONE_MINUS_SRC_COLOR,
    DST_COLOR,
    ONE_MINUS_DST_COLOR,
    SRC_ALPHA,
    ONE_MINUS_SRC_ALPHA,
    DST_ALPHA,
    ONE_MINUS_DST_ALPHA,
    CONSTANT_COLOR,
    ONE_MINUS_CONSTANT_COLOR,
    SRC_ALPHA_SATURATE
}

extern (C) enum GPUBlendOp
{
    INVALID,
    ADD,
    SUBTRACT,
    REVERSE_SUBTRACT,
    MIN,
    MAX
}

alias GPUColorComponentFlags = ubyte;

enum GPUColorComponent : ubyte
{
    R = 1u << 0,
    G = 1u << 1,
    B = 1u << 2,
    A = 1u << 3,
}

extern (C) struct GPUColorTargetBlendState
{
    GPUBlendFactor src_color_blendfactor;
    GPUBlendFactor dst_color_blendfactor;
    GPUBlendOp color_blend_op;
    GPUBlendFactor src_alpha_blendfactor;
    GPUBlendFactor dst_alpha_blendfactor;
    GPUBlendOp alpha_blend_op;
    GPUColorComponentFlags color_write_mask;
    bool enable_blend;
    bool enable_color_write_mask;
    ubyte padding1;
    ubyte padding2;
}

extern (C) struct GPUColorTargetDescription
{
    GPUTextureFormat format;
    GPUColorTargetBlendState blend_state;
}

extern (C) struct GPUGraphicsPipelineTargetInfo
{
    const(GPUColorTargetDescription)* color_target_descriptions;
    uint num_color_targets;
    GPUTextureFormat depth_stencil_format;
    bool has_depth_stencil_target;
    ubyte padding1;
    ubyte padding2;
    ubyte padding3;
}

extern (C) struct GPUGraphicsPipelineCreateInfo
{
    GPUShader* vertex_shader;
    GPUShader* fragment_shader;
    GPUVertexInputState vertex_input_state;
    GPUPrimitiveType primitive_type;
    GPURasterizerState rasterizer_state;
    GPUMultisampleState multisample_state;
    GPUDepthStencilState depth_stencil_state;
    GPUGraphicsPipelineTargetInfo target_info;

    PropertiesID props;
}

extern (C) struct SDL_GPUGraphicsPipelineCreateInfo
{
    GPUShader* vertex_shader;
    GPUShader* fragment_shader;
    GPUVertexInputState vertex_input_state;
    GPUPrimitiveType primitive_type;
    GPURasterizerState rasterizer_state;
    GPUMultisampleState multisample_state;
    GPUDepthStencilState depth_stencil_state;
    GPUGraphicsPipelineTargetInfo target_info;
    PropertiesID props;
}
