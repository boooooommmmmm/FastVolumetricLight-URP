#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "FastVolumetricLightIntersection.hlsl"

struct appdata
{
    float4 positionOS : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 uv : TEXCOORD0;

    half4 color : COLOR;
};

struct v2f
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 positionOS : TEXCOORD2;
    float4 screenPos : TEXCOORD3;
    float3 cameraPosOS : TEXCOORD4;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

TEXTURE2D_X_FLOAT(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

TEXTURE2D_X_HALF(_NoiseTex);
SAMPLER(sampler_LinearRepeat);
float4 _NoiseTex_ST;

TEXTURE2D_X_HALF(_GradientTex);
SAMPLER(sampler_GradientTex);

half4 _Color;
half _Intensity;
half _SoftBlend;
half4 _NoiseDirection;
half _NoiseStrength;

v2f vert(appdata v)
{
    v2f o;

    o.positionWS = TransformObjectToWorld(v.positionOS);
    o.positionOS = v.positionOS.xyz;
    o.uv = v.uv;

    o.positionCS = TransformWorldToHClip(o.positionWS);
    o.screenPos = ComputeScreenPos(o.positionCS);

    o.cameraPosOS = TransformWorldToObject(_WorldSpaceCameraPos);

    // Prevent mesh from being clipped by near clip plane
    o.positionCS.z = min(o.positionCS.z, 0);

    return o;
}

half4 frag(v2f i) : SV_Target
{
    float2 screenUV = i.screenPos.xy / i.screenPos.w;
    float3 viewDirWS = normalize(i.positionWS - _WorldSpaceCameraPos);
    float sceneDepth = LinearEyeDepth(SAMPLE_TEXTURE2D_X(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV), _ZBufferParams);

    float3 camFwd = UNITY_MATRIX_V[2].xyz; //z基向量
    float sceneDistance = sceneDepth / dot(-viewDirWS, camFwd); //real distance between scene and camera

    half4 color = 0;

    float3 rayDirection = TransformWorldToObjectDir(viewDirWS);
    float3 rayOrigin = TransformWorldToObject(_WorldSpaceCameraPos);
    float4 intersection = GetIntersection(rayOrigin, rayDirection);

    if (intersection.x > 0 || intersection.y > 0)
    {
        //Calculate noise
        float2 noiseUV = i.uv;
        noiseUV = noiseUV * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
        float noise1 = SAMPLE_TEXTURE2D_X(_NoiseTex, sampler_LinearRepeat, noiseUV + _NoiseDirection.xy * _Time.x).a;
        float noise2 = SAMPLE_TEXTURE2D_X(_NoiseTex, sampler_LinearRepeat, noiseUV + _NoiseDirection.xy * _Time.x * 2).a;
        float noise = noise1 + noise2 * 0.5;

        intersection.x = max(intersection.x, 0); //camera may inside the volumetric light

        float3 entry = TransformObjectToWorld(rayOrigin + rayDirection * intersection.x); //Cal entry point
        float3 mid = rayOrigin + rayDirection * (intersection.x + intersection.y) * 0.5;//middle point of two intersection points(object space)

        //Calculate transparency by distance from camera
        //further from camera, more transparency 
        float transparency = 1 - (length(mid) + noise * _NoiseStrength * 0.1) / 0.5; 

        color.rgb = SAMPLE_TEXTURE2D_X(_GradientTex, sampler_GradientTex, float2(transparency, 0.5)) * _Intensity;
        color.a = smoothstep(0, 1, transparency);

        //blend transparency by distance
        //Larger delta depth means ray need transform more distance in light volume, also means less transparency.
        color.a *= saturate((sceneDistance - length(entry - _WorldSpaceCameraPos)) / _SoftBlend);
    }

    color *= _Color;

    return color;
}
