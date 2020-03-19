{$mode objfpc}
{$assertions on}
{$include targetos}

unit GLUtils;
interface
uses
  {$ifdef API_OPENGL}
  GL, GLext,
  {$endif}
  {$ifdef API_OPENGLES}
  GLES30,
  {$endif}
  SysUtils;

procedure GLAssert (messageString: string = 'OpenGL error'); inline; 
function GLEnumToStr(enum: GLenum): string;

implementation

function GLEnumToStr(enum: GLenum): string;
begin
  case enum of
    GL_DEPTH_BUFFER_BIT:
      result := 'GL_DEPTH_BUFFER_BIT';     
    GL_STENCIL_BUFFER_BIT:
      result := 'GL_STENCIL_BUFFER_BIT';     
    GL_COLOR_BUFFER_BIT:
      result := 'GL_COLOR_BUFFER_BIT';     
    GL_POINTS:
      result := 'GL_POINTS';     
    GL_LINES:
      result := 'GL_LINES';     
    GL_LINE_LOOP:
      result := 'GL_LINE_LOOP';     
    GL_LINE_STRIP:
      result := 'GL_LINE_STRIP';     
    GL_TRIANGLES:
      result := 'GL_TRIANGLES';     
    GL_TRIANGLE_STRIP:
      result := 'GL_TRIANGLE_STRIP';     
    GL_TRIANGLE_FAN:
      result := 'GL_TRIANGLE_FAN';     
    GL_SRC_COLOR:
      result := 'GL_SRC_COLOR';     
    GL_ONE_MINUS_SRC_COLOR:
      result := 'GL_ONE_MINUS_SRC_COLOR';     
    GL_SRC_ALPHA:
      result := 'GL_SRC_ALPHA';     
    GL_ONE_MINUS_SRC_ALPHA:
      result := 'GL_ONE_MINUS_SRC_ALPHA';     
    GL_DST_ALPHA:
      result := 'GL_DST_ALPHA';     
    GL_ONE_MINUS_DST_ALPHA:
      result := 'GL_ONE_MINUS_DST_ALPHA';     
    GL_DST_COLOR:
      result := 'GL_DST_COLOR';     
    GL_ONE_MINUS_DST_COLOR:
      result := 'GL_ONE_MINUS_DST_COLOR';     
    GL_SRC_ALPHA_SATURATE:
      result := 'GL_SRC_ALPHA_SATURATE';     
    GL_FUNC_ADD:
      result := 'GL_FUNC_ADD';     
    GL_BLEND_EQUATION:
      result := 'GL_BLEND_EQUATION';     
    //GL_BLEND_EQUATION_RGB:
    //  result := 'GL_BLEND_EQUATION_RGB';     
    GL_BLEND_EQUATION_ALPHA:
      result := 'GL_BLEND_EQUATION_ALPHA';     
    GL_FUNC_SUBTRACT:
      result := 'GL_FUNC_SUBTRACT';     
    GL_FUNC_REVERSE_SUBTRACT:
      result := 'GL_FUNC_REVERSE_SUBTRACT';     
    GL_BLEND_DST_RGB:
      result := 'GL_BLEND_DST_RGB';     
    GL_BLEND_SRC_RGB:
      result := 'GL_BLEND_SRC_RGB';     
    GL_BLEND_DST_ALPHA:
      result := 'GL_BLEND_DST_ALPHA';     
    GL_BLEND_SRC_ALPHA:
      result := 'GL_BLEND_SRC_ALPHA';     
    GL_CONSTANT_COLOR:
      result := 'GL_CONSTANT_COLOR';     
    GL_ONE_MINUS_CONSTANT_COLOR:
      result := 'GL_ONE_MINUS_CONSTANT_COLOR';     
    GL_CONSTANT_ALPHA:
      result := 'GL_CONSTANT_ALPHA';     
    GL_ONE_MINUS_CONSTANT_ALPHA:
      result := 'GL_ONE_MINUS_CONSTANT_ALPHA';     
    GL_BLEND_COLOR:
      result := 'GL_BLEND_COLOR';     
    GL_ARRAY_BUFFER:
      result := 'GL_ARRAY_BUFFER';     
    GL_ELEMENT_ARRAY_BUFFER:
      result := 'GL_ELEMENT_ARRAY_BUFFER';     
    GL_ARRAY_BUFFER_BINDING:
      result := 'GL_ARRAY_BUFFER_BINDING';     
    GL_ELEMENT_ARRAY_BUFFER_BINDING:
      result := 'GL_ELEMENT_ARRAY_BUFFER_BINDING';     
    GL_STREAM_DRAW:
      result := 'GL_STREAM_DRAW';     
    GL_STATIC_DRAW:
      result := 'GL_STATIC_DRAW';     
    GL_DYNAMIC_DRAW:
      result := 'GL_DYNAMIC_DRAW';     
    GL_BUFFER_SIZE:
      result := 'GL_BUFFER_SIZE';     
    GL_BUFFER_USAGE:
      result := 'GL_BUFFER_USAGE';     
    GL_CURRENT_VERTEX_ATTRIB:
      result := 'GL_CURRENT_VERTEX_ATTRIB';     
    GL_FRONT:
      result := 'GL_FRONT';     
    GL_BACK:
      result := 'GL_BACK';     
    GL_FRONT_AND_BACK:
      result := 'GL_FRONT_AND_BACK';     
    GL_TEXTURE_2D:
      result := 'GL_TEXTURE_2D';     
    GL_CULL_FACE:
      result := 'GL_CULL_FACE';     
    GL_BLEND:
      result := 'GL_BLEND';     
    GL_DITHER:
      result := 'GL_DITHER';     
    GL_STENCIL_TEST:
      result := 'GL_STENCIL_TEST';     
    GL_DEPTH_TEST:
      result := 'GL_DEPTH_TEST';     
    GL_SCISSOR_TEST:
      result := 'GL_SCISSOR_TEST';     
    GL_POLYGON_OFFSET_FILL:
      result := 'GL_POLYGON_OFFSET_FILL';     
    GL_SAMPLE_ALPHA_TO_COVERAGE:
      result := 'GL_SAMPLE_ALPHA_TO_COVERAGE';     
    GL_SAMPLE_COVERAGE:
      result := 'GL_SAMPLE_COVERAGE';     
    GL_INVALID_ENUM:
      result := 'GL_INVALID_ENUM';     
    GL_INVALID_VALUE:
      result := 'GL_INVALID_VALUE';     
    GL_INVALID_OPERATION:
      result := 'GL_INVALID_OPERATION';     
    GL_OUT_OF_MEMORY:
      result := 'GL_OUT_OF_MEMORY';     
    GL_CW:
      result := 'GL_CW';     
    GL_CCW:
      result := 'GL_CCW';     
    GL_LINE_WIDTH:
      result := 'GL_LINE_WIDTH';     
    GL_ALIASED_POINT_SIZE_RANGE:
      result := 'GL_ALIASED_POINT_SIZE_RANGE';     
    GL_ALIASED_LINE_WIDTH_RANGE:
      result := 'GL_ALIASED_LINE_WIDTH_RANGE';     
    GL_CULL_FACE_MODE:
      result := 'GL_CULL_FACE_MODE';     
    GL_FRONT_FACE:
      result := 'GL_FRONT_FACE';     
    GL_DEPTH_RANGE:
      result := 'GL_DEPTH_RANGE';     
    GL_DEPTH_WRITEMASK:
      result := 'GL_DEPTH_WRITEMASK';     
    GL_DEPTH_CLEAR_VALUE:
      result := 'GL_DEPTH_CLEAR_VALUE';     
    GL_DEPTH_FUNC:
      result := 'GL_DEPTH_FUNC';     
    GL_STENCIL_CLEAR_VALUE:
      result := 'GL_STENCIL_CLEAR_VALUE';     
    GL_STENCIL_FUNC:
      result := 'GL_STENCIL_FUNC';     
    GL_STENCIL_FAIL:
      result := 'GL_STENCIL_FAIL';     
    GL_STENCIL_PASS_DEPTH_FAIL:
      result := 'GL_STENCIL_PASS_DEPTH_FAIL';     
    GL_STENCIL_PASS_DEPTH_PASS:
      result := 'GL_STENCIL_PASS_DEPTH_PASS';     
    GL_STENCIL_REF:
      result := 'GL_STENCIL_REF';     
    GL_STENCIL_VALUE_MASK:
      result := 'GL_STENCIL_VALUE_MASK';     
    GL_STENCIL_WRITEMASK:
      result := 'GL_STENCIL_WRITEMASK';     
    GL_STENCIL_BACK_FUNC:
      result := 'GL_STENCIL_BACK_FUNC';     
    GL_STENCIL_BACK_FAIL:
      result := 'GL_STENCIL_BACK_FAIL';     
    GL_STENCIL_BACK_PASS_DEPTH_FAIL:
      result := 'GL_STENCIL_BACK_PASS_DEPTH_FAIL';     
    GL_STENCIL_BACK_PASS_DEPTH_PASS:
      result := 'GL_STENCIL_BACK_PASS_DEPTH_PASS';     
    GL_STENCIL_BACK_REF:
      result := 'GL_STENCIL_BACK_REF';     
    GL_STENCIL_BACK_VALUE_MASK:
      result := 'GL_STENCIL_BACK_VALUE_MASK';     
    GL_STENCIL_BACK_WRITEMASK:
      result := 'GL_STENCIL_BACK_WRITEMASK';     
    GL_VIEWPORT:
      result := 'GL_VIEWPORT';     
    GL_SCISSOR_BOX:
      result := 'GL_SCISSOR_BOX';     
    GL_COLOR_CLEAR_VALUE:
      result := 'GL_COLOR_CLEAR_VALUE';     
    GL_COLOR_WRITEMASK:
      result := 'GL_COLOR_WRITEMASK';     
    GL_UNPACK_ALIGNMENT:
      result := 'GL_UNPACK_ALIGNMENT';     
    GL_PACK_ALIGNMENT:
      result := 'GL_PACK_ALIGNMENT';     
    GL_MAX_TEXTURE_SIZE:
      result := 'GL_MAX_TEXTURE_SIZE';     
    GL_MAX_VIEWPORT_DIMS:
      result := 'GL_MAX_VIEWPORT_DIMS';     
    GL_SUBPIXEL_BITS:
      result := 'GL_SUBPIXEL_BITS';     
    GL_RED_BITS:
      result := 'GL_RED_BITS';     
    GL_GREEN_BITS:
      result := 'GL_GREEN_BITS';     
    GL_BLUE_BITS:
      result := 'GL_BLUE_BITS';     
    GL_ALPHA_BITS:
      result := 'GL_ALPHA_BITS';     
    GL_DEPTH_BITS:
      result := 'GL_DEPTH_BITS';     
    GL_STENCIL_BITS:
      result := 'GL_STENCIL_BITS';     
    GL_POLYGON_OFFSET_UNITS:
      result := 'GL_POLYGON_OFFSET_UNITS';     
    GL_POLYGON_OFFSET_FACTOR:
      result := 'GL_POLYGON_OFFSET_FACTOR';     
    GL_TEXTURE_BINDING_2D:
      result := 'GL_TEXTURE_BINDING_2D';     
    GL_SAMPLE_BUFFERS:
      result := 'GL_SAMPLE_BUFFERS';     
    GL_SAMPLES:
      result := 'GL_SAMPLES';     
    GL_SAMPLE_COVERAGE_VALUE:
      result := 'GL_SAMPLE_COVERAGE_VALUE';     
    GL_SAMPLE_COVERAGE_INVERT:
      result := 'GL_SAMPLE_COVERAGE_INVERT';     
    GL_NUM_COMPRESSED_TEXTURE_FORMATS:
      result := 'GL_NUM_COMPRESSED_TEXTURE_FORMATS';     
    GL_COMPRESSED_TEXTURE_FORMATS:
      result := 'GL_COMPRESSED_TEXTURE_FORMATS';     
    GL_DONT_CARE:
      result := 'GL_DONT_CARE';     
    GL_FASTEST:
      result := 'GL_FASTEST';     
    GL_NICEST:
      result := 'GL_NICEST';     
    GL_GENERATE_MIPMAP_HINT:
      result := 'GL_GENERATE_MIPMAP_HINT';     
    GL_BYTE:
      result := 'GL_BYTE';     
    GL_UNSIGNED_BYTE:
      result := 'GL_UNSIGNED_BYTE';     
    GL_SHORT:
      result := 'GL_SHORT';     
    GL_UNSIGNED_SHORT:
      result := 'GL_UNSIGNED_SHORT';     
    GL_INT:
      result := 'GL_INT';     
    GL_UNSIGNED_INT:
      result := 'GL_UNSIGNED_INT';     
    GL_FLOAT:
      result := 'GL_FLOAT';
    {$ifdef API_OPENGLES}
    GL_FIXED:
      result := 'GL_FIXED';     
    {$endif}
    GL_DEPTH_COMPONENT:
      result := 'GL_DEPTH_COMPONENT';     
    GL_ALPHA:
      result := 'GL_ALPHA';     
    GL_RGB:
      result := 'GL_RGB';     
    GL_RGBA:
      result := 'GL_RGBA';     
    GL_LUMINANCE:
      result := 'GL_LUMINANCE';     
    GL_LUMINANCE_ALPHA:
      result := 'GL_LUMINANCE_ALPHA';     
    GL_UNSIGNED_SHORT_4_4_4_4:
      result := 'GL_UNSIGNED_SHORT_4_4_4_4';     
    GL_UNSIGNED_SHORT_5_5_5_1:
      result := 'GL_UNSIGNED_SHORT_5_5_5_1';     
    GL_UNSIGNED_SHORT_5_6_5:
      result := 'GL_UNSIGNED_SHORT_5_6_5';     
    GL_FRAGMENT_SHADER:
      result := 'GL_FRAGMENT_SHADER';     
    GL_VERTEX_SHADER:
      result := 'GL_VERTEX_SHADER';     
    GL_MAX_VERTEX_ATTRIBS:
      result := 'GL_MAX_VERTEX_ATTRIBS';  
    {$ifdef API_OPENGLES}     
    GL_MAX_VERTEX_UNIFORM_VECTORS:
      result := 'GL_MAX_VERTEX_UNIFORM_VECTORS';     
    GL_MAX_VARYING_VECTORS:
      result := 'GL_MAX_VARYING_VECTORS';   
    {$endif}  
    GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS:
      result := 'GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS';     
    GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS:
      result := 'GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS';     
    GL_MAX_TEXTURE_IMAGE_UNITS:
      result := 'GL_MAX_TEXTURE_IMAGE_UNITS';    
    {$ifdef API_OPENGLES} 
    GL_MAX_FRAGMENT_UNIFORM_VECTORS:
      result := 'GL_MAX_FRAGMENT_UNIFORM_VECTORS';    
    {$endif} 
    GL_SHADER_TYPE:
      result := 'GL_SHADER_TYPE';     
    GL_DELETE_STATUS:
      result := 'GL_DELETE_STATUS';     
    GL_LINK_STATUS:
      result := 'GL_LINK_STATUS';     
    GL_VALIDATE_STATUS:
      result := 'GL_VALIDATE_STATUS';     
    GL_ATTACHED_SHADERS:
      result := 'GL_ATTACHED_SHADERS';     
    GL_ACTIVE_UNIFORMS:
      result := 'GL_ACTIVE_UNIFORMS';     
    GL_ACTIVE_UNIFORM_MAX_LENGTH:
      result := 'GL_ACTIVE_UNIFORM_MAX_LENGTH';     
    GL_ACTIVE_ATTRIBUTES:
      result := 'GL_ACTIVE_ATTRIBUTES';     
    GL_ACTIVE_ATTRIBUTE_MAX_LENGTH:
      result := 'GL_ACTIVE_ATTRIBUTE_MAX_LENGTH';     
    GL_SHADING_LANGUAGE_VERSION:
      result := 'GL_SHADING_LANGUAGE_VERSION';     
    GL_CURRENT_PROGRAM:
      result := 'GL_CURRENT_PROGRAM';     
    GL_NEVER:
      result := 'GL_NEVER';     
    GL_LESS:
      result := 'GL_LESS';     
    GL_EQUAL:
      result := 'GL_EQUAL';     
    GL_LEQUAL:
      result := 'GL_LEQUAL';     
    GL_GREATER:
      result := 'GL_GREATER';     
    GL_NOTEQUAL:
      result := 'GL_NOTEQUAL';     
    GL_GEQUAL:
      result := 'GL_GEQUAL';     
    GL_ALWAYS:
      result := 'GL_ALWAYS';     
    GL_KEEP:
      result := 'GL_KEEP';     
    GL_REPLACE:
      result := 'GL_REPLACE';     
    GL_INCR:
      result := 'GL_INCR';     
    GL_DECR:
      result := 'GL_DECR';     
    GL_INVERT:
      result := 'GL_INVERT';     
    GL_INCR_WRAP:
      result := 'GL_INCR_WRAP';     
    GL_DECR_WRAP:
      result := 'GL_DECR_WRAP';     
    GL_VENDOR:
      result := 'GL_VENDOR';     
    GL_RENDERER:
      result := 'GL_RENDERER';     
    GL_VERSION:
      result := 'GL_VERSION';     
    GL_EXTENSIONS:
      result := 'GL_EXTENSIONS';     
    GL_NEAREST:
      result := 'GL_NEAREST';     
    GL_LINEAR:
      result := 'GL_LINEAR';     
    GL_NEAREST_MIPMAP_NEAREST:
      result := 'GL_NEAREST_MIPMAP_NEAREST';     
    GL_LINEAR_MIPMAP_NEAREST:
      result := 'GL_LINEAR_MIPMAP_NEAREST';     
    GL_NEAREST_MIPMAP_LINEAR:
      result := 'GL_NEAREST_MIPMAP_LINEAR';     
    GL_LINEAR_MIPMAP_LINEAR:
      result := 'GL_LINEAR_MIPMAP_LINEAR';     
    GL_TEXTURE_MAG_FILTER:
      result := 'GL_TEXTURE_MAG_FILTER';     
    GL_TEXTURE_MIN_FILTER:
      result := 'GL_TEXTURE_MIN_FILTER';     
    GL_TEXTURE_WRAP_S:
      result := 'GL_TEXTURE_WRAP_S';     
    GL_TEXTURE_WRAP_T:
      result := 'GL_TEXTURE_WRAP_T';     
    GL_TEXTURE:
      result := 'GL_TEXTURE';     
    GL_TEXTURE_CUBE_MAP:
      result := 'GL_TEXTURE_CUBE_MAP';     
    GL_TEXTURE_BINDING_CUBE_MAP:
      result := 'GL_TEXTURE_BINDING_CUBE_MAP';     
    GL_TEXTURE_CUBE_MAP_POSITIVE_X:
      result := 'GL_TEXTURE_CUBE_MAP_POSITIVE_X';     
    GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
      result := 'GL_TEXTURE_CUBE_MAP_NEGATIVE_X';     
    GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
      result := 'GL_TEXTURE_CUBE_MAP_POSITIVE_Y';     
    GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
      result := 'GL_TEXTURE_CUBE_MAP_NEGATIVE_Y';     
    GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
      result := 'GL_TEXTURE_CUBE_MAP_POSITIVE_Z';     
    GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
      result := 'GL_TEXTURE_CUBE_MAP_NEGATIVE_Z';     
    GL_MAX_CUBE_MAP_TEXTURE_SIZE:
      result := 'GL_MAX_CUBE_MAP_TEXTURE_SIZE';     
    GL_TEXTURE0:
      result := 'GL_TEXTURE0';     
    GL_TEXTURE1:
      result := 'GL_TEXTURE1';     
    GL_TEXTURE2:
      result := 'GL_TEXTURE2';     
    GL_TEXTURE3:
      result := 'GL_TEXTURE3';     
    GL_TEXTURE4:
      result := 'GL_TEXTURE4';     
    GL_TEXTURE5:
      result := 'GL_TEXTURE5';     
    GL_TEXTURE6:
      result := 'GL_TEXTURE6';     
    GL_TEXTURE7:
      result := 'GL_TEXTURE7';     
    GL_TEXTURE8:
      result := 'GL_TEXTURE8';     
    GL_TEXTURE9:
      result := 'GL_TEXTURE9';     
    GL_TEXTURE10:
      result := 'GL_TEXTURE10';     
    GL_TEXTURE11:
      result := 'GL_TEXTURE11';     
    GL_TEXTURE12:
      result := 'GL_TEXTURE12';     
    GL_TEXTURE13:
      result := 'GL_TEXTURE13';     
    GL_TEXTURE14:
      result := 'GL_TEXTURE14';     
    GL_TEXTURE15:
      result := 'GL_TEXTURE15';     
    GL_TEXTURE16:
      result := 'GL_TEXTURE16';     
    GL_TEXTURE17:
      result := 'GL_TEXTURE17';     
    GL_TEXTURE18:
      result := 'GL_TEXTURE18';     
    GL_TEXTURE19:
      result := 'GL_TEXTURE19';     
    GL_TEXTURE20:
      result := 'GL_TEXTURE20';     
    GL_TEXTURE21:
      result := 'GL_TEXTURE21';     
    GL_TEXTURE22:
      result := 'GL_TEXTURE22';     
    GL_TEXTURE23:
      result := 'GL_TEXTURE23';     
    GL_TEXTURE24:
      result := 'GL_TEXTURE24';     
    GL_TEXTURE25:
      result := 'GL_TEXTURE25';     
    GL_TEXTURE26:
      result := 'GL_TEXTURE26';     
    GL_TEXTURE27:
      result := 'GL_TEXTURE27';     
    GL_TEXTURE28:
      result := 'GL_TEXTURE28';     
    GL_TEXTURE29:
      result := 'GL_TEXTURE29';     
    GL_TEXTURE30:
      result := 'GL_TEXTURE30';     
    GL_TEXTURE31:
      result := 'GL_TEXTURE31';     
    GL_ACTIVE_TEXTURE:
      result := 'GL_ACTIVE_TEXTURE';     
    GL_REPEAT:
      result := 'GL_REPEAT';     
    GL_CLAMP_TO_EDGE:
      result := 'GL_CLAMP_TO_EDGE';     
    GL_MIRRORED_REPEAT:
      result := 'GL_MIRRORED_REPEAT';     
    GL_FLOAT_VEC2:
      result := 'GL_FLOAT_VEC2';     
    GL_FLOAT_VEC3:
      result := 'GL_FLOAT_VEC3';     
    GL_FLOAT_VEC4:
      result := 'GL_FLOAT_VEC4';     
    GL_INT_VEC2:
      result := 'GL_INT_VEC2';     
    GL_INT_VEC3:
      result := 'GL_INT_VEC3';     
    GL_INT_VEC4:
      result := 'GL_INT_VEC4';     
    GL_BOOL:
      result := 'GL_BOOL';     
    GL_BOOL_VEC2:
      result := 'GL_BOOL_VEC2';     
    GL_BOOL_VEC3:
      result := 'GL_BOOL_VEC3';     
    GL_BOOL_VEC4:
      result := 'GL_BOOL_VEC4';     
    GL_FLOAT_MAT2:
      result := 'GL_FLOAT_MAT2';     
    GL_FLOAT_MAT3:
      result := 'GL_FLOAT_MAT3';     
    GL_FLOAT_MAT4:
      result := 'GL_FLOAT_MAT4';     
    GL_SAMPLER_2D:
      result := 'GL_SAMPLER_2D';     
    GL_SAMPLER_CUBE:
      result := 'GL_SAMPLER_CUBE';     
    GL_VERTEX_ATTRIB_ARRAY_ENABLED:
      result := 'GL_VERTEX_ATTRIB_ARRAY_ENABLED';     
    GL_VERTEX_ATTRIB_ARRAY_SIZE:
      result := 'GL_VERTEX_ATTRIB_ARRAY_SIZE';     
    GL_VERTEX_ATTRIB_ARRAY_STRIDE:
      result := 'GL_VERTEX_ATTRIB_ARRAY_STRIDE';     
    GL_VERTEX_ATTRIB_ARRAY_TYPE:
      result := 'GL_VERTEX_ATTRIB_ARRAY_TYPE';     
    GL_VERTEX_ATTRIB_ARRAY_NORMALIZED:
      result := 'GL_VERTEX_ATTRIB_ARRAY_NORMALIZED';     
    GL_VERTEX_ATTRIB_ARRAY_POINTER:
      result := 'GL_VERTEX_ATTRIB_ARRAY_POINTER';     
    GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING:
      result := 'GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING'; 
    {$ifdef API_OPENGLES}    
    GL_IMPLEMENTATION_COLOR_READ_TYPE:
      result := 'GL_IMPLEMENTATION_COLOR_READ_TYPE';     
    GL_IMPLEMENTATION_COLOR_READ_FORMAT:
      result := 'GL_IMPLEMENTATION_COLOR_READ_FORMAT';     
    {$endif}
    GL_COMPILE_STATUS:
      result := 'GL_COMPILE_STATUS';     
    GL_INFO_LOG_LENGTH:
      result := 'GL_INFO_LOG_LENGTH';     
    GL_SHADER_SOURCE_LENGTH:
      result := 'GL_SHADER_SOURCE_LENGTH';     
    {$ifdef API_OPENGLES}
    GL_SHADER_COMPILER:
      result := 'GL_SHADER_COMPILER';     
    GL_SHADER_BINARY_FORMATS:
      result := 'GL_SHADER_BINARY_FORMATS';     
    GL_NUM_SHADER_BINARY_FORMATS:
      result := 'GL_NUM_SHADER_BINARY_FORMATS';     
    GL_LOW_FLOAT:
      result := 'GL_LOW_FLOAT';     
    GL_MEDIUM_FLOAT:
      result := 'GL_MEDIUM_FLOAT';     
    GL_HIGH_FLOAT:
      result := 'GL_HIGH_FLOAT';     
    GL_LOW_INT:
      result := 'GL_LOW_INT';     
    GL_MEDIUM_INT:
      result := 'GL_MEDIUM_INT';     
    GL_HIGH_INT:
      result := 'GL_HIGH_INT';    
    {$endif}
    GL_FRAMEBUFFER:
      result := 'GL_FRAMEBUFFER';     
    GL_RENDERBUFFER:
      result := 'GL_RENDERBUFFER';     
    GL_RGBA4:
      result := 'GL_RGBA4';     
    GL_RGB5_A1:
      result := 'GL_RGB5_A1';   
    {$ifdef API_OPENGLES}  
    GL_RGB565:
      result := 'GL_RGB565';     
    {$endif}
    GL_DEPTH_COMPONENT16:
      result := 'GL_DEPTH_COMPONENT16';     
    //GL_STENCIL_INDEX:
    //  result := 'GL_STENCIL_INDEX';     
    //GL_STENCIL_INDEX8:
    //  result := 'GL_STENCIL_INDEX8';     
    GL_RENDERBUFFER_WIDTH:
      result := 'GL_RENDERBUFFER_WIDTH';     
    GL_RENDERBUFFER_HEIGHT:
      result := 'GL_RENDERBUFFER_HEIGHT';     
    GL_RENDERBUFFER_INTERNAL_FORMAT:
      result := 'GL_RENDERBUFFER_INTERNAL_FORMAT';     
    GL_RENDERBUFFER_RED_SIZE:
      result := 'GL_RENDERBUFFER_RED_SIZE';     
    GL_RENDERBUFFER_GREEN_SIZE:
      result := 'GL_RENDERBUFFER_GREEN_SIZE';     
    GL_RENDERBUFFER_BLUE_SIZE:
      result := 'GL_RENDERBUFFER_BLUE_SIZE';     
    GL_RENDERBUFFER_ALPHA_SIZE:
      result := 'GL_RENDERBUFFER_ALPHA_SIZE';     
    GL_RENDERBUFFER_DEPTH_SIZE:
      result := 'GL_RENDERBUFFER_DEPTH_SIZE';     
    GL_RENDERBUFFER_STENCIL_SIZE:
      result := 'GL_RENDERBUFFER_STENCIL_SIZE';     
    GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE:
      result := 'GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE';     
    GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME:
      result := 'GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME';     
    GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL:
      result := 'GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL';     
    GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE:
      result := 'GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE';     
    GL_COLOR_ATTACHMENT0:
      result := 'GL_COLOR_ATTACHMENT0';     
    GL_DEPTH_ATTACHMENT:
      result := 'GL_DEPTH_ATTACHMENT';     
    GL_STENCIL_ATTACHMENT:
      result := 'GL_STENCIL_ATTACHMENT';     
    GL_FRAMEBUFFER_COMPLETE:
      result := 'GL_FRAMEBUFFER_COMPLETE';     
    GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT:
      result := 'GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT';     
    GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
      result := 'GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT';   
    {$ifdef API_OPENGLES}  
    GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
      result := 'GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS';     
    {$endif}
    GL_FRAMEBUFFER_UNSUPPORTED:
      result := 'GL_FRAMEBUFFER_UNSUPPORTED';     
    GL_FRAMEBUFFER_BINDING:
      result := 'GL_FRAMEBUFFER_BINDING';     
    GL_RENDERBUFFER_BINDING:
      result := 'GL_RENDERBUFFER_BINDING';     
    GL_MAX_RENDERBUFFER_SIZE:
      result := 'GL_MAX_RENDERBUFFER_SIZE';     
    GL_INVALID_FRAMEBUFFER_OPERATION:
      result := 'GL_INVALID_FRAMEBUFFER_OPERATION'; 
    otherwise
      exit(HexStr(enum, 4));
  end;
  result += ' ($'+HexStr(enum, 4)+')';
end;

procedure GLAssert (messageString: string = 'OpenGL error');
var
  error: GLenum;
begin
  error := glGetError();
  Assert(error = GL_NO_ERROR, messageString+' '+GLEnumToStr(error));
end;

end.