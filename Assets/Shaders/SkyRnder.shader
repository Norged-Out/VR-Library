// sky renderer using volumn rendering
Shader "Custom/SkyRnder"
{
    Properties
    {
        _SunlightColor("Sunlight Color", Color) = (1,1,1,1)
        _G("Mie Anisotropy", Range(0,1)) = 0.76
        _SunColor("Sun Color", Color) = (0.8, 0.8, 0.8, 1)
        _SunSize("Sun Size", float) = 0.0093
        _Density("Density", float) = 1
        _StarTex ("Star Texture", Cube) = "white" {}
        _ScatterStrength("Scatter Strength", float) = 0.00001
        _LengthFactor("Length Factor", float) = 1.1
        _MieBoost("Mie Boost", float) = 4
        _Thickness("Thisckness of Atmosphere", float) = 80000.0
        _LowCloudBound("Low Cloud Bound", float) = 2000.0
        _HighCloudBound("High Cloud Bound", float) = 10000.0
        _CloudAbsorption("Cloud Absorption", float) = 0.00001

            // ---- 云噪声（主形状） ----
    _DensityNoiseTex("Cloud Shape Noise (fbm/perlin)", 3D) = "white" {}
    _DensityNoise_Scale("Density Noise Scale", Vector) = (0.001, 0.001, 0.001, 0)
    _DensityNoise_Offset("Density Noise Offset", Vector) = (0,0,0,0)

    // ---- 云噪声（侵蚀） ----
    _DensityErodeTex("Cloud Erode Noise (Worley/fbm)", 3D) = "white" {}
    _DensityErode_Scale("Erode Noise Scale", Vector) = (0.001, 0.001, 0.001, 0)
    _DensityErode_Offset("Erode Noise Offset", Vector) = (0,0,0,0)

    // ---- 噪声控制 ----
    _ErodeScale("Erode Strength", Range(0,1)) = 0.5
    _DensityScale("Cloud Density Strength", Float) = 1.0
        
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Opaque"}

        pass{
            ZWrite Off
            ZTest Always
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _SunlightColor;
            float _G;
            float3 _SunDir;
            float _SunIntensity;
            float4 _SunColor;
            float _SunSize;
            float _Density;
            samplerCUBE _StarTex;
            float _ScatterStrength;
            float _LengthFactor;
            float _MieBoost;
            float _Thickness;
            float _LowCloudBound;
            float _HighCloudBound;
            float _CloudAbsorption;

            // 云噪声
sampler3D _DensityNoiseTex;
float3 _DensityNoise_Scale;
float3 _DensityNoise_Offset;

sampler3D _DensityErodeTex;
float3 _DensityErode_Scale;
float3 _DensityErode_Offset;

// 控制参数
float _ErodeScale;
float _DensityScale;


            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 dir : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.dir = normalize(UnityObjectToWorldDir(v.vertex.xyz));
                return o;
            }

            float3 WorldToTexCoord(float3 worldPos)
            {
                return worldPos / (_Thickness * 1.1);
            }

            // 单瓣 HG
            float HGPhase(float cosTheta, float g)
            {
                float denom = 1.0 + g*g - 2.0*g*cosTheta;
                return (1.0 - g*g) / (4.0 * UNITY_PI * pow(max(denom, 1e-3), 1.5));
            }

            // 双瓣 HG
            float DHGPhase(float cosTheta, float g0, float g1, float f)
            {
                float p0 = HGPhase(cosTheta, g0); // 前向
                float p1 = HGPhase(cosTheta, g1); // 后向
                return lerp(p0, p1, f);
            }

            float sampleDensity(float3 position)
            {
                // 主噪声
                float3 uvw = position;
                float density = tex3D(_DensityNoiseTex, uvw).r;

                // 侵蚀噪声
                float3 erodeUVW = position;
                float erode = tex3D(_DensityErodeTex, erodeUVW).r * _ErodeScale;

                // 边缘腐蚀 + 浓度缩放
                density = max(0, density - erode) * _DensityScale;

                return density;
            }

            float3 lightPathDensity(float3 position, float3 sunDir, int stepCount, float3 beta)
            {   
                if(sunDir.y < 0.001)
                    return 0;

                float distanceLow  = max(0, (_LowCloudBound  - position.y) / sunDir.y);
                float distanceHigh = max(0, (_HighCloudBound - position.y) / sunDir.y);
                float distance     = distanceHigh - distanceLow;
                float stepSize     = distance / stepCount;

                float density = 0;

                for(int s = 0; s < stepCount; s++)
                {
                    float3 samplePos = (position + sunDir * s * stepSize) / (_Thickness * 2) + 0.5;

                    // 调用统一的密度函数
                    float cloudDensity = sampleDensity(samplePos);

                    density += cloudDensity * (beta + _CloudAbsorption) * stepSize;
                }

                return exp(-density);
            }

            float4 frag(v2f i) : SV_TARGET
            {
                // atmosphere parameters
                float3 betaR = float3(5.8e-6, 1.35e-5, 3.1e-5); // Rayleigh scattering coefficient
                float3 betaM = float3(2e-6, 2e-6, 2e-6);        // Mie scattering coefficient

                float3 viewDir = normalize(i.dir);
                float3 sunDir  = normalize(_SunDir);

                float cosTheta = dot(viewDir, sunDir);
                float theta = acos(cosTheta);


                // 常用参数（可调）
                float g0 = 0.85;   // 强前向散射
                float g1 = -0.2;   // 弱后向散射
                float f  = 0.3;    // 混合比例

                float miePhase = DHGPhase(cosTheta, g0, g1, f);

                // phase functions
                float rayleighPhase = 3.0 / (16.0 * UNITY_PI) * (1 + cosTheta * cosTheta);
                //float miePhase =  _MieBoost * (1 - _G * _G) / (4.0 * UNITY_PI * pow(1 + _G * _G - 2 * _G * cosTheta, 1.5));

                // the parameters will be used in the path integral
                static const float atmosphereHeight = _Thickness; // the height of atmosphere, which is 80 km
                int steps = 24;                                // steps
                float stepSize = atmosphereHeight / steps;

                // the paramter will be used in cloud path integral
                bool flag = true;
                if(viewDir.y < 0.001) flag = false;
                float distanceLow = max(0,_LowCloudBound / viewDir.y);
                float distanceHigh = max(0, _HighCloudBound / viewDir.y);
                float distance = distanceHigh - distanceLow;
                float CloudStepSize = distance / steps;

                float3 scattering = 0;
                float3 transmittance = 1;
                float3 transmittanceC = 1;

                // the decay of sunlight during the way to earth. to collect the light below the land, a little disterb
                // is added to the dir of the sun. because the light gradient is indistinctable around withe light.
                // this action is eligible
                float muS = saturate(dot(normalize(sunDir + float3(0, 0.3, 0)), float3(0, 1, 0)));
                float thetaDeg = acos(muS) * (180.0 / UNITY_PI);
                float airMassS = 1.0 / (muS + 0.50572 * pow(96.07995 - thetaDeg, -1.6364));
                float3 extinctionS = exp(-(betaR + betaM) * airMassS * _Density);

                float dC = 0;
                for (int s = 0; s < steps; s++)
                {
                    float t = (s + 0.5) * stepSize;   // half-way sapling is better than original step length
                    float3 samplePos = viewDir * t;

                    // exponential rule for height -> density
                    float height = max(0, samplePos.y);
                    float localDensityR = exp(-height / 8000.0) * _Density;
                    float localDensityM = exp(-height / 1200.0) * _Density;

                    
                    // discrete integral of the scattering light
                    float horizonFade = pow(saturate((muS+0.1)/0.5), 3.0);
                    float3 dL = (localDensityR * betaR * rayleighPhase + localDensityM * betaM * miePhase)
                                * extinctionS * transmittance * stepSize * horizonFade;

                    //could
                    if(flag){
                    float3 CloudSamplePos = viewDir * (distanceLow + s*CloudStepSize);
                    float cloudDensity = sampleDensity(CloudSamplePos / (_Thickness * 2)+ 0.5);
                    float horizonFade = pow(saturate(viewDir.y * 2.5), 2.0);
                    cloudDensity *= horizonFade;
                    float3 lightIntensity = lightPathDensity(CloudSamplePos, sunDir, 16, betaM);
                    float3 singleScattering = cloudDensity * betaM *  miePhase * lightIntensity * CloudStepSize * extinctionS * transmittanceC;
                    float3 ambient = float3(0.006, 0.007, 0.009);
                    float3 multiScattering = ambient * (1 - exp(-cloudDensity * _ScatterStrength)) * CloudStepSize * transmittanceC;
                    
                    dC = singleScattering + multiScattering;
                    transmittanceC *= exp(-(cloudDensity * (betaM + _CloudAbsorption) * CloudStepSize));
                    }
                    

                    scattering += dL + dC;

                    // beforing moving to the next cell, its light decay shoud be recoreded
                    transmittance *= exp(-(localDensityR * betaR + localDensityM * betaM) * stepSize);
                    
                }

                // sun disk
                float sunDisk = exp(-pow(theta / _SunSize, 3));
                float3 sunCol = extinctionS * sunDisk * _SunlightColor;

                //blend the color of the sun and light
                float3 color = scattering * _SunlightColor.xyz;
                float sunHeight = sunDir.y; // the height of sun
                float dayFactor = saturate(exp(sunHeight * 5.0) - 0.5); //the higher, the brighter
                float3 nightCol = float3(0.003, 0.006, 0.015);

                float3 star = sqrt(1 - dayFactor + 0.02) * texCUBE(_StarTex, i.dir);

                color = lerp(nightCol, color, dayFactor) + sunCol + saturate(pow(star, 2));
                return float4(color, 1);
            }
            ENDCG
        }
        
    }
    FallBack "Diffuse"
}
