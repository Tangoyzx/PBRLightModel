Shader "Unlit/PBR1"
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

			
			inline float g1_cal(float someDot, float k) {
				return someDot / (someDot * (1 - k) + k);
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 normal = UnpackNormal(tex2D(_NormalTex, i.uv));
				float3 lightDir = normalize(i.tanLightDir);
				float3 viewDir = normalize(i.tanViewDir);

				fixed3 diffuseColor = tex2D(_DiffuseTex, i.uv).rgb;
                fixed3 specularColor = tex2D(_SpecularTex, i.uv).rgb;
				float gloss = tex2D(_GlossTex, i.uv).r;
				float roughneses = 1 - gloss;
				// float roughneses = gloss;

				float3 H = normalize(lightDir + viewDir);

				float dotNH = (dot(normal, H));
				float dotNV = (dot(normal, viewDir));
				float dotNL = (dot(normal, lightDir));
				float dotLH = (dot(H, lightDir));

				float a = roughneses * roughneses;
				float a2 = a * a;
				float pi = 3.1415926;

				float d_1 = dotNH * dotNH * (a2 - 1) + 1;
				float d = a2 / (pi * d_1 * d_1);

				float k = (roughneses + 1);
				k = k * k * 0.125;
				float g = g1_cal(saturate(dotNL), k) * g1_cal(saturate(dotNV), k);

				float f_1 = 1 - dotLH;
				f_1 = f_1 * f_1 * f_1 * f_1 * f_1;
				float f = specularColor + (1 - specularColor) * f_1;
                
                float brdf = f * g * d / (4 * dotNL* dotNV);

				float3 light = (brdf * pi + diffuseColor) * _LightColor0 * dotNL;

				return fixed4(light, 1);
			}
			ENDCG
		}
	}
}
