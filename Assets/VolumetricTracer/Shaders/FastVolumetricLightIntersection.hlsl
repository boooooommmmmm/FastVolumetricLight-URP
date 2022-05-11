//All intersection functions come from:
//https://iquilezles.org/articles/intersectors/

//Sphere
//Keyword: _LIGHTSHAPE_SPHERE
// Ray-sphere intersection. Returns the distance to the first and second intersection along the ray (or -1 if ray misses)
float2 SphereIntersection(float3 rayOrigin, float3 rayDirection)
{
    float sphereRadius = 1.0f;
    float3 center = float3(0, 0, 0);

    rayOrigin -= center;
    float a = dot(rayDirection, rayDirection);
    float b = 2.0 * dot(rayOrigin, rayDirection);
    float c = dot(rayOrigin, rayOrigin) - (sphereRadius * sphereRadius);
    float d = b * b - 4 * a * c;

    // [UNITY_BRANCH]
    if (d < 0)
    {
        return -1;
    }
    else
    {
        d = sqrt(d);
        return float2(-b - d, -b + d) / (2 * a);
    }
}

//Box
//Keyword: _LIGHTSHAPE_BOX
float2 BoxIntersection(float3 rayOrigin, float3 rayDirection)
{
    float3 boxSize = float3(1, 1, 1);
    float3 outNormal = 0;
    
    float3 m = 1.0 / rayDirection; // can precompute if traversing a set of aligned boxes
    float3 n = m * rayOrigin; // can precompute if traversing a set of aligned boxes
    float3 k = abs(m) * boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    
    if (tN > tF || tF < 0.0) return -1; // no intersection
    outNormal = -sign(rayDirection) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
    
    return float2(tN, tF);
}

float2 GetIntersection(float3 rayOrigin, float3 rayDirection)
{
    float2 result = 0;
    #ifdef _LIGHTSHAPE_SPHERE
    result = SphereIntersection(rayOrigin, rayDirection);
    #elif _LIGHTSHAPE_BOX
    result = BoxIntersection(rayOrigin, rayDirection);
    #endif

    return result;
}
