/* -------------------------------------------------------------------------- */
/*                              D4SCO COLORSPACES                             */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_COLORSPACES
#define D4SCO_COLORSPACES

/* -------------------------------- Includes -------------------------------- */

#include "D4SCO/helpers.fxh"

/* -------------------------------- Constants ------------------------------- */

static const float3 LUM_AP1 = float3(0.272228716780915, 0.674081765811148, 0.053689517407937);
static const float3 LUM_709 = float3(0.212639005871510, 0.715168678767756, 0.072192315360734);
static const float3 MID_SRGB = float3(0.5, 0.5, 0.5);

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

// ANCHOR | sRGB' <> XYZ | Rec. 709 | D65
float3 sRGBltoXYZ(float3 color)
{
  static const float3x3 mat = float3x3(
    0.412390799265959, 0.357584339383878, 0.180480788401834,
    0.212639005871510, 0.715168678767756, 0.072192315360734,
    0.019330818715592, 0.119194779794626, 0.950532152249661
  );
  return mul(mat, color);
}
float3 XYZtosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    3.240969941904523, -1.537383177570094, -0.498610760293003,
    -0.969243636280880, 1.875967501507721, 0.041555057407176,
    0.055630079696994, -0.203976958888977, 1.056971514242879
  );
  return mul(mat, color);
}

/* ----------------------------- CIE Transforms ----------------------------- */

// ANCHOR | XYZ <> xyY
float3 XYZtoxyY(float3 color)
{
  float divider = sum3(color);
  if (divider == 0.0) divider = D10;
  return float3(
    color.x / divider,
    color.y / divider,
    color.y
  );
}
float3 xyYtoXYZ(float3 color)
{
  return float3(
    color.x * color.z / max(color.y, D10),
    color.z,
    (1.0 - color.x - color.y) * color.z / max(color.y, D10)
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

// ANCHOR | ACES2065-1 <> sRGB' | AP0 <> Rec. 709 | D60 <> D65 (Bradford)
float3 AP0tosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    2.521400888578221, -1.133995749382747, -0.387561856768867,
    -0.276214061561748, 1.372595566304089, -0.096282355736466,
    -0.015320200077479, -0.152992561800699, 1.168387199619315
  );
  return mul(mat, color);
}
float3 sRGBltoAP0(float3 color)
{
  static const float3x3 mat = float3x3(
    0.439643004019961, 0.383005471371792, 0.177399308886895,
    0.089715731865361, 0.813475053791709, 0.096782252404812,
    0.017512720476296, 0.111551438549134, 0.870882792975248
  );
  return mul(mat, color);
}

// ANCHOR | ACEScg <> sRGB' | AP1 <> Rec. 709 | D60 <> D65 (Bradford)
float3 AP1tosRGBl(float3 color)
{
  static const float3x3 mat = float3x3(
    1.704858676289160, -0.621716021885330, -0.083299371729057,
    -0.130076824208823, 1.140735774822504, -0.010559801677511,
    -0.023964072927574, -0.128975508299318, 1.153014018916862
  );
  return mul(mat, color);
}
float3 sRGBltoAP1(float3 color)
{
  static const float3x3 mat = float3x3(
    0.613132422390542, 0.339538015799666, 0.047416696048269,
    0.070124380833917, 0.916394011313573, 0.013451523958235,
    0.020587657528185, 0.109574571610682, 0.869785404035327
  );
  return mul(mat, color);
}

// ANCHOR | ACES2065-1 <> XYZ | AP0 | D60
float3 AP0toXYZ(float3 color)
{
  static const float3x3 mat = float3x3(
    0.952552395900000, 0.000000000000000, 0.000093678600000,
    0.343966449800000, 0.728166096600000, -0.072132546400000,
    0.000000000000000, 0.000000000000000, 1.008825184400000
  );
  return mul(mat, color);
}
float3 XYZtoAP0(float3 color)
{
  static const float3x3 mat = float3x3(
    1.049811017500000, 0.000000000000000, -0.000097484500000,
    -0.495903023100000, 1.373313045800000, 0.098240036100000,
    0.000000000000000, 0.000000000000000, 0.991252018200000
  );
  return mul(mat, color);
}

// ANCHOR | ACEScg <> XYZ | AP1 | D60
float3 AP1toXYZ(float3 color)
{
  static const float3x3 mat = float3x3(
    0.662454181108506, 0.134004206456433, 0.156187687004908,
    0.272228716780915, 0.674081765811148, 0.053689517407937,
    -0.005574649490394, 0.004060733528983, 1.010339100312997
  );
  return mul(mat, color);
}
float3 XYZtoAP1(float3 color)
{
  static const float3x3 mat = float3x3(
    1.641023379694325, -0.324803294184790, -0.236424695237612,
    -0.663662858722983, 1.615331591657338, 0.016756347685530,
    0.011721894328375, -0.008284441996237, 0.988394858539022
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
