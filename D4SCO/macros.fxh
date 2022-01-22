/* -------------------------------------------------------------------------- */
/*                                D4SCO MACROS                                */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_MACROS
#define D4SCO_MACROS

/* ---------------------------- Shader Shortcuts ---------------------------- */

#define PASS(NAME, VS, PS) \
  pass NAME \
  { \
    SetVertexShader(CompileShader(vs_5_0, VS)); \
    SetPixelShader(CompileShader(ps_5_0, PS)); \
  }

#define TECH(NAME, STR, VS, PS) \
  technique11 NAME <string UIName = STR;> \
  { \
    PASS(p0, VS, PS) \
  }
#define TECH2(NAME, STR, VS1, PS1, VS2, PS2) \
  technique11 NAME <string UIName = STR;> \
  { \
    PASS(p0, VS1, PS1) \
    PASS(p1, VS2, PS2) \
  }

#endif
