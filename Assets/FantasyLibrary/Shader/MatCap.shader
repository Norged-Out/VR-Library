Shader "Unlit/MatcapBlend" {
    Properties{
        _MainTex("Main Texture", 2D) = "white" {}
        _MatCapTex("MatCap Texture", 2D) = "white" {}
        _Blend("Blend", Range(0, 1)) = 0
    }
        SubShader{
            Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase"}
            LOD 100

            Pass {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag

                #include "UnityCG.cginc"

                struct appdata {
                    float4 vertex : POSITION;
                    float2 uv : TEXCOORD0;
                    float3 normal : NORMAL;
                };

                struct v2f {
                    float2 mainUv : TEXCOORD0;
                    float2 matUv : TEXCOORD1;
                    float4 vertex : SV_POSITION;
                };

                sampler2D _MatCapTex;
                sampler2D _MainTex;
                float4 _MainTex_ST;
                fixed _Blend;

                v2f vert(appdata v) {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    // 法線をワールド座標へと変換
                    float3 normal = UnityObjectToWorldNormal(v.normal);
                    // ビュー行列へ変換
                    normal = mul((float3x3)UNITY_MATRIX_V, normal);
                    // 法線(-1~1)をUV(0~1)として扱う
                    o.matUv = normal * 0.5 + 0.5;
                    o.mainUv = TRANSFORM_TEX(v.uv, _MainTex);
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target {
                    fixed4 mainColor = tex2D(_MainTex, i.mainUv);
                    fixed4 matColor = tex2D(_MatCapTex, i.matUv);
                    // メインテクスチャとMatCapを補完する
                    fixed4 col = fixed4(lerp(mainColor, matColor, _Blend));
                    return col;
                }
                ENDCG
            }
        }
}