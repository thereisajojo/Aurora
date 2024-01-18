Shader "Hidden/AuroraPass"
{
    Properties
    {
        /*
        [HDR]_AuroraTopColor("Top Color", Color) = (0.8, 0, 1, 1)
        [HDR]_AuroraBottomColor("Bottom Color", Color) = (0, 1, 0.67, 1)
        _AuroraHeight("Aurora Height", Float) = 0.5
        _AuroraHeightOffset("Aurora Height Offset", Float) = 0.15
        _AuroraDistance("Aurora Distance", Float) = 6
        _AuroraIntensity("Aurora Intensity", Range(0,1)) = 1.0
        _AuroraSpeed("Aurora Speed", Range(0,1)) = 0.5
        _AuroraColFactor("Aurora Color Factor", Range(0,1)) = 0.7
        
        [Toggle(_REFLECT_AURORA)] _Reflection("Reflection", Float) = 0
        */
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Cull Off ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma shader_feature _REFLECT_AURORA

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
            };

            half3 _AuroraTopColor;
            half3 _AuroraBottomColor;
            float _AuroraHeight;
            float _AuroraHeightOffset;
            float _AuroraDistance;
            half _AuroraIntensity;
            half _AuroraColFactor;
            float4 _AuroraSpeed; // x: x-axis, y: z-aixs, z: noise, w: 0

            v2f vert(appdata v)
            {
                v2f o;
                o.positionOS = v.vertex.xyz;
                o.positionCS = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float tri(float x)
            {
                return clamp(abs(frac(x) - 0.5), 0.01, 0.49);
            }

            float2 tri2(float2 p)
            {
                return float2(tri(p.x) + tri(p.y), tri(p.y + tri(p.x)));
            }

            float2x2 RotateMatrix(float a)
            {
                float c = cos(a);
                float s = sin(a);
                return float2x2(c, s, -s, c);
            }

            // 极光噪声
            float SurAuroraNoise(float2 pos)
            {
                float intensity = 1.8;
                float size = 2.5;
                float rz = 0;
                // pos = mul(RotateMatrix(pos.x * 0.06), pos);
                float2 bp = pos;
                for (int i = 0; i < 3; i++)
                {
                    float2 dg = tri2(bp * 1.85) * 0.75;
                    dg = mul(RotateMatrix(_Time.y * _AuroraSpeed.z), dg);
                    pos -= dg / size;

                    bp *= 1.3;
                    size *= 0.45;
                    intensity *= 0.42;
                    pos *= 1.21 + (rz - 1.0) * 0.02;

                    rz += tri(pos.x + tri(pos.y)) * intensity;
                    pos = mul(float2x2(-0.95534, -0.29552, 0.29552, -0.95534), pos);
                }
                return clamp(1 / (rz * 46), 0, 0.55);
                // return clamp(1.0 / pow(rz * 29.0, 1.3), 0, 0.55);
            }

            #define LayerCount 30
            #define InvLayer 0.033333333f // 1 ÷ 30
            half4 frag(v2f input) : SV_Target
            {
                input.positionOS *= 2; // -0.5 ~ 0.5 => -1 ~ 1

            #if !defined(_REFLECT_AURORA)
                if (input.positionOS.y > 0)
            #endif
                {
                    half4 aurora = half4(0, 0, 0, 0);
                    half4 avgCol = half4(0, 0, 0, 0);
                    float auroraDis = _AuroraDistance * 0.001;
                    float2 skyuv = input.positionOS.xz / (abs(input.positionOS.y) + _AuroraHeightOffset);

                    for (int i = 0; i < LayerCount; i++)
                    {
                        float2 noiseuv = skyuv * (_AuroraHeight + i * auroraDis);
                        noiseuv += _Time.x * _AuroraSpeed.xy * 5;
                        half noise = SurAuroraNoise(noiseuv);
                        half4 col2 = half4(0, 0, 0, noise);
                        // col2.rgb = (sin(half3(-1.15, 1.5, -0.2) + i * _AuroraColFactor * 0.1) * 0.8 + 0.5) * noise;
                        col2.rgb = lerp(_AuroraBottomColor, _AuroraTopColor, InvLayer * i + _AuroraColFactor) * noise;
                        avgCol = lerp(avgCol, col2, half(0.5));
                        aurora += avgCol * exp2(-i * 0.065 - 2.5) * smoothstep(0.0, 5.0, i);
                    }

                    aurora *= 1.8;
                    aurora = smoothstep(half(0), half(1.5), aurora);
                    aurora.a *= _AuroraIntensity;
                    return aurora;
                }

                return half4(0, 0, 0, 0);
            }
            ENDCG
        }
    }
}
