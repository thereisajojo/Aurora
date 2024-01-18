Shader "Skybox/AuroraSky"
{
    Properties
    {
        [Header(Sky Setting)]
        _TopColor("Top Color", Color) = (0, 0, 0, 1)
        _HorizonColor("Horizon Color", Color) = (0.2, 0.3, 0.5, 1)
        _BottomColor("Bottom Color", Color) = (0, 0, 0, 1)
        _Exponent1("Exponent Factor for Top Half", Float) = 10.0
        _Exponent2("Exponent Factor for Bottom Half", Float) = 10.0
        _Intensity("Intensity", Float) = 1.0
        
        [Header(Star Setting)]
        [HDR]_StarColor("Star Color", Color) = (1,1,1,0)
        _StarIntensity("Star Intensity", Range(0,1)) = 0.5
        _StarSpeed("Star Speed", Range(0,1)) = 0.5
        
        //[Header(Aurora Setting)]
        //[HDR]_AuroraColor ("Aurora Color", Color) = (1,1,1,0)
        //_AuroraHeight("Aurora Height", Float) = 0.5
        //_AuroraHeightOffset("Aurora Height Offset", Float) = 0.15
        //_AuroraDistance("Aurora Distance", Float) = 6
        //_AuroraIntensity("Aurora Intensity", Range(0,1)) = 1.0
        //_AuroraSpeed("Aurora Speed", Range(0,1)) = 0.5
        //_AuroraColFactor("Aurora Color Factor", Range(0,1)) = 0.7
        
        //[Header(Water Setting)]
        //_CloudSpeed("Water Speed", Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma  multi_compile _ _SAMPLE_AURORA

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionOS : TEXCOORD1;
                float4 positionSS : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _AuroraTexture;

            // 环境背景颜色
            half4 _TopColor;
            half4 _HorizonColor;
            half4 _BottomColor;
            half _Intensity;
            half _Exponent1;
            half _Exponent2;

            //星星 
            half4 _StarColor;
            half _StarIntensity;
            half _StarSpeed;
            
            // 星空散列哈希
            float StarAuroraHash(float3 x)
            {
                float3 p = float3(dot(x, float3(214.1, 127.7, 125.4)),
                                  dot(x, float3(260.5, 183.3, 954.2)),
                                  dot(x, float3(209.5, 571.3, 961.2)));

                return -0.001 + _StarIntensity * frac(sin(p) * 43758.5453123);
            }

            // 星空噪声
            float StarNoise(float3 st)
            {
                // 卷动星空
                st += float3(0, _Time.y * _StarSpeed, 0);

                // fbm
                float3 i = floor(st);
                float3 f = frac(st);

                float3 u = f * f * (3.0 - 1.0 * f);

                return lerp(lerp(dot(StarAuroraHash(i + float3(0.0, 0.0, 0.0)), f - float3(0.0, 0.0, 0.0)),
                                 dot(StarAuroraHash(i + float3(1.0, 0.0, 0.0)), f - float3(1.0, 0.0, 0.0)), u.x),
                            lerp(dot(StarAuroraHash(i + float3(0.0, 1.0, 0.0)), f - float3(0.0, 1.0, 0.0)),
                                 dot(StarAuroraHash(i + float3(1.0, 1.0, 0.0)), f - float3(1.0, 1.0, 0.0)), u.y), u.z);
            }

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.positionOS = v.vertex.xyz;
                o.positionCS = UnityObjectToClipPos(v.vertex);
                o.positionSS = ComputeScreenPos(o.positionCS);
                o.uv = v.uv;
                return o;
            }

            half4 frag(v2f input) : SV_Target
            {
                // 背景
                float p = input.positionOS.y;
                float p1 = 1.0f - pow (min (1.0f, 1.0f - p), _Exponent1);
                float p3 = 1.0f - pow (min (1.0f, 1.0f + p), _Exponent2);
                float p2 = 1.0f - p1 - p3;
                int reflection = p < 0 ? -1 : 1;
                half4 skyCol = (_TopColor * p1 + _HorizonColor * p2 + _BottomColor * p3) * _Intensity;

                // 星星
                float star = StarNoise(float3(input.positionOS.x, input.positionOS.y * reflection, input.positionOS.z) * 64);
                star = star > 0.8 ? star : smoothstep(0.81, 0.98, star);
                half4 starCol = _StarColor;
                if(reflection == -1)
                {
                    starCol *= half(0.3);
                }
                skyCol = lerp(skyCol, starCol, star);

                #if defined(_SAMPLE_AURORA)
                // 采样极光
                float2 screenuv = input.positionSS.xy / input.positionSS.w;
                half4 auroraCol = tex2D(_AuroraTexture, screenuv);
                skyCol = lerp(skyCol, auroraCol, auroraCol.a);
                #endif
                
                return skyCol;
            }
            ENDCG
        }
    }
}