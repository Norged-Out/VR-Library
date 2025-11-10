Shader "Null's Shader/Vertex/LookatCamera/Opaque" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "black" {}
		[MaterialToggle] _XRotaion ("X Rotation", Float ) = 1
		[MaterialToggle] _HorizontalInverse ("Horizontal Inverse", Float ) = 0
	}
	SubShader {
		Tags { "IgnoreProjector" = "True" "DisableBatching" = "True" }
		Pass {
			Cull off
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "NS LookatCamera Common.cginc"

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 c = _Color * tex2D(_MainTex, i.uv);
				UNITY_APPLY_FOG(i.fogCoord, c);
				return c;
			}
			ENDCG
		}
	} 
}
