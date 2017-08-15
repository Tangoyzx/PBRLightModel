Shader "Unlit/IBL_Compare"
{
	Properties
	{
		_NormalTex ("Normal", 2D) = "bump" {}
		_DiffuseTex ("Diffuse", 2D) = "white" {}
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(0, 1)) = 0.5
		_Skybox("Skybox", CUBE) = "" {}
		_LUT("LUT", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		CGINCLUDE
		#include "CustomCommon.cginc"
		ENDCG

		Pass
		{
			Tags {"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert_1
			#pragma fragment frag

			#pragma multi_compile_fwdbase

			samplerCUBE _Skybox;
			sampler2D _LUT;
            fixed4 _Specular;
            float _Gloss;

			struct v2f_1 {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				half4 T2W0 : TEXCOORD1;
				half4 T2W1 : TEXCOORD2;
				half4 T2W2 : TEXCOORD3;
				half3 lightDir : TEXCOROD4;
				half3 viewDir : TEXCOROD5;
			};

			half ComputeCubemapMipFromRoughness( half Roughness, half MipCount )
			{
				// Level starting from 1x1 mip
				half Level = 3 - 1.15 * log2( Roughness );
				return MipCount - 1 - Level;
			}

			half3 EnvBRDF( half3 SpecularColor, half Roughness, half NoV )
			{
				// Importance sampled preintegrated G * F
				float2 AB = tex2D( _LUT, float2( NoV, Roughness )).rg;

				// Anything less than 2% is physically impossible and is instead considered to be shadowing 
				float3 GF = SpecularColor * AB.x + saturate( 50.0 * SpecularColor.g ) * AB.y;
				return GF;
			}

			v2f_1 vert_1(appdata_tan v) {
				v2f_1 o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;

				TANGENT_SPACE_ROTATION;

				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
                half3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
				half3 worldPos = mul(v.vertex, unity_ObjectToWorld);

				o.T2W0 = half4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.T2W1 = half4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.T2W2 = half4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				o.lightDir = WorldSpaceLightDir(v.vertex);
				o.viewDir = WorldSpaceViewDir(v.vertex);

				return o;
			}
			
			fixed4 frag (v2f_1 i) : SV_Target
			{
				half3 normal = UnpackNormal(tex2D(_NormalTex, i.uv));

				half3 worldNormal = normalize(half3(dot(i.T2W0.xyz, normal), dot(i.T2W1.xyz, normal), dot(i.T2W2.xyz, normal)));  
				half3 worldLightDir = normalize(i.lightDir);
				half3 worldViewDir = normalize(i.viewDir);
				half3 worldHalfDir = normalize(worldLightDir + worldViewDir);

				half dotNL = saturate(dot(worldNormal, worldLightDir));
				half dotNV = saturate(dot(worldNormal, worldViewDir));
				half dotLH = saturate(dot(worldLightDir, worldHalfDir));
				half dotNH = saturate(dot(worldNormal, worldHalfDir));
				
				half3 worldReflect = 2 * dotNV * worldNormal - worldViewDir;

				fixed3 diffuseColor = tex2D(_DiffuseTex, i.uv).rgb;
                fixed3 specularColor = _Specular;
				float gloss = _Gloss;
				float roughness = 1 - gloss;

				half m = ComputeCubemapMipFromRoughness(roughness, 9);
				fixed3 giColor = texCUBElod(_Skybox, float4(-worldReflect.x, worldReflect.yz, m)).rgb;
				half3 giBRDF = EnvBRDF(specularColor, roughness, dotNV);

				// return fixed4(texCUBElod(_Skybox, float4(worldReflect, m)).rgb * specularColor, 1);
				// return texCUBElod(_Skybox, float4(worldReflect, 0));

				half roughness2 = roughness * roughness;

				half roughnessSqr = roughness2 * roughness2;

				half d = dotNH * dotNH * (roughnessSqr - 1.h) + 1.00001h;
				half specularTerm = roughnessSqr / (max(0.1h, dotLH*dotLH) * (roughness2 + 0.5h) * (d * d) * 4);

				return half4((diffuseColor + specularTerm * specularColor) * _LightColor0 * dotNL + giColor * giBRDF, 1);

				// return fixed4(giColor * specularColor, 1);
			}
			ENDCG
		}
	}
}
