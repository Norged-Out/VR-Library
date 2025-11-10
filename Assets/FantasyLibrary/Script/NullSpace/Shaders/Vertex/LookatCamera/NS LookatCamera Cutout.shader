Shader "Null's Shader/Vertex/LookatCamera/Cutout" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "black" {}
		[MaterialToggle] _XRotaion ("X Rotation", Float ) = 1
		[MaterialToggle] _HorizontalInverse ("Horizontal Inverse", Float ) = 0
		_ClipAlpha ("Clip Alpha", Range(0.0,1.0)) = .5
	}
	SubShader {
		Tags { "RenderType" = "TransparentCutout" "Queue" = "AlphaTest" "IgnoreProjector" = "True" "DisableBatching" = "True" }
		Pass {
			Cull off
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "NS LookatCamera Common.cginc"

			fixed _ClipAlpha;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 c = _Color * tex2D(_MainTex, i.uv);
				clip(c.a - _ClipAlpha);
				UNITY_APPLY_FOG(i.fogCoord, c);
				return c;
			}ENDCG
		}
	} 
}
