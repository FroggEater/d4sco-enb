/* -------------------------------------------------------------------------- */
/*                                 D4SCO DEBUG                                */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By Froggeater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_DEBUG
#define D4SCO_DEBUG

/* -------------------------------- Includes -------------------------------- */

#include "ui.fxh"
#include "macros.fxh"
#include "helpers.fxh"

/* ------------------------------- UI Settings ------------------------------ */

UI_BLNK(50)

UI_CAT(_D1, "Debug Settings")
UI_SPLT(39)
UI_BOOL(bEnableTextures, "Enable Textures", false)
UI_FLOAT(fTextureScale, "Texture Scale", 0.25, 5.0, 1.0)
UI_FLOAT(fTextureScroll, "Texture Scroll", 0.0, 5.0, 0.0)

UI_BLNK(51)

UI_BOOL(bEnableSplitScreen, "Enable SplitScreen", false)
UI_FLOAT(fSplitScreenPercent, "ScplitScreen Percent", 0.0, 1.0, 0.5)

UI_BLNK(51)

UI_BOOL(bEnableClipping, "Enable Clipping", false)
UI_FLOAT(fClippingUpperTreshold, "Clipping Upper Treshold", 0.0, 1.0, 1.0)
UI_FLOAT(fClippingLowerTreshold, "Clipping Lower Treshold", 0.0, 1.0, 0.0)

/* -------------------------------------------------------------------------- */
/*                                   SHADERS                                  */
/* -------------------------------------------------------------------------- */

/* --------------------------------- Vertex --------------------------------- */

void VS_Debug(
  inout float4 pos : SV_POSITION,
  inout float2 txcoord : TEXCOORD0,
  uniform uint column,
  uniform uint order
)
{
  float divider = 10.0 / fTextureScale;
  float scroll = 1.0 + fTextureScroll;

  pos = float4(
    pos.x / divider + (divider - 1.0 - column * 2.0) / divider,
    pos.y / divider + (scroll * (divider - 1.0) - order * 2.0) / divider,
    pos.z,
    1.0
  );
}

/* ---------------------------------- Pixel --------------------------------- */

float4 PS_Texture(
  float4 pos : SV_POSITION,
  float2 txcoord : TEXCOORD0,
  uniform Texture2D TextureInput,
  uniform bool isSingleChannel = false
) : SV_TARGET
{
  clip(bEnableTextures ? 1.0 : -1.0);

  float3 color = isSingleChannel ?
    TextureInput.Sample(PointSampler, txcoord.xy).rrr :
    TextureInput.Sample(PointSampler, txcoord.xy).rgb;
  
  return float4(color, 1.0);
}

float4 PS_SplitScreen(
  float4 pos : SV_POSITION,
  float2 txcoord : TEXCOORD0,
  uniform Texture2D TextureInput
) : SV_TARGET
{
  clip(bEnableSplitScreen && txcoord.x < fSplitScreenPercent ? 1.0 : -1.0);

  float3 color = TextureInput.Sample(PointSampler, txcoord.xy).rgb;

  return float4(color, 1.0);
}

float4 PS_Clipping(
  float4 pos : SV_POSITION,
  float2 txcoord : TEXCOORD0,
  uniform Texture2D TextureInput
) : SV_TARGET
{
  float3 color = TextureInput.Sample(PointSampler, txcoord.xy).rgb;
  bool isOutside = ext3(color, fClippingLowerTreshold, fClippingUpperTreshold);

  clip(isOutside ? 1.0 : -1.0);

  float clipping = step(min3(color), 0.5);
  return float4(
    clipping,
    clipping,
    clipping,
    1.0
  );
}

/* -------------------------------------------------------------------------- */
/*                                 TECHNIQUES                                 */
/* -------------------------------------------------------------------------- */

#define PASS_DEBUG_TEXTURE(NAME, ORDER, TEXTURE, SINGLE) \
  PASS(NAME, VS_Debug(0, ORDER), PS_Texture(TEXTURE, SINGLE))
#define PASS_DEBUG_SPLITSCREEN(NAME, TEXTURE) \
  PASS(NAME, VS_Basic(), PS_SplitScreen(TEXTURE))
#define PASS_DEBUG_CLIPPING(NAME, TEXTURE) \
  PASS(NAME, VS_Basic(), PS_Clipping(TEXTURE))

#endif
