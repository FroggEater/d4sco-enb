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
// uint iACESColorSpace = 0;

// bool buseSimpleCubic = false;
// float fycRadiusWeight = 1.75;
// float fglowGain = 0.05;
// float fglowMid = 0.08;
// float fredHue = 0.0;
// float fredWidth = 135.0;
// float fredPivot = 0.03;
// float fredScale = 0.82;
// float fsatFactor = 0.96;

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
    applySegmentedSplineC5(aces.r),
    applySegmentedSplineC5(aces.g),
    applySegmentedSplineC5(aces.b)
  );

  // Go from RGB to OCES and return
  float3 oces = aces;
  if (colorspace == 0)
    oces = AP1toAP0(aces);

  return oces;
}

/* ----------------------------------- ODT ---------------------------------- */

// float cinemaWhite = 48.0;
// float cinemaBlack = 0.02;
// float satFactor = 0.93;

// ANCHOR | OCES > sRGB' | D60 > D65
float3 applyPartialODT(
  float3 oces,
  uint colorspace = 0,
  float cinemaBlack = 0.02,
  float cinemaWhite = 48.0,
  float gamma = 0.9811,
  float satFactor = 0.93
)
{
  if (colorspace == 0)
    oces = AP0toAP1(oces);
  
  // Apply tonescale for each channel
  oces = float3(
    applySegmentedSplineC9(oces.r),
    applySegmentedSplineC9(oces.g),
    applySegmentedSplineC9(oces.b)
  );

  // Scale luminance to a linear code value
  oces = float3(
    YtoLinear(oces.r, cinemaBlack, cinemaWhite),
    YtoLinear(oces.g, cinemaBlack, cinemaWhite),
    YtoLinear(oces.b, cinemaBlack, cinemaWhite)
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
