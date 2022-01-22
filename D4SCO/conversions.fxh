/* -------------------------------------------------------------------------- */
/*                              D4SCO CONVERSIONS                             */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_CONVERSIONS
#define D4SCO_CONVERSIONS

/* -------------------------------- Includes -------------------------------- */

#include "D4SCO/helpers.fxh"

/* ------------------------------- Conversions ------------------------------ */

// ANCHOR | RGB > ?
float RGBtoSaturation(float3 color)
{
  return (max(max3(color), D10) - max(min3(color), D10)) / max(max3(color), D2);
}
// Converts RGB to a luminance proxy YC ~ Y + K * chroma
float RGBtoYc(float3 color, float radiusWeight = 1.75)
{
  float chroma = sqrt(color.b * sub2(color.bg) + color.g * sub2(color.gr) + color.r * sub2(color.rb));
  return (sum3(color) + radiusWeight * chroma) / 3.0;
}
float RGBtoHue(float3 color)
{
  float hue;
  if (same3(color))
    hue = 0.0; // was NAN in original CTL code, no idea how it goes in HLSL
  else
    hue = (180.0 / PI) * atan2(sqrt(3.0) * (color.g - color.b), 2.0 * color.r - sum2(color.gb));

  if (hue < 0.0) hue += 360.0;
  return clamp(hue, 0.0, 360.0);
}

// ANCHOR | Others
float YtoLinear(float y, float mi, float ma)
{
  return (y - mi) / (ma - mi);
}

/* -------------------------------- Utilities ------------------------------- */

float centerHue(float hue, float center)
{
  float centeredHue = hue - center;
  if (centeredHue < -180.0) centeredHue += 360.0;
  else if (centeredHue > 180.0) centeredHue -= 360.0;

  return centeredHue;
}

#endif
