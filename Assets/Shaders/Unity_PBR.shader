Shader "Unlit/Unity_PBR2"
{
	Properties
	{
		_NormalTex ("Normal", 2D) = "bump" {}
		_DiffuseTex ("Diffuse", 2D) = "white" {}
		_SpecularTex ("Specular", 2D) = "white" {}
		_GlossTex ("Gloss", 2D) = "white" {}
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
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fwdbase
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 normal = UnpackNormal(tex2D(_NormalTex, i.uv));
                // float3 normal = float3(0, 0, 1);
				float3 lightDir = normalize(i.tanLightDir);
                
				float3 viewDir = normalize(i.tanViewDir);

				half3 specularColor = tex2D(_SpecularTex, i.uv).rgb;
				half smoothness = tex2D(_GlossTex, i.uv).r;

				half oneMinusReflectivity;
				fixed3 diffuseColor = EnergyConservationBetweenDiffuseAndSpecular_Custom(tex2D(_DiffuseTex, i.uv).rgb, specularColor, oneMinusReflectivity);
				
                float3 H = Unity_SafeNormalize_Custom(lightDir + viewDir);

				half dotNL = saturate(dot(normal, lightDir));
				half dotNH = saturate(dot(normal, H));
				half dotNV = saturate(dot(normal, viewDir));
				half dotLH = saturate(dot(H, lightDir));

				half roughness = 1 - smoothness;
				roughness = roughness * roughness;

				half roughnessSqr = roughness * roughness;

				half d = dotNH * dotNH * (roughnessSqr - 1.h) + 1.00001h;
				half specularTerm = roughnessSqr / (max(0.1h, dotLH*dotLH) * (roughness + 0.5h) * (d * d) * 4);

				// half sq = max(1-4f, roughnessSqr);
				// half specularPower = (2.0 / sq) - 2.0;
				// specularPower = max(specularPower, 1e-4f);
				// half invV = dotLH * dotLH * smoothness + roughness;
				// half invF = dotLH;

				return half4((diffuseColor + specularTerm * specularColor) * _LightColor0 * dotNL, 1);
			}
			ENDCG
		}
	}
}
