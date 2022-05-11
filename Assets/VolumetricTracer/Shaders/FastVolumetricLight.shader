Shader "FVL/FastVolumetricLight"
{
    Properties
    {
        _MainTex ("Gradient", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Intensity ("Intensity", Float) = 4
        _SoftBlend ("Soft Blend", Range(0.001, 10)) = 0.5

        [KeywordEnum(Sphere, Box, RoundedBox, Plane, Disk, HexagonalPrism, Capsule, CappedCylinder, Cylinder, CappedCone, RoundedCone, Ellipsoid, Triangle, Ellipse, Torus, Sphere4, Goursat)]_LightShape("Light Shape",int) = 0
    }

    SubShader
    {
        Pass
        {
            //This object must be transparent
            Tags
            {
                "RenderType"="Transparent" "Queue"="Transparent"
                //"RenderType"="Opaque" "Queue"="Opaque"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest Always
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing

            #pragma shader_feature _LIGHTSHAPE_SPHERE _LIGHTSHAPE_BOX _LIGHTSHAPE_ROUNDEDBOX _LIGHTSHAPE_PLANE _LIGHTSHAPE_DISK _LIGHTSHAPE_HEXAGONALPRISM _LIGHTSHAPE_CAPSULE _LIGHTSHAPE_CAPPEDCYLINDER _LIGHTSHAPE_CYLINDER _LIGHTSHAPE_CAPPEDCONE _LIGHTSHAPE_ROUNDEDCONE _LIGHTSHAPE_ELLIPSOID _LIGHTSHAPE_TRIANGLE _LIGHTSHAPE_ELLIPSE _LIGHTSHAPE_TORUS _LIGHTSHAPE_SPHERE4 _LIGHTSHAPE_GOURSAT
            #include "FastVolumetricLight.hlsl"
            ENDHLSL
        }
    }
}