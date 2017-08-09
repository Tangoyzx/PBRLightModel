#ifndef CUSTOM_COMMON
#define CUSTOM_COMMON

#include "UnityCG.cginc"
#include "Lighting.cginc"  
#include "AutoLight.cginc"

struct v2f {
    float4 pos : POSITION;
    float2 uv : TEXCOORD0;
    float3 tanLightDir : TEXCOORD1;
    float3 tanViewDir : TEXCOORD2;
};

sampler2D _NormalTex;
sampler2D _SpecularTex;
sampler2D _GlossTex;
sampler2D _DiffuseTex;

v2f vert(appdata_tan v) {
    v2f o;
    TANGENT_SPACE_ROTATION;

    o.tanLightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
    o.tanViewDir = mul(rotation, ObjSpaceViewDir(v.vertex));
    o.uv = v.texcoord;
    o.pos = UnityObjectToClipPos(v.vertex);

    return o;
}

inline half SpecularStrength_Custom(half3 specular) {
    return specular.r;
}

inline half3 EnergyConservationBetweenDiffuseAndSpecular_Custom (half3 albedo, half3 specColor, out half oneMinusReflectivity)
{
    oneMinusReflectivity = 1 - SpecularStrength_Custom(specColor);
    return albedo * (half3(1,1,1) - specColor);
}

inline half3 Unity_SafeNormalize_Custom(half3 inVec)
{
    half dp3 = max(0.001f, dot(inVec, inVec));
    return inVec * rsqrt(dp3);
}

#endif // CUSTOM_COMMON