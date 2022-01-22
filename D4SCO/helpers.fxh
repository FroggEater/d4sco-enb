/* -------------------------------------------------------------------------- */
/*                                D4SCO HELPERS                               */
/* -------------------------------------------------------------------------- */
/* ------------------------------ By FroggEater ----------------------------- */
/* -------------------------------------------------------------------------- */

#ifndef D4SCO_HELPERS
#define D4SCO_HELPERS

/* -------------------------------- Constants ------------------------------- */

static const float PI = 3.1415926535897932384626433832795;

static const float HALF_MAX = 65535.0;
// static const float HALF_MIN = exp2(-14.0);

static const float D10 = 1e-10;
static const float D9 = 1e-9;
static const float D8 = 1e-8;
static const float D7 = 1e-7;
static const float D6 = 1e-6;
static const float D5 = 1e-5;
static const float D4 = 1e-4;
static const float D3 = 1e-3;
static const float D2 = 1e-2;
static const float D1 = 1e-1;

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

// Returns the biggest element of a given vector
float max2(float2 v) { return max(v.x, v.y); }
float max3(float3 v) { return max(max2(v.xy), v.z); }
float max4(float4 v) { return max(max3(v.xyz), v.w); }

// Returns the sum of all the elements of a given vector
float sum2(float2 v) { return sum(v.x, v.y); }
float sum3(float3 v) { return sum(sum2(v.xy), v.z); }
float sum4(float4 v) { return sum(sum3(v.xyz), v.w); }

// Returns the substraction of all the elements in order of the given vector
float sub2(float2 v) { return v.x - v.y; }
float sub3(float3 v) { return sub2(v.xy) - v.z; }
float sub4(float4 v) { return sub3(v.xyz) - v.w; }

// Returns the given input to the power of 2, 3 or 4
float sq(float x) { return x * x; }
float cb(float x) { return x * x * x; }
float qd(float x) { return x * x * x * x; }

// Returns true if all the elements of the given vector are out of the given bounds
bool ext(float x, float mi, float ma) { return (x < mi || x > ma); }
bool ext2(float2 v, float mi, float ma) { return ext(v.x, mi, ma) && ext(v.y, mi, ma); }
bool ext3(float3 v, float mi, float ma) { return ext2(v.xy, mi, ma) && ext(v.z, mi, ma); }
bool ext4(float4 v, float mi, float ma) { return ext3(v.xyz, mi, ma) && ext(v.w, mi, ma); }

// Reurns true if all the elements of the given vector are equal
bool same2(float2 v) { return v.x == v.y; }
bool same3(float3 v) { return (v.x == v.y) && (v.y == v.z); }
bool same4(float4 v) { return (v.x == v.y) && (v.y == v.z) && (v.z == v.w); }

/* ------------------------------- Techniques ------------------------------- */

void VS_Basic(inout float4 pos : SV_POSITION, inout float4 txcoord : TEXCOORD0) { pos.w = 1.0; }
float4 PS_Blank(float4 pos : SV_POSITION, float4 txcoord : TEXCOORD0) : SV_TARGET { return 0.0; }

#endif
