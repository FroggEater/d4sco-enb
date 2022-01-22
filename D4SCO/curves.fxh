/* -------------------------------------------------------------------------- */
/*                                D4SCO CURVES                                */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_CURVES
#define D4SCO_CURVES

/* -------------------------------- Includes -------------------------------- */

#include "D4SCO/helpers.fxh"

/* --------------------------------- Shapers -------------------------------- */

float sigmoidShaper(float x)
{
  float t = max(1.0 - abs(x * 0.5), 0.0);
  float y = 1.0 + sign(x) * (1.0 - t * t);

  return y * 0.5;
}

float cubicBasisShaper(float x, float width, bool simplified = false)
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

#endif
