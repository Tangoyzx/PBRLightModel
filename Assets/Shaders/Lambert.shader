Shader "Unlit/Lambert"
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
				float3 lightDir = normalize(i.tanLightDir);
				float3 viewDir = normalize(i.tanViewDir);

				fixed4 diffuseColor = tex2D(_DiffuseTex, i.uv);
				float dotNL = saturate(dot(lightDir, normal));
				return diffuseColor * (dotNL * 0.5 + 0.5) * _LightColor0;
			}
			ENDCG
		}
	}
}
