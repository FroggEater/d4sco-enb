/* -------------------------------------------------------------------------- */
/*                                D4SCO CURVES                                */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_CURVES
#define D4SCO_CURVES

/* -------------------------------- Includes -------------------------------- */

#include "D4SCO/helpers.fxh"

/* -------------------------------- Constants ------------------------------- */

static const float ACES_MIN = pow(2.0, -14.0);
static const float OCES_MIN = 1e-4;

static const float3x3 SPLINE_MAT = float3x3(
  0.5, -1.0, 0.5,
  -1.0, 1.0, 0.5,
  0.5, 0.0, 0.0
);

/* --------------------------------- Shapers -------------------------------- */

float sigmoidShaper(float x)
{
  float t = max(1.0 - abs(x * 0.5), 0.0);
  float y = 1.0 + sign(x) * (1.0 - t * t);

  return y * 0.5;
}

float cubicBasisShaper(float x, float width, bool simplified = true)
{
  if (simplified)
    return sq(smoothstep(0.0, 1.0, 1.0 - abs(2.0 * x / width)));

  static const float4x4 mat = float4x4(
    -1.0 / 6.0, 3.0 / 6.0, -3.0 / 6.0, 1.0 / 6.0,
    3.0 / 6.0, -6.0 / 6.0, 3.0 / 6.0, 0.0 / 6.0,
    -3.0 / 6.0, 0.0 / 6.0, 3.0 / 6.0, 0.0 / 6.0,
    1.0 / 6.0, 4.0 / 6.0, 1.0 / 6.0, 0.0 / 6.0
  );

  float knots[5] =
    {-0.5 * width, -0.25 * width, 0.0, 0.25 * width, 0.5 * width};

  float y = 0.0;
  if ((x > knots[0]) && (x < knots[4]))
  {
    float coord = (x - knots[0]) * 4.0 / width;
    int j = coord;
    float t = coord - j;

    float monomials[4] = {t * t * t, t * t, t, 1.0};

    if ((j >= 0) && (j <= 3))
    {
      y = monomials[0] * mat[0][3 - j] +
        monomials[1] * mat[1][3 - j] +
        monomials[2] * mat[2][3 - j] +
        monomials[3] * mat[3][3 - j];
    }
  }

  return y * 1.5;
}

/* --------------------------------- Curves --------------------------------- */

struct SegmentedSplineC5Params
{
  float coefsLow[6];
  float coefsHigh[6];

  float2 minPoint;
  float2 midPoint;
  float2 maxPoint;

  float slopeLow;
  float slopeHigh;
};

struct SegmentedSplineC9Params
{
  float coefsLow[10];
  float coefsHigh[10];

  float2 minPoint;
  float2 midPoint;
  float2 maxPoint;

  float slopeLow;
  float slopeHigh;
};

float applySegmentedSplineC5(float x, SegmentedSplineC5Params p)
{
  static const int KNOTS_LOW = 4;
  static const int KNOTS_HIGH = 4;

  x = x <= 0 ? ACES_MIN : x;
  float logx = log10(x);
  float logy;

  if (logx <= log10(p.minPoint.x))
    logy = logx * p.slopeLow + (log10(p.minPoint.y) - p.slopeLow * log10(p.minPoint.x));
  else if ((logx > log10(p.minPoint.x)) && (logx < log10(p.midPoint.x)))
  {
    float coord =
      (KNOTS_LOW - 1) * (logx - log10(p.minPoint.x)) / (log10(p.midPoint.x) - log10(p.minPoint.x));
    int j = coord;
    float t = coord - j;

    float3 coefs = {p.coefsLow[j], p.coefsLow[j + 1], p.coefsLow[j + 2]};
    float3 monomials = {t * t, t, 1.0};

    logy = dot(monomials, mul(coefs, SPLINE_MAT));
  }
  else if ((logx >= log10(p.midPoint.x)) && (logx < log10(p.maxPoint.x)))
  {
    float coord =
      (KNOTS_HIGH - 1) * (logx - log10(p.midPoint.x)) / (log10(p.maxPoint.x) - log10(p.midPoint.x));
    int j = coord;
    float t = coord - j;

    float3 coefs = {p.coefsHigh[j], p.coefsHigh[j + 1], p.coefsHigh[j + 2]};
    float3 monomials = {t * t, t, 1.0};

    logy = dot(monomials, mul(coefs, SPLINE_MAT));
  }
  else
    logy = logx * p.slopeHigh + (log10(p.maxPoint.y) - p.slopeHigh * log10(p.maxPoint.x));

  return pow(10.0, logy);
}

float applySegmentedSplineC9(float x, SegmentedSplineC9Params p)
{
  static const int KNOTS_LOW = 8;
  static const int KNOTS_HIGH = 8;

  x = x <= 0 ? OCES_MIN : x;
  float logx = log10(x);
  float logy;

  if (logx <= log10(p.minPoint.x))
    logy = logx * p.slopeLow + (log10(p.minPoint.y) - p.slopeLow * log10(p.minPoint.x));
  else if ((logx > log10(p.minPoint.x)) && (logx < log10(p.midPoint.x)))
  {
    float coord =
      (KNOTS_LOW - 1) * (logx - log10(p.minPoint.x)) / (log10(p.midPoint.x) - log10(p.minPoint.x));
    int j = coord;
    float t = coord - j;

    float3 coefs = {p.coefsLow[j], p.coefsLow[j + 1], p.coefsLow[j + 2]};
    float3 monomials = {t * t, t, 1.0};

    logy = dot(monomials, mul(coefs, SPLINE_MAT));
  }
  else if ((logx >= log10(p.midPoint.x)) && (logx < log10(p.maxPoint.x)))
  {
    float coord =
      (KNOTS_HIGH - 1) * (logx - log10(p.midPoint.x)) / (log10(p.maxPoint.x) - log10(p.midPoint.x));
    int j = coord;
    float t = coord - j;

    float3 coefs = {p.coefsHigh[j], p.coefsHigh[j + 1], p.coefsHigh[j + 2]};
    float3 monomials = {t * t, t, 1.0};

    logy = dot(monomials, mul(coefs, SPLINE_MAT));
  }
  else
    logy = logx * p.slopeHigh + (log10(p.maxPoint.y) - p.slopeHigh * log10(p.maxPoint.x));

  return pow(10.0, logy);
}

#endif
