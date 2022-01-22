/* -------------------------------------------------------------------------- */
/*                              D4SCO COLORSPACES                             */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_COLORSPACES
#define D4SCO_COLORSPACES

/* ---------------------------- Common Transforms --------------------------- */

// ANCHOR | sRGB <> sRGB' | Rec. 709 | D65
float3 sRGBtosRGBl(float3 color)
{
  static const float a = 0.055;
  static const float b = 0.0404482362771082;
  return float3(
    color.r <= b ? color.r / 12.92 : pow((color.r + a) / (1.0 + a), 2.4),
    color.g <= b ? color.g / 12.92 : pow((color.g + a) / (1.0 + a), 2.4),
    color.b <= b ? color.b / 12.92 : pow((color.b + a) / (1.0 + a), 2.4)
  );
}
float3 sRGBltosRGB(float3 color)
{
  static const float a = 0.055;
  static const float b = 0.00313066844250063;
  return float3(
    color.r <= b ? color.r * 12.92 : (1.0 + a) * pow(color.r, 1.0 / 2.4) - a,
    color.g <= b ? color.g * 12.92 : (1.0 + a) * pow(color.g, 1.0 / 2.4) - a,
    color.b <= b ? color.b * 12.92 : (1.0 + a) * pow(color.b, 1.0 / 2.4) - a
  );
}

/* ----------------------------- ACES Transforms ---------------------------- */

// ANCHOR | ACES2065-1 <> ACEScg | AP0 <> AP1 | D60
float3 AP0toAP1(float3 color)
{
  static const float3x3 mat = float3x3(
    1.451439316071658, -0.236510746889360, -0.214928569308364,
    -0.076553773314263, 1.176229699811789, -0.099675926450360,
    0.008316148424961, -0.006032449790909, 0.997716301412982
  );
  return mul(mat, color);
}
float3 AP1toAP0(float3 color)
{
  static const float3x3 mat = float3x3(
    0.695452241358567, 0.140678696470730, 0.163869062213569,
    0.044794563352499, 0.859671118442968, 0.095534318210286,
    -0.005525882558111, 0.004025210305977, 1.001500672251631
  );
  return mul(mat, color);
}

/* ------------------ Chromatic Adaptation Transforms (CAT) ----------------- */

// ANCHOR | XYZ | Bradford | D65 <> D60
float3 D65toD60(float3 color)
{
  static const float3x3 mat = float3x3(
    1.01303, 0.00610531, -0.014971,
    0.00769823, 0.998165, -0.00503203,
    -0.00284131, 0.00468516, 0.924507
  );
  return mul(mat, color);
}
float3 D60toD65(float3 color)
{
  static const float3x3 mat = float3x3(
    0.987224, -0.00611327, 0.0159533,
	  -0.00759836, 1.00186, 0.00533002,
	  0.00307257, -0.00509595, 1.08168
  );
  return mul(mat, color);
}

#endif
