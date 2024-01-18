Shader "Hidden/noise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _AuroraHeight("Aurora Height", Float) = 0.5
        _AuroraHeightOffset("Aurora Height Offset", Float) = 0.15
        _AuroraDistance("Aurora Distance", Float) = 6
        _AuroraIntensity("Aurora Intensity", Range(0,1)) = 1.0
        _AuroraSpeed("Aurora Speed", Vector) = (0, 0, 0.5, 0)
        _AuroraColFactor("Aurora Color Factor", Range(0,1)) = 0.7
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float _AuroraHeight;
            float _AuroraHeightOffset;
            float _AuroraDistance;
            float _AuroraIntensity;
            float3 _AuroraSpeed;
            float _AuroraColFactor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

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

            fixed4 frag (v2f i) : SV_Target
            {
                float noise = SurAuroraNoise((i.uv + _AuroraHeight) * _AuroraHeightOffset);
                return half4(noise,noise,noise,noise);
            }
            ENDCG
        }
    }
}
