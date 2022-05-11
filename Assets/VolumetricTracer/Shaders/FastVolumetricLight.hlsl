#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "FastVolumetricLightIntersection.hlsl"

struct appdata {
    float4 positionOS : POSITION;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
    float4 texcoord : TEXCOORD0;

    half4 color : COLOR;
};

struct v2f
{
    float4 positionCS : SV_POSITION;
    float2 texcoord : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 positionOS : TEXCOORD2;
    float4 screenPos : TEXCOORD3;
    float3 cameraPosOS : TEXCOORD4;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

TEXTURE2D_X_FLOAT(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

sampler2D _MainTex;
float4 _Color;
float _Intensity;
float _SoftBlend;

v2f vert(appdata v)
{
    v2f o;
    
    o.positionWS = TransformObjectToWorld(v.positionOS);
    o.positionOS = v.positionOS.xyz;
    o.texcoord = v.texcoord;

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

    float3 camFwd = UNITY_MATRIX_V[2].xyz;//z基向量
    float sceneDistance = sceneDepth / dot(-viewDirWS, camFwd);
    
    half4 color = 0;
    
    float3 rayDirection = TransformWorldToObjectDir(viewDirWS);
    float3 rayOrigin = TransformWorldToObject(_WorldSpaceCameraPos);

    float2 intersection = GetIntersection(rayOrigin, rayDirection);

    if (intersection.x > 0 || intersection.y > 0)
    {
        intersection.x = max(intersection.x, 0);

        // World-space entry point. Used for scene blending
        float3 entry = TransformObjectToWorld(rayOrigin + rayDirection * intersection.x);

        float3 mid = rayOrigin + rayDirection * (intersection.x + intersection.y) * 0.5;
        
        float alpha = 1 - length(mid) / 0.5;

        color.rgb = tex2D(_MainTex, float2(alpha, 0.5)) * _Intensity;
        color.a = smoothstep(0, 1, alpha);

        // Scene blending
        color.a *= saturate((sceneDistance - length(entry - _WorldSpaceCameraPos)) / _SoftBlend);
    }
    //return _SoftBlend;

    color *= _Color;

    return color;
}
