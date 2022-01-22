/* -------------------------------------------------------------------------- */
/*                                 D4SCO ACES                                 */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_ACES
#define D4SCO_ACES

/* -------------------------------- Includes -------------------------------- */

#include "D4SCO/colorspaces.fxh"
#include "D4SCO/helpers.fxh"

/* ------------------------------- Parameters ------------------------------- */

// TODO Put into a shared UI parameters file
uint iACESColorSpace = 0;

float fRRTGlowGain = 0.05;
float fRRTGlowMid = 0.08;
float fRRTRedHue = 0.0;
float fRRTRedWidth = 135.0;
float fRRTRedPivot = 0.03;
float fRRTRedScale = 0.82;
float fRRTSatFactor = 0.96;

float fODTCinemaWhite = 48.0;
float fODTCinemaBlack = 0.02;
float fODTSatFactor = 0.93;

/* ----------------------------------- IDT ---------------------------------- */

// ANCHOR | sRGB > ACES2065-1 | D65 > D60 (Bradford)
float3 applyIDTtoAP0(float3 color)
{
  linColor = sRGBtosRGBl(color);
  return sRGBltoAP0(linColor);
}

// ANCHOR | sRGB > ACEScg | D65 > D60 (Bradford)
float3 applyIDTtoAP1(float3 color)
{
  linColor = sRGBtosRGBl(color);
  return sRGBltoAP1(linColor);
}

/* ----------------------------------- RRT ---------------------------------- */

// ANCHOR | ACES (AP0 or AP1) > OCES
float3 applyRRT(float3 aces)
{
  // Glow correction
  float sat = RGBtoSaturation(aces);
  float yc = RGBtoYc(aces);
  float s = sigmoidShaper((sat - 0.4) / 0.2);
  float glow = 1.0 + applyGlow(yc, fRRTGlowGain * s, fRRTGlowMid);

  aces *= glow;

  // Red correction
  float hue = RGBtoHue(aces);
  float centeredHue = centerHue(hue, fRRTRedHue);
  float hueWeight = cubicBasisShaper(centeredHue, fRRTRedWidth);

  aces.r += hueWeight * sat * (fRRTRedPivot - aces.r) * (1.0 - fRRTRedScale);

  // Go from ACES to RGB rendering space
  if (iACESColorSpace == 0)
  {
    aces = clamp(aces, 0.0, HALF_MAX);
    aces = AP0toAP1(aces);
  }

  aces = clamp(aces, 0.0, HALF_MAX);

  // Global desaturation
  aces = lerp(dot(aces, LUM_AP1), aces, fRRTSatFactor);

  // Apply tonescale for each channel
  aces = float3(
    applySegmentedSplineC5(aces.r),
    applySegmentedSplineC5(aces.g),
    applySegmentedSplineC5(aces.b)
  );

  // Go from RGB to OCES and return
  float3 oces = aces;
  if (iACESColorSpace == 0)
    oces = AP1toAP0(aces);

  return oces;
}

/* ----------------------------------- ODT ---------------------------------- */

// ANCHOR | OCES > sRGB' | D60 > D65
float3 applyPartialODT(float3 oces)
{
  if (iACESColorSpace == 0)
    oces = AP0toAP1(oces);
  
  // Apply tonescale for each channel
  oces = float3(
    applySegmentedSplineC9(oces.r),
    applySegmentedSplineC9(oces.g),
    applySegmentedSplineC9(oces.b)
  );

  // Scale luminance to a linear code value
  oces = float3(
    YtoLinear(oces.r, fODTCinemaBlack, fODTCinemaWhite),
    YtoLinear(oces.g, fODTCinemaBlack, fODTCinemaWhite),
    YtoLinear(oces.b, fODTCinemaBlack, fODTCinemaWhite)
  );

  // Compensate for a dimmer surround
  oces = applyDimmerSurround(oces);

  // Global desaturation to compensate for luminance differences
  oces = lerp(dot(oces, LUM_AP1), oces, fODTSatFactor);

  // Go back to sRGB' and return
  oces = AP1tosRGBl(oces);
  return saturate(oces);
}

#endif D4SCO_ACES
