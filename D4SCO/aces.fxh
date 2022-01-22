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

static const float ODT_CINEMA_WHITE = 48.0;
static const float ODT_CINEMA_BLACK = 0.02;

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

float3 applyBrighterSurround(float3 color, float gamma = 0.9811)
{
  color = AP1toXYZ(color);
  color = XYZtoxyY(color);

  color.y = clamp(color.y, 0.0, HALF_MAX);
  color.y = pow(color.y, gamma);

  color = xyYtoXYZ(color);
  color = XYZtoAP1(color);
  return color;
}

/* ----------------------------------- IDT ---------------------------------- */

// ANCHOR | sRGB > ACES2065-1 | D65 > D60 (Bradford)
float3 applyIDTtoAP0(float3 color, float preExposure = 1.0)
{
  linColor = sRGBtosRGBl(color);
  return sRGBltoAP0(linColor * preExposure);
}

// ANCHOR | sRGB > ACEScg | D65 > D60 (Bradford)
float3 applyIDTtoAP1(float3 color, float preExposure = 1.0)
{
  linColor = sRGBtosRGBl(color);
  return sRGBltoAP1(linColor * preExposure);
}

/* ----------------------------------- RRT ---------------------------------- */

// TODO Put into a shared UI parameters file

// ANCHOR | ACES (AP0 or AP1) > OCES
float3 applyRRT(
  float3 aces,
  uint colorspace = 0,
  bool useSimpleCubic = false,
  float ycRadiusWeight = 1.75,
  float glowGain = 0.05,
  float glowMid = 0.08,
  float redHue = 0.0,
  float redWidth = 135.0,
  float redPivot = 0.03,
  float redScale = 0.82,
  float satFactor = 0.96
)
{
  // Glow correction
  float sat = RGBtoSaturation(aces);
  float yc = RGBtoYc(aces, ycRadiusWeight);
  float s = sigmoidShaper((sat - 0.4) / 0.2);
  float glow = 1.0 + computeGlow(yc, glowGain * s, glowMid);

  aces *= glow;

  // Red correction
  float hue = RGBtoHue(aces);
  float centeredHue = centerHue(hue, redHue);
  float hueWeight = cubicBasisShaper(centeredHue, redWidth, useSimpleCubic);

  aces.r += hueWeight * sat * (redPivot - aces.r) * (1.0 - redScale);

  // Go from ACES to RGB rendering space
  if (colorspace == 0)
  {
    aces = clamp(aces, 0.0, HALF_MAX);
    aces = AP0toAP1(aces);
  }

  aces = clamp(aces, 0.0, HALF_MAX);

  // Global desaturation
  aces = lerp(dot(aces, LUM_AP1), aces, satFactor);

  // Apply tonescale for each channel
  aces = float3(
    applySegmentedSplineC5(aces.r, C5_PARAMS_RRT),
    applySegmentedSplineC5(aces.g, C5_PARAMS_RRT),
    applySegmentedSplineC5(aces.b, C5_PARAMS_RRT)
  );

  // Go from RGB to OCES and return
  float3 oces = aces;
  if (colorspace == 0)
    oces = AP1toAP0(aces);

  return oces;
}

/* ----------------------------------- ODT ---------------------------------- */

// ANCHOR | OCES > sRGB' | D60 > D65
float3 applyPartialODT(
  float3 oces,
  uint colorspace = 0,
  float gamma = 0.9811,
  float satFactor = 0.93
)
{
  if (colorspace == 0)
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
  oces = applyBrighterSurround(oces, gamma);

  // Global desaturation to compensate for luminance differences
  oces = lerp(dot(oces, LUM_AP1), oces, satFactor);

  // Go back to sRGB' and return
  oces = AP1tosRGBl(oces);
  return saturate(oces);
}

#endif D4SCO_ACES
