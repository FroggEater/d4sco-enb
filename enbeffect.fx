/* -------------------------------------------------------------------------- */
/*                                D4SCO EFFECTS                               */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

/* --------------------------- External Parameters -------------------------- */

// x = generic timer in range 0..1, period of 16777216 ms (4.6 hours)
// y = average fps
// w = frame time elapsed (in seconds)
float4 Timer;
// x = Width
// y = 1/Width
// z = aspect
// w = 1/aspect, aspect is Width/Height
float4 ScreenSize;
// changes in range 0..1, 0 means full quality, 1 lowest dynamic quality (0.33, 0.66 are limits for quality levels)
float	AdaptiveQuality;
// x = current weather index
// y = outgoing weather index
// z = weather transition
// w = time of the day in 24 standart hours. Weather index is value from weather ini file, for example WEATHER002 means index==2, but index==0 means that weather not captured.
float4 Weather;
// x = dawn
// y = sunrise
// z = day
// w = sunset. Interpolators range from 0..1
float4 TimeOfDay1;
// x = dusk
// y = night. Interpolators range from 0..1
float4 TimeOfDay2;
// changes in range 0..1, 0 means that night time, 1 - day time
float	ENightDayFactor;
// changes 0 or 1. 0 means that exterior, 1 - interior
float	EInteriorFactor;
// x = Width
// y = 1/Width
// z = aspect
// w = 1/aspect, aspect is Width/Height
float4 BloomSize;

/* ---------------------------- Debug Parameters ---------------------------- */

// keyboard controlled temporary variables. Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4 tempF1; // 0,1,2,3
float4 tempF2; // 5,6,7,8
float4 tempF3; // 9,0
// xy = cursor position in range 0..1 of screen;
// z = is shader editor window active;
// w = mouse buttons with values 0..7 as follows:
//    0 = none
//    1 = left
//    2 = right
//    3 = left+right
//    4 = middle
//    5 = left+middle
//    6 = right+middle
//    7 = left+right+middle (or rather cat is sitting on your mouse)
float4 tempInfo1;
// xy = cursor position of previous left mouse button click
// zw = cursor position of previous right mouse button click
float4 tempInfo2;

/* --------------------------- SSE/ENB Parameters --------------------------- */

// SSE parameters
float4 Params01[7];

// ENB parameters
// x - bloom amount
// y - lens amount
float4 ENBParams01;

/* ------------------------ Textures & Render Targets ----------------------- */

Texture2D			TextureColor; //hdr color, in multipass mode it's previous pass 32 bit ldr, except when temporary render targets are used
Texture2D			TextureBloom; //vanilla or enb bloom
Texture2D			TextureLens; //enb lens fx
Texture2D			TextureDepth; //scene depth
Texture2D			TextureAdaptation; //vanilla or enb adaptation
Texture2D			TextureAperture; //this frame aperture 1*1 R32F hdr red channel only. computed in depth of field shader file
Texture2D			TexturePalette; //enbpalette texture, if loaded and enabled in [colorcorrection].

//textures of multipass technique
Texture2D			TextureOriginal; //color R16B16G16A16 64 bit hdr format
//temporary textures which can be set as render target for techniques via annotations like <string RenderTarget="RenderTargetRGBA32";>
Texture2D			RenderTargetRGBA32; //R8G8B8A8 32 bit ldr format
Texture2D			RenderTargetRGBA64; //R16B16G16A16 64 bit ldr format
Texture2D			RenderTargetRGBA64F; //R16B16G16A16F 64 bit hdr format
Texture2D			RenderTargetR16F; //R16F 16 bit hdr format with red channel only
Texture2D			RenderTargetR32F; //R32F 32 bit hdr format with red channel only
Texture2D			RenderTargetRGB32F; //32 bit hdr format without alpha

/* -------------------------------- Includes -------------------------------- */

#include "D4SCO/aces.fxh"
#include "D4SCO/helpers.fxh"
#include "D4SCO/macros.fxh"
#include "D4SCO/ui.fxh"

/* -------------------------------------------------------------------------- */
/*                                    PARTS                                   */
/* -------------------------------------------------------------------------- */

/* ----------------------------------- UI ----------------------------------- */

UI_HEAD("Effects")

UI_BLNK(1)

UI_CTGR(1, "ACES Settings")
UI_SPLT(1)
UI_BOOL(bUseAces, "Enable ACES", false)
UI_INT(iAcesColorspace, "AP# Colorspace", 0, 1, 0)
UI_FLOAT(fIDTExposureMultiplier, "IDT Exposure Pre-multiplier", 0.0, 2.0, 1.0)
UI_FLOAT(fRRTSatFactor, "RRT Saturation Factor", 0.0, 1.0, 0.96)
UI_FLOAT(fODTSatFactor, "ODT Saturation Factor", 0.0, 1.0, 0.93)

UI_BLNK(2)

UI_MESG(1, "RRT Specific Settings")
UI_FLOAT(fYcRadiusWeight, "Glow: Yc Radius Weight", 0.0, 2.0, 1.75)
UI_FLOAT(fGlowGain, "Glow: Gain Amount", 0.0, 0.5, 0.05)
UI_FLOAT(fGlowMid, "Glow: Middle Point", 0.0, 0.5, 0.08)

UI_BLNK(3)

UI_FLOAT(fRedHue, "Red: Hue Angle", 0.0, 360.0, 0.0)
UI_FLOAT(fRedWidth, "Red: Base Width", 0.0, 360.0, 135.0)
UI_FLOAT(fRedPivot, "Red: Pivot Point", 0.0, 0.5, 0.03)
UI_FLOAT(fRedScale, "Red: Scale", 0.0, 2.0, 0.82)

UI_BLNK(4)

UI_CTGR(2, "AGCC Settings")
UI_SPLT(2)
UI_BOOL(bUseAGCC, "Enable AGCC", false)
UI_FLOAT(fAGCCSatMult, "AGCC Saturation Multiplier", 0.0, 2.0, 1.0)
UI_FLOAT(fAGCCConMult, "AGCC Contrast Multiplier", 0.0, 2.0, 1.0)
UI_FLOAT(fAGCCBrtMult, "AGCC Brightness Multiplier", 0.0, 2.0, 1.0)
UI_FLOAT(fAGCCTintMult, "AGCC Tint Multiplier", 0.0, 2.0, 1.0)
UI_FLOAT(fAGCCFadeMult, "AGCC Fade Multiplier", 0.0, 2.0, 1.0)

#include "D4SCO/debug.fxh"

/* -------------------------------- Functions ------------------------------- */

float3 applyAGCC(float3 color)
{
  float gameSaturation = Params01[3].x * fAGCCSatMult;
  float gameContrast = Params01[3].z * fAGCCConMult;
  float gameBrightness = Params01[3].w * fAGCCBrtMult;

  float3 gameTintColor = applyIDTtoAP1(Params01[4].rgb);
  float3 gameFadeColor = applyIDTtoAP1(Params01[5].rgb);
  float gameTintWeight = Params01[4].a * fAGCCTintMult;
  float gameFadeWeight = Params01[5].a * fAGCCFadeMult;

  float grey = dot(color, LUM_AP1);
  float3 middle = float3(0.5, 0.5, 0.5);

  color = lerp(grey, color, gameSaturation);
  color = lerp(middle, color, gameContrast) * gameBrightness;
  color = lerp(color, grey * gameTintColor, gameTintWeight);
  color = lerp(color, gameFadeColor, gameFadeWeight);

  return color;
}

/* -------------------------------------------------------------------------- */
/*                                   SHADERS                                  */
/* -------------------------------------------------------------------------- */

/* ---------------------------------- Pixel --------------------------------- */

float4	PS_Draw(float4 pos : SV_POSITION, float2 txcoord: TEXCOORD0) : SV_TARGET
{
  float3 color = TextureColor.Sample(PointSampler, txcoord.xy).rgb;

  if (bUseAces)
  {
    color = iAcesColorspace == 0 ?
      applyIDTtoAP0(color, fIDTExposureMultiplier) :
      applyIDTtoAP1(color, fIDTExposureMultiplier);

    if (bUseAGCC)
      color = applyAGCC(color);

    color = applyRRT(	
      color,
      iAcesColorspace,
      fYcRadiusWeight,
      fGlowGain,
      fGlowMid,
      fRedHue,
      fRedWidth,
      fRedPivot,
      fRedScale,
      fRRTSatFactor
    );

    color = applyPartialODT(color, iAcesColorspace, fODTSatFactor);
    color = sRGBltosRGB(color);
  }
  return debug(float4(saturate(color), 1.0));
}

// NOTE Vanilla shader, do not modify
float4	PS_DrawOriginal(float4 pos : SV_POSITION, float2 txcoord : TEXCOORD0) : SV_TARGET
{
  float4	res;
  float4	color;

  float2	scaleduv=Params01[6].xy*txcoord.xy;
  scaleduv=max(scaleduv, 0.0);
  scaleduv=min(scaleduv, Params01[6].zy);

  color=TextureColor.Sample(PointSampler, txcoord.xy); //hdr scene color

  float4	r0, r1, r2, r3;
  r1.xy=scaleduv;
  r0.xyz = color.xyz;
  if (0.5<=Params01[0].x) r1.xy=txcoord.xy;
  r1.xyz = TextureBloom.Sample(LinearSampler, r1.xy).xyz;
  r2.xy = TextureAdaptation.Sample(LinearSampler, txcoord.xy).xy; //in skyrimse it two component

  r0.w=dot(float3(2.125000e-001, 7.154000e-001, 7.210000e-002), r0.xyz);
  r0.w=max(r0.w, 1.000000e-005);
  r1.w=r2.y/r2.x;
  r2.y=r0.w * r1.w;
  if (0.5<Params01[2].z) r2.z=0xffffffff; else r2.z=0;
  r3.xy=r1.w * r0.w + float2(-4.000000e-003, 1.000000e+000);
  r1.w=max(r3.x, 0.0);
  r3.xz=r1.w * 6.2 + float2(5.000000e-001, 1.700000e+000);
  r2.w=r1.w * r3.x;
  r1.w=r1.w * r3.z + 6.000000e-002;
  r1.w=r2.w / r1.w;
  r1.w=pow(r1.w, 2.2);
  r1.w=r1.w * Params01[2].y;
  r2.w=r2.y * Params01[2].y + 1.0;
  r2.y=r2.w * r2.y;
  r2.y=r2.y / r3.y;
  if (r2.z==0) r1.w=r2.y; else r1.w=r1.w;
  r0.w=r1.w / r0.w;
  r1.w=saturate(Params01[2].x - r1.w);
  r1.xyz=r1 * r1.w;
  r0.xyz=r0 * r0.w + r1;
  r1.x=dot(r0.xyz, float3(2.125000e-001, 7.154000e-001, 7.210000e-002));
  r0.w=1.0;
  r0=r0 - r1.x;
  r0=Params01[3].x * r0 + r1.x;
  r1=Params01[4] * r1.x - r0;
  r0=Params01[4].w * r1 + r0;
  r0=Params01[3].w * r0 - r2.x;
  r0=Params01[3].z * r0 + r2.x;
  r0.xyz=saturate(r0);
  r1.xyz=pow(r1.xyz, Params01[6].w);
  //active only in certain modes, like khajiit vision, otherwise Params01[5].w=0
  r1=Params01[5] - r0;
  res=Params01[5].w * r1 + r0;

//	res.xyz = color.xyz;
//	res.w=1.0;
  return res;
}

/* -------------------------------------------------------------------------- */
/*                                 TECHNIQUES                                 */
/* -------------------------------------------------------------------------- */

TECH(Draw, "D4SCO - Effects", VS_Basic(), PS_Draw())
TECH(DrawOriginal, "Vanilla", VS_Basic(), PS_DrawOriginal())

// technique11 ORIGINALPOSTPROCESS <string UIName="Vanilla";> //do not modify this technique
// {
// 	pass p0
// 	{
// 		SetVertexShader(CompileShader(vs_5_0, VS_Draw()));
// 		SetPixelShader(CompileShader(ps_5_0, PS_DrawOriginal()));
// 	}
// }
