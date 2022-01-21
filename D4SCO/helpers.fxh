/* -------------------------------------------------------------------------- */
/*                                D4SCO HELPERS                               */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_HELPERS
#define D4SCO_HELPERS

/* -------------------------------- Samplers -------------------------------- */

SamplerState PointSampler
{
  Filter = MIN_MAG_MIP_POINT;
  AddressU = Clamp;
  AddressV = Clamp;
};

SamplerState LinearSampler
{
  Filter = MIN_MAG_MIP_LINEAR;
  AddressU = Clamp;
  AddressV = Clamp;
};

/* -------------------------------- Utilities ------------------------------- */

// Returns the smallest element of a given vector
float min2(float2 v) { return min(v.x, v.y); }
float min3(float3 v) { return min(min2(v.xy), v.z); }
float min4(float4 v) { return min(min3(v.xyz), v.w); }

// Returns true if all the elements of the given vector are out of the given bounds
bool ext(float v, float mi, float ma) { return (v < mi || v > ma); }
bool ext2(float2 v, float mi, float ma) { return ext(v.x, mi, ma) && ext(v.y, mi, ma); }
bool ext3(float3 v, float mi, float ma) { return ext2(v.xy, mi, ma) && ext(v.z, mi, ma); }
bool ext4(float4 v, float mi, float ma) { return ext3(v.xyz, mi, ma) && ext(v.w, mi, ma); }

/* ------------------------------- Techniques ------------------------------- */

void VS_Basic(inout float4 pos : SV_POSITION, inout float4 txcoord : TEXCOORD0) { pos.w = 1.0; }
float4 PS_Blank(float4 pos : SV_POSITION, float4 txcoord : TEXCOORD0) : SV_TARGET { return 0.0; }

#endif
