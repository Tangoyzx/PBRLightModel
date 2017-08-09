Shader "Unlit/Phong"
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

				fixed3 diffuseColor = tex2D(_DiffuseTex, i.uv).rgb;
                fixed3 specularColor = tex2D(_SpecularTex, i.uv).rgb;
				float gloss = tex2D(_GlossTex, i.uv).r;

                float dotNL = dot(lightDir, normal);

                float3 reflectDir = normal * dotNL * 2 - lightDir;
                
                float dotRV = saturate(dot(viewDir, reflectDir));

				return fixed4((specularColor * pow(dotRV, gloss * 64) + diffuseColor * saturate(dotNL)) * _LightColor0, 1);
			}
			ENDCG
		}
	}
}
