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
static const float RRT_RED_HUE = 0.0;
static const float RRT_RED_WIDTH = 135.0;
static const float RRT_RED_PIVOT = 0.03;
static const float RRT_RED_SCALE = 0.82;
static const float RRT_SAT_FACTOR = 0.96;

static const float ODT_CINEMA_BLACK = 0.02;
static const float ODT_CINEMA_WHITE = 48.0;
static const float ODT_SURROUND_GAMMA = 0.9811;
static const float ODT_SAT_FACTOR = 0.93;


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
float3 applyRRT(float3 aces, float glowGain = RRT_GLOW_GAIN, float glowMid = RRT_GLOW_MID, float sat = RRT_SAT_FACTOR)
{
  if (ACES_SWEETENERS)
  {
    // Glow correction
    float saturation = RGBtoSaturation(aces);
    float yc = RGBtoYc(aces);
    float s = sigmoidShaper((saturation - 0.4) / 0.2);
    float glow = 1.0 + computeGlow(yc, glowGain * s, glowMid);

    aces *= glow;

    // Red correction
    float hue = RGBtoHue(aces);
    float centeredHue = centerHue(hue, RRT_RED_HUE);
    float hueWeight = cubicBasisShaper(centeredHue, RRT_RED_WIDTH);

    aces.r += hueWeight * saturation * (RRT_RED_PIVOT - aces.r) * (1.0 - RRT_RED_SCALE);
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
float3 applyPartialODT(float3 oces, float sat = ODT_SAT_FACTOR)
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
