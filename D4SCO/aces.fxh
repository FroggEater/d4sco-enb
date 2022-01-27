/* -------------------------------------------------------------------------- */
/*                                 D4SCO ACES                                 */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_ACES
#define D4SCO_ACES

/* -------------------------------- Includes -------------------------------- */

#include "D4SCO/colorspaces.fxh"
#include "D4SCO/conversions.fxh"
#include "D4SCO/curves.fxh"
#include "D4SCO/helpers.fxh"

/* -------------------------------- Constants ------------------------------- */

static const uint ACES_COLORSPACE = 1;
static const bool ACES_SWEETENERS = true;
static const bool ACES_SURROUND = false;
static const bool ACES_SIMPLE_TRANSFORM = true;

static const float RRT_GLOW_GAIN = 0.05;
static const float RRT_GLOW_MID = 0.08;

static const float RRT_HUE_WIDTH = 135.0;
static const float RRT_RED_HUE = 0.0;
static const float RRT_RED_PIVOT = 0.03;
static const float RRT_RED_SCALE = 0.82;
static const float RRT_GREEN_HUE = 120.0;
static const float RRT_GREEN_PIVOT = 0.0;
static const float RRT_GREEN_SCALE = 1.0;
static const float RRT_BLUE_HUE = 240.0;
static const float RRT_BLUE_PIVOT = 0.0;
static const float RRT_BLUE_SCALE = 1.0;

static const float RRT_SAT_FACTOR = 0.96;

static const float ODT_CINEMA_BLACK = 0.02;
static const float ODT_CINEMA_WHITE = 48.0;
static const float ODT_SURROUND_GAMMA = 0.9811;
static const float ODT_SAT_FACTOR = 0.93;

static const float HK_A = 0.03017;
static const float HK_B = 0.04556;
static const float HK_C = 0.02667;
static const float HK_D = 0.00295;
static const float HK_E = 0.14592;
static const float HK_F = 0.05084;
static const float HK_G = 0.01900;
static const float HK_H = 0.00764;


static const SegmentedSplineC5Params C5_PARAMS_RRT =
{
  // coefsLow[6] & coefsHigh[6]
  {-4.0, -4.0, -3.1573765773, -0.4852499958, 1.8477324706, 1.8477324706},
  {-0.7185482425, 2.0810307172, 3.6681241237, 4.0, 4.0, 4.0},

  // minPoint, midPoint, maxPoint
  {0.18 * exp2(-15.0), D4},
  {0.18, 4.8}, 
  {0.18 * exp2(18.0), 10000.0},

  // slopeLow, slopeHigh
  0.0,
  0.0
};

static const SegmentedSplineC9Params C9_PARAMS_ODT48 =
{
  // coefsLow[10] & coefsHigh[10]
  {-1.6989700043, -1.6989700043, -1.4779, -1.2291, -0.8648, -0.448, 0.00518, 0.4511080334, 0.9113744414, 0.9113744414},
  {0.5154386965, 0.8470437783, 1.1358, 1.3802, 1.5197, 1.5985, 1.6467, 1.6746091357, 1.687873339, 1.687873339},

  // minPoint, midPoint, maxPoint
  {applySegmentedSplineC5(0.18 * exp2(-6.5), C5_PARAMS_RRT), 0.02},
  {applySegmentedSplineC5(0.18, C5_PARAMS_RRT), 4.8},
  {applySegmentedSplineC5(0.18 * exp2(6.5), C5_PARAMS_RRT), 48.0},

  // slopeLow, slopeHigh
  0.0,
  0.04
};

/* -------------------------------- Functions ------------------------------- */

float computeGlow(float yc, float glowGain, float glowMid)
{
  float glow;

  if (yc <= 2.0 / 3.0 * glowMid)
    glow = glowGain;
  else if (yc >= 2.0 * glowMid)
    glow = 0.0;
  else
    glow = glowGain * (glowMid / yc - 0.5);

  return glow;
}

float3 applyBrighterSurround(float3 color)
{
  color = AP1toXYZ(color);
  color = XYZtoxyY(color);

  color.y = clamp(color.y, 0.0, HALF_MAX);
  color.y = pow(color.y, ODT_SURROUND_GAMMA);

  color = xyYtoXYZ(color);
  color = XYZtoAP1(color);
  return color;
}

float3 applyNayataniModel(float3 color, float lum = 0.5, float shift = 0.0872)
{
  static const float den = -2.0 * WP_65.x + 12.0 * WP_65.y + 3.0;
  static const float2 wpuv = float2(4.0 * WP_65.x / den, 9.0 * WP_65.y / den);

  float3 xyz = AP1toXYZ(color);
  xyz = D60toD65(color);
  xyz = clamp(xyz, 0.0, FLT_MAX);

  float3 luv = XYZtoLuv(xyz);

  float mult = -0.866;
  float K = 0.2717 * (6.469 + 6.362 * pow(lum, 0.4495)) / (6.489 + pow(lum, 0.4495));

  float hue = atan2(luv.z - wpuv.y, luv.y - wpuv.x);
  hue = hue < 0.0 ? hue + radians(360.0) : hue;

  float q =
    -0.01585 -
    HK_A * cos(hue) -
    HK_B * cos(2.0 * hue) -
    HK_C * cos(3.0 * hue) -
    HK_D * cos(4.0 * hue) +
    HK_E * sin(hue) +
    HK_F * sin(2.0 * hue) -
    HK_G * sin(3.0 * hue) -
    HK_H * sin(4.0 * hue);
  float suv = 13.0 * hypot(luv.y - wpuv.x, luv.z - wpuv.y);
  float s = 1.0 + (mult * q + shift * K) * suv;
  s = s == 0.0 ? 1.0 : 1.0 / s;

  return color * s;
}

/* ----------------------------------- IDT ---------------------------------- */

// ANCHOR | sRGB > ACES2065-1 or ACEScg | D65 > D60 (Bradford)
float3 applyIDT(float3 color, float exp = 1.0)
{
  color = sRGBtosRGBl(color);
  color *= exp;

  if (ACES_SIMPLE_TRANSFORM)
  {
    return ACES_COLORSPACE == 0 ?
      sRGBltoAP0(color) :
      sRGBltoAP1(color);
  }
  else
  {
    color = sRGBltoXYZ(color);
    color = D65toD60(color);
    return ACES_COLORSPACE == 0 ?
      XYZtoAP0(color) :
      XYZtoAP1(color);
  }
}

/* ----------------------------------- RRT ---------------------------------- */

// ANCHOR | ACES (AP0 or AP1) > OCES
float3 applyRRT(
  float3 aces,
  bool sweeteners = ACES_SWEETENERS,
  float glowGain = RRT_GLOW_GAIN,
  float glowMid = RRT_GLOW_MID,
  float sat = RRT_SAT_FACTOR,
  float redPivot = RRT_RED_PIVOT,
  float redScale = RRT_RED_SCALE,
  float greenPivot = RRT_GREEN_PIVOT,
  float greenScale = RRT_GREEN_SCALE,
  float bluePivot = RRT_BLUE_PIVOT,
  float blueScale = RRT_BLUE_SCALE
)
{
  if (sweeteners)
  {
    // Glow correction
    float saturation = RGBtoSaturation(aces);
    float yc = RGBtoYc(aces);
    float s = sigmoidShaper((saturation - 0.4) / 0.2);
    float glow = 1.0 + computeGlow(yc, glowGain * s, glowMid);

    aces *= glow;

    // Color correction
    float hue = RGBtoHue(aces);
    float redHue = centerHue(hue, RRT_RED_HUE);
    float greenHue = centerHue(hue, RRT_GREEN_HUE);
    float blueHue = centerHue(hue, RRT_BLUE_HUE);
    float redHueWeight = cubicBasisShaper(redHue, RRT_HUE_WIDTH);
    float greenHueWeight = cubicBasisShaper(greenHue, RRT_HUE_WIDTH);
    float blueHueWeight = cubicBasisShaper(blueHue, RRT_HUE_WIDTH);

    aces.r += redHueWeight * saturation * (redPivot - aces.r) * (1.0 - redScale);
    aces.g += greenHueWeight * saturation * (greenPivot - aces.g) * (1.0 - greenScale);
    aces.b += blueHueWeight * saturation * (bluePivot - aces.b) * (1.0 - blueScale);
  }

  // Go from ACES to RGB rendering space
  // aces = clamp(aces, 0.0, HALF_MAX);
  aces = clamp(aces, 0.0, FLT_MAX);

  if (ACES_COLORSPACE == 0)
  {
    aces = AP0toAP1(aces);
    aces = clamp(aces, 0.0, FLT_MAX);
  }

  // Global desaturation
  aces = lerp(dot(aces, LUM_AP1), aces, sat);

  // Apply tonescale for each channel
  aces = float3(
    applySegmentedSplineC5(aces.r, C5_PARAMS_RRT),
    applySegmentedSplineC5(aces.g, C5_PARAMS_RRT),
    applySegmentedSplineC5(aces.b, C5_PARAMS_RRT)
  );

  // Go from RGB to OCES and return
  float3 oces = aces;
  if (ACES_COLORSPACE == 0)
    oces = AP1toAP0(aces);

  return oces;
}

/* ----------------------------------- ODT ---------------------------------- */

// ANCHOR | OCES > sRGB' | D60 > D65
float3 applyPartialODT(
  float3 oces,
  bool nayatani = false,
  float lum = 0.5,
  float shift = 0.0872,
  float sat = ODT_SAT_FACTOR
)
{
  if (ACES_COLORSPACE == 0)
    oces = AP0toAP1(oces);
  
  // Apply tonescale for each channel
  oces = float3(
    applySegmentedSplineC9(oces.r, C9_PARAMS_ODT48),
    applySegmentedSplineC9(oces.g, C9_PARAMS_ODT48),
    applySegmentedSplineC9(oces.b, C9_PARAMS_ODT48)
  );

  // Scale luminance to a linear code value
  oces = float3(
    YtoLinear(oces.r, ODT_CINEMA_BLACK, ODT_CINEMA_WHITE),
    YtoLinear(oces.g, ODT_CINEMA_BLACK, ODT_CINEMA_WHITE),
    YtoLinear(oces.b, ODT_CINEMA_BLACK, ODT_CINEMA_WHITE)
  );

  // Compensate for a dimmer surround
  if (ACES_SURROUND) oces = applyBrighterSurround(oces);

  // Global desaturation to compensate for luminance differences
  oces = lerp(dot(oces, LUM_AP1), oces, sat);

  if (nayatani)
    oces = applyNayataniModel(oces, lum, shift);

  // Go back to sRGB' and return
  if (ACES_SIMPLE_TRANSFORM)
    oces = AP1tosRGBl(oces);
  else {
    oces = AP1toXYZ(oces);
    oces = D60toD65(oces);
    oces = XYZtosRGBl(oces);
  }
  return saturate(oces);
}

#endif
